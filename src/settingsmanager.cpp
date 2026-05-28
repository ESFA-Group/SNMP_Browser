#include "settingsmanager.h"
#include <QDir>

SettingsManager::SettingsManager(QObject* parent)
    : QObject(parent)
    , m_settings("MyCompany", "SnmpBrowser")
    , m_port(161)
    , m_theme("dark")
{
    load();
}

SettingsManager::~SettingsManager()
{
    save();
}

QString SettingsManager::ip() const
{
    return m_ip;
}

void SettingsManager::setIp(const QString& ip)
{
    if (m_ip != ip) {
        m_ip = ip;
        emit ipChanged();
    }
}

int SettingsManager::port() const
{
    return m_port;
}

void SettingsManager::setPort(int port)
{
    if (m_port != port) {
        m_port = port;
        emit portChanged();
    }
}

QString SettingsManager::username() const
{
    return m_username;
}

void SettingsManager::setUsername(const QString& username)
{
    if (m_username != username) {
        m_username = username;
        emit usernameChanged();
    }
}

QString SettingsManager::authKey() const
{
    return m_authKey;
}

void SettingsManager::setAuthKey(const QString& authKey)
{
    if (m_authKey != authKey) {
        m_authKey = authKey;
        emit authKeyChanged();
    }
}

QString SettingsManager::privKey() const
{
    return m_privKey;
}

void SettingsManager::setPrivKey(const QString& privKey)
{
    if (m_privKey != privKey) {
        m_privKey = privKey;
        emit privKeyChanged();
    }
}

QString SettingsManager::mibPath() const
{
    return m_mibPath;
}

void SettingsManager::setMibPath(const QString& mibPath)
{
    if (m_mibPath != mibPath) {
        m_mibPath = mibPath;
        emit mibPathChanged();
    }
}

QString SettingsManager::theme() const
{
    return m_theme;
}

void SettingsManager::setTheme(const QString& theme)
{
    if (m_theme != theme) {
        m_theme = theme;
        emit themeChanged();
    }
}

void SettingsManager::save()
{
    m_settings.setValue("ip", m_ip);
    m_settings.setValue("port", m_port);
    m_settings.setValue("username", m_username);
    m_settings.setValue("auth_key", m_authKey);
    m_settings.setValue("priv_key", m_privKey);
    m_settings.setValue("mib_path", m_mibPath);
    m_settings.setValue("theme", m_theme);
    m_settings.sync();
}

void SettingsManager::load()
{
    m_ip = m_settings.value("ip", "192.168.1.1").toString();
    m_port = m_settings.value("port", 161).toInt();
    m_username = m_settings.value("username", "admin").toString();
    m_authKey = m_settings.value("auth_key", "").toString();
    m_privKey = m_settings.value("priv_key", "").toString();
    m_mibPath = m_settings.value("mib_path", "").toString();
    m_theme = m_settings.value("theme", "dark").toString();
    
    // Validate MIB path
    if (!m_mibPath.isEmpty() && !QDir(m_mibPath).exists()) {
        m_mibPath.clear();
    }
    
    emit ipChanged();
    emit portChanged();
    emit usernameChanged();
    emit authKeyChanged();
    emit privKeyChanged();
    emit mibPathChanged();
    emit themeChanged();
}
