#include "snmpworker.h"
#include <QDebug>
#include <QDir>
#include <QFileInfo>

// Net-SNMP includes
#include <net-snmp/net-snmp-config.h>
#include <net-snmp/net-snmp-includes.h>

SnmpWorker::SnmpWorker(const DeviceConfig& config, const QString& mibPath, QObject* parent)
    : QObject(parent)
    , m_config(config)
    , m_mibPath(mibPath)
    , m_isRunning(true)
{
}

SnmpWorker::~SnmpWorker()
{
}

void SnmpWorker::stop()
{
    m_isRunning = false;
}

QString SnmpWorker::formatTimeTicks(unsigned long ticks)
{
    double totalSeconds = ticks / 100.0;
    int days = static_cast<int>(totalSeconds / 86400);
    int remainder = static_cast<int>(totalSeconds) % 86400;
    int hours = remainder / 3600;
    remainder %= 3600;
    int minutes = remainder / 60;
    double seconds = totalSeconds - (days * 86400) - (hours * 3600) - (minutes * 60);
    
    QString result;
    if (days > 0) result += QString("%1d ").arg(days);
    if (hours > 0 || days > 0) result += QString("%1h ").arg(hours);
    result += QString("%1m %2s").arg(minutes).arg(seconds, 0, 'f', 2);
    
    return result.trimmed();
}

QString SnmpWorker::formatOctetString(const unsigned char* data, size_t length)
{
    // Check if it's printable text
    bool isText = true;
    for (size_t i = 0; i < length && isText; ++i) {
        unsigned char c = data[i];
        if (!((c >= 32 && c <= 126) || c == 9 || c == 10 || c == 13)) {
            isText = false;
        }
    }
    
    if (isText) {
        return QString::fromUtf8(reinterpret_cast<const char*>(data), length);
    }
    
    // Check for MAC address (6 bytes)
    if (length == 6) {
        return QString("%1:%2:%3:%4:%5:%6")
            .arg(data[0], 2, 16, QChar('0'))
            .arg(data[1], 2, 16, QChar('0'))
            .arg(data[2], 2, 16, QChar('0'))
            .arg(data[3], 2, 16, QChar('0'))
            .arg(data[4], 2, 16, QChar('0'))
            .arg(data[5], 2, 16, QChar('0'))
            .toUpper();
    }
    
    // Hex format
    QString hex = "0x ";
    for (size_t i = 0; i < length; ++i) {
        hex += QString("%1 ").arg(data[i], 2, 16, QChar('0')).toUpper();
    }
    return hex.trimmed();
}

