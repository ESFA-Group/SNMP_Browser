#include "snmpcontroller.h"
#include "snmpworker.h"
#include "mibcompilerworker.h"
#include <QGuiApplication>
#include <QClipboard>
#include <QFile>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDateTime>
#include <QDir>
#include <QDebug>

SnmpController::SnmpController(QObject* parent)
    : QObject(parent)
    , m_isScanning(false)
    , m_isCompiling(false)
    , m_statusMessage("Ready to connect")
    , m_treeModel(new TreeModel(this))
    , m_proxyModel(new TreeFilterProxyModel(this))
    , m_settings(new SettingsManager(this))
    , m_workerThread(nullptr)
    , m_worker(nullptr)
    , m_compilerThread(nullptr)
    , m_compiler(nullptr)
{
    m_proxyModel->setSourceModel(m_treeModel);
}

SnmpController::~SnmpController()
{
    cleanupWorker();
    cleanupCompiler();
}

bool SnmpController::isScanning() const
{
    return m_isScanning;
}

bool SnmpController::isCompiling() const
{
    return m_isCompiling;
}

QString SnmpController::statusMessage() const
{
    return m_statusMessage;
}

TreeModel* SnmpController::treeModel() const
{
    return m_treeModel;
}

TreeFilterProxyModel* SnmpController::proxyModel() const
{
    return m_proxyModel;
}

SettingsManager* SnmpController::settings() const
{
    return m_settings;
}

bool SnmpController::canExport() const
{
    return m_treeModel->itemCount() > 0;
}

void SnmpController::setStatusMessage(const QString& message)
{
    if (m_statusMessage != message) {
        m_statusMessage = message;
        emit statusMessageChanged();
    }
}

void SnmpController::startScan()
{
    if (m_isScanning) return;
    
    if (m_settings->ip().isEmpty()) {
        emit errorOccurred("Error", "IP Address is required");
        return;
    }
    
    // Clear previous results
    m_treeModel->clear();
    emit canExportChanged();
    
    // Create device config
    DeviceConfig config(
        m_settings->ip(),
        m_settings->port(),
        m_settings->username(),
        m_settings->authKey(),
        m_settings->privKey()
    );
    
    // Create worker thread
    m_workerThread = new QThread(this);
    m_worker = new SnmpWorker(config, m_settings->mibPath());
    m_worker->moveToThread(m_workerThread);
    
    // Connect signals
    connect(m_workerThread, &QThread::started, m_worker, &SnmpWorker::doWork);
    connect(m_worker, &SnmpWorker::logMessage, this, &SnmpController::onWorkerLog);
    connect(m_worker, &SnmpWorker::resultReady, this, &SnmpController::onWorkerResult);
    connect(m_worker, &SnmpWorker::errorOccurred, this, &SnmpController::onWorkerError);
    connect(m_worker, &SnmpWorker::finished, this, &SnmpController::onWorkerFinished);
    connect(m_worker, &SnmpWorker::finished, m_workerThread, &QThread::quit);
    connect(m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);
    connect(m_workerThread, &QThread::finished, m_workerThread, &QObject::deleteLater);
    
    m_isScanning = true;
    emit isScanningChanged();
    setStatusMessage("Scanning network device...");
    
    m_workerThread->start();
}

void SnmpController::stopScan()
{
    if (m_worker) {
        m_worker->stop();
        setStatusMessage("Stopping scan...");
    }
}

void SnmpController::cleanupWorker()
{
    if (m_workerThread && m_workerThread->isRunning()) {
        if (m_worker) {
            m_worker->stop();
        }
        m_workerThread->quit();
        m_workerThread->wait(3000);
    }
    m_worker = nullptr;
    m_workerThread = nullptr;
}

void SnmpController::onWorkerLog(const QString& message)
{
    setStatusMessage(message);
}

void SnmpController::onWorkerResult(const QString& oid, const QString& rawValue, const QString& prettyValue)
{
    m_treeModel->addItem(oid, rawValue, prettyValue);
}

void SnmpController::onWorkerError(const QString& error)
{
    emit errorOccurred("SNMP Error", error);
}

void SnmpController::onWorkerFinished()
{
    m_isScanning = false;
    emit isScanningChanged();
    setStatusMessage("Scan Complete.");
    emit canExportChanged();
    
    m_worker = nullptr;
    m_workerThread = nullptr;
}

