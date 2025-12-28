#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>
#include <QString>

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString ip READ ip WRITE setIp NOTIFY ipChanged)
    Q_PROPERTY(int port READ port WRITE setPort NOTIFY portChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString authKey READ authKey WRITE setAuthKey NOTIFY authKeyChanged)
    Q_PROPERTY(QString privKey READ privKey WRITE setPrivKey NOTIFY privKeyChanged)
    Q_PROPERTY(QString mibPath READ mibPath WRITE setMibPath NOTIFY mibPathChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)

public:
    explicit SettingsManager(QObject* parent = nullptr);
    ~SettingsManager();

    QString ip() const;
    void setIp(const QString& ip);

    int port() const;
    void setPort(int port);

    QString username() const;
    void setUsername(const QString& username);

    QString authKey() const;
    void setAuthKey(const QString& authKey);

    QString privKey() const;
    void setPrivKey(const QString& privKey);

    QString mibPath() const;
    void setMibPath(const QString& mibPath);

    QString theme() const;
    void setTheme(const QString& theme);

    Q_INVOKABLE void save();
    Q_INVOKABLE void load();

signals:
    void ipChanged();
    void portChanged();
    void usernameChanged();
    void authKeyChanged();
    void privKeyChanged();
    void mibPathChanged();
    void themeChanged();

private:
    QSettings m_settings;
    QString m_ip;
    int m_port;
    QString m_username;
    QString m_authKey;
    QString m_privKey;
    QString m_mibPath;
    QString m_theme;
};

#endif // SETTINGSMANAGER_H
