#ifndef DEVICECONFIG_H
#define DEVICECONFIG_H

#include <QString>

struct DeviceConfig {
    QString ip;
    int port;
    QString username;
    QString authKey;
    QString privKey;
    
    DeviceConfig() : port(161) {}
    
    DeviceConfig(const QString& ip, int port, const QString& username,
                 const QString& authKey, const QString& privKey)
        : ip(ip), port(port), username(username), 
          authKey(authKey), privKey(privKey) {}
};

#endif // DEVICECONFIG_H