void SnmpController::compileMibs()
{
    if (m_isCompiling) return;
    
    if (m_settings->mibPath().isEmpty() || !QDir(m_settings->mibPath()).exists()) {
        emit errorOccurred("Error", "Please select a MIB folder first.");
        return;
    }
    
    m_compilerThread = new QThread(this);
    m_compiler = new MibCompilerWorker(m_settings->mibPath());
    m_compiler->moveToThread(m_compilerThread);
    
    connect(m_compilerThread, &QThread::started, m_compiler, &MibCompilerWorker::doWork);
    connect(m_compiler, &MibCompilerWorker::progressMessage, this, &SnmpController::onCompileProgress);
    connect(m_compiler, &MibCompilerWorker::finished, this, &SnmpController::onCompileFinished);
    connect(m_compiler, &MibCompilerWorker::finished, m_compilerThread, &QThread::quit);
    connect(m_compilerThread, &QThread::finished, m_compiler, &QObject::deleteLater);
    connect(m_compilerThread, &QThread::finished, m_compilerThread, &QObject::deleteLater);
    
    m_isCompiling = true;
    emit isCompilingChanged();
    setStatusMessage("Compiling MIBs... check progress.");
    
    m_compilerThread->start();
}

void SnmpController::cleanupCompiler()
{
    if (m_compilerThread && m_compilerThread->isRunning()) {
        m_compilerThread->quit();
        m_compilerThread->wait(3000);
    }
    m_compiler = nullptr;
    m_compilerThread = nullptr;
}

void SnmpController::onCompileProgress(const QString& message)
{
    setStatusMessage(message);
}

void SnmpController::onCompileFinished(const QString& report)
{
    m_isCompiling = false;
    emit isCompilingChanged();
    setStatusMessage("Compilation finished.");
    emit compileFinished(report);
    
    m_compiler = nullptr;
    m_compilerThread = nullptr;
}

void SnmpController::selectMibFolder(const QUrl& folderUrl)
{
    QString path = folderUrl.toLocalFile();
    if (!path.isEmpty() && QDir(path).exists()) {
        m_settings->setMibPath(path);
        setStatusMessage(QString("MIB path set to: %1").arg(path));
    }
}

void SnmpController::exportSnapshot(const QUrl& fileUrl)
{
    QString filePath = fileUrl.toLocalFile();
    if (filePath.isEmpty()) return;
    
    if (m_treeModel->itemCount() == 0) {
        emit errorOccurred("Export", "No data to export.");
        return;
    }
    
    bool isJson = filePath.toLower().endsWith(".json");
    
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit errorOccurred("Export Error", QString("Failed to open file: %1").arg(file.errorString()));
        return;
    }
    
    try {
        // Gather data from tree model
        QJsonArray dataArray;
        
        // Iterate through the tree model
        for (int groupIdx = 0; groupIdx < m_treeModel->rowCount(); ++groupIdx) {
            QModelIndex groupIndex = m_treeModel->index(groupIdx, 0);
            QString groupName = m_treeModel->data(groupIndex, TreeModel::OidRole).toString();
            
            for (int childIdx = 0; childIdx < m_treeModel->rowCount(groupIndex); ++childIdx) {
                QModelIndex childIndex = m_treeModel->index(childIdx, 0, groupIndex);
                
                QJsonObject item;
                item["Group"] = groupName;
                item["Parameter"] = m_treeModel->data(childIndex, TreeModel::OidRole).toString();
                item["Value"] = m_treeModel->data(childIndex, TreeModel::ValueRole).toString();
                item["Raw"] = m_treeModel->data(childIndex, TreeModel::RawValueRole).toString();
                
                dataArray.append(item);
            }
        }
        
        if (isJson) {
            QJsonDocument doc(dataArray);
            file.write(doc.toJson(QJsonDocument::Indented));
        } else {
            // CSV format
            QTextStream stream(&file);
            stream << "Group,Parameter,Value,Raw\n";
            
            for (const QJsonValue& val : dataArray) {
                QJsonObject obj = val.toObject();
                // Escape CSV fields
                auto escapeField = [](const QString& field) -> QString {
                    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
                        return '"' + QString(field).replace('"', "\"\"") + '"';
                    }
                    return field;
                };
                
                stream << escapeField(obj["Group"].toString()) << ","
                       << escapeField(obj["Parameter"].toString()) << ","
                       << escapeField(obj["Value"].toString()) << ","
                       << escapeField(obj["Raw"].toString()) << "\n";
            }
        }
        
        file.close();
        setStatusMessage(QString("Snapshot saved to %1").arg(QFileInfo(filePath).fileName()));
        emit infoMessage("Export Success", QString("Successfully saved %1 items.").arg(dataArray.size()));
        
    } catch (...) {
        emit errorOccurred("Export Error", "Failed to write file.");
    }
}

void SnmpController::copyToClipboard(const QString& text)
{
    QGuiApplication::clipboard()->setText(text);
    setStatusMessage(QString("Copied: %1").arg(text.left(50)));
}