void SnmpWorker::doWork()
{
    emit logMessage(QString("Starting SNMP Walk on %1...").arg(m_config.ip));
    
    // Initialize SNMP library
    init_snmp("snmpbrowser");
    
    // Load MIBs if path is specified
    if (!m_mibPath.isEmpty() && QDir(m_mibPath).exists()) {
        emit logMessage(QString("MIB Source: %1").arg(m_mibPath));
        
        // Add MIB directory to search path
        add_mibdir(m_mibPath.toLocal8Bit().constData());
        
        // Load all MIB files in directory
        QDir mibDir(m_mibPath);
        QStringList filters;
        filters << "*.mib" << "*.my" << "*.txt" << "*.smi";
        QStringList mibFiles = mibDir.entryList(filters, QDir::Files);
        
        int loadedCount = 0;
        for (const QString& file : mibFiles) {
            QString modName = QFileInfo(file).baseName();
            if (read_module(modName.toLocal8Bit().constData()) != nullptr) {
                loadedCount++;
            }
        }
        emit logMessage(QString("Loaded %1 MIB modules.").arg(loadedCount));
    }
    
    // Create SNMPv3 session
    struct snmp_session session;
    snmp_sess_init(&session);
    
    session.peername = strdup(QString("%1:%2").arg(m_config.ip).arg(m_config.port)
                               .toLocal8Bit().constData());
    session.version = SNMP_VERSION_3;
    
    // Security settings
    session.securityName = strdup(m_config.username.toLocal8Bit().constData());
    session.securityNameLen = m_config.username.length();
    session.securityLevel = SNMP_SEC_LEVEL_AUTHPRIV;
    
    // Auth protocol (MD5)
    session.securityAuthProto = usmHMACMD5AuthProtocol;
    session.securityAuthProtoLen = USM_AUTH_PROTO_MD5_LEN;
    session.securityAuthKeyLen = USM_AUTH_KU_LEN;
    
    if (generate_Ku(session.securityAuthProto,
                    session.securityAuthProtoLen,
                    reinterpret_cast<u_char*>(const_cast<char*>(m_config.authKey.toLocal8Bit().constData())),
                    m_config.authKey.length(),
                    session.securityAuthKey,
                    &session.securityAuthKeyLen) != SNMPERR_SUCCESS) {
        emit errorOccurred("Failed to generate authentication key");
        emit finished();
        return;
    }
    
    // Privacy protocol (DES)
    session.securityPrivProto = usmDESPrivProtocol;
    session.securityPrivProtoLen = USM_PRIV_PROTO_DES_LEN;
    session.securityPrivKeyLen = USM_PRIV_KU_LEN;
    
    if (generate_Ku(session.securityAuthProto,
                    session.securityAuthProtoLen,
                    reinterpret_cast<u_char*>(const_cast<char*>(m_config.privKey.toLocal8Bit().constData())),
                    m_config.privKey.length(),
                    session.securityPrivKey,
                    &session.securityPrivKeyLen) != SNMPERR_SUCCESS) {
        emit errorOccurred("Failed to generate privacy key");
        emit finished();
        return;
    }
    
    // Timeout and retries
    session.timeout = 2000000; // 2 seconds
    session.retries = 1;
    
    // Open session
    struct snmp_session* ss = snmp_open(&session);
    if (!ss) {
        char* errMsg = nullptr;
        snmp_error(&session, nullptr, nullptr, &errMsg);
        emit errorOccurred(QString("Failed to open SNMP session: %1").arg(errMsg ? errMsg : "Unknown error"));
        if (errMsg) free(errMsg);
        emit finished();
        return;
    }
    
    // Start OID for walking (iso.org.dod.internet = 1.3.6.1)
    oid rootOid[] = {1, 3, 6, 1};
    size_t rootOidLen = sizeof(rootOid) / sizeof(oid);
    
    oid currentOid[MAX_OID_LEN];
    size_t currentOidLen = rootOidLen;
    memcpy(currentOid, rootOid, rootOidLen * sizeof(oid));
    
    // SNMP walk loop
    while (m_isRunning) {
        struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_GETNEXT);
        snmp_add_null_var(pdu, currentOid, currentOidLen);
        
        struct snmp_pdu* response = nullptr;
        int status = snmp_synch_response(ss, pdu, &response);
        
        if (status == STAT_SUCCESS && response->errstat == SNMP_ERR_NOERROR) {
            for (struct variable_list* vars = response->variables; vars; vars = vars->next_variable) {
                // Check if we've gone past our root OID
                if (vars->name_length < rootOidLen ||
                    memcmp(vars->name, rootOid, rootOidLen * sizeof(oid)) != 0) {
                    m_isRunning = false;
                    break;
                }
                
                // Check for end of MIB
                if (vars->type == SNMP_ENDOFMIBVIEW) {
                    m_isRunning = false;
                    break;
                }
                
                // Get OID string
                char oidBuf[2048];
                snprint_objid(oidBuf, sizeof(oidBuf), vars->name, vars->name_length);
                QString oidStr = QString::fromLocal8Bit(oidBuf);
                
                // Get value
                char valBuf[2048];
                snprint_value(valBuf, sizeof(valBuf), vars->name, vars->name_length, vars);
                QString rawValue = QString::fromLocal8Bit(valBuf);
                
                // Format pretty value based on type
                QString prettyValue;
                switch (vars->type) {
                    case ASN_TIMETICKS:
                        prettyValue = formatTimeTicks(*vars->val.integer);
                        break;
                    case ASN_OCTET_STR:
                        prettyValue = formatOctetString(vars->val.string, vars->val_len);
                        break;
                    case ASN_IPADDRESS:
                        if (vars->val_len == 4) {
                            prettyValue = QString("%1.%2.%3.%4")
                                .arg(vars->val.string[0])
                                .arg(vars->val.string[1])
                                .arg(vars->val.string[2])
                                .arg(vars->val.string[3]);
                        } else {
                            prettyValue = rawValue;
                        }
                        break;
                    case ASN_INTEGER:
                    case ASN_COUNTER:
                    case ASN_GAUGE:
                    case ASN_COUNTER64:
                        prettyValue = rawValue;
                        break;
                    default:
                        prettyValue = rawValue;
                        break;
                }
                
                emit resultReady(oidStr, rawValue, prettyValue);
                
                // Update current OID for next iteration
                memcpy(currentOid, vars->name, vars->name_length * sizeof(oid));
                currentOidLen = vars->name_length;
            }
        } else {
            if (status == STAT_SUCCESS) {
                emit errorOccurred(QString("SNMP Error: %1").arg(snmp_errstring(response->errstat)));
            } else if (status == STAT_TIMEOUT) {
                emit errorOccurred("SNMP request timed out");
            } else {
                char* errMsg = nullptr;
                snmp_error(ss, nullptr, nullptr, &errMsg);
                emit errorOccurred(QString("SNMP Error: %1").arg(errMsg ? errMsg : "Unknown"));
                if (errMsg) free(errMsg);
            }
            m_isRunning = false;
        }
        
        if (response) {
            snmp_free_pdu(response);
        }
    }
    
    snmp_close(ss);
    emit finished();
}
