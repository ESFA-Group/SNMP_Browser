#ifndef SNMPWORKER_H
#define SNMPWORKER_H

#include <QObject>
#include <QThread>
#include <QString>
#include <atomic>
#include "deviceconfig.h"

class SnmpWorker : public QObject
{
    Q_OBJECT

public:
    explicit SnmpWorker(const DeviceConfig& config, const QString& mibPath = QString(), QObject* parent = nullptr);
    ~SnmpWorker();

public slots:
    void doWork();
    void stop();

signals:
    void logMessage(const QString& message);
    void resultReady(const QString& oid, const QString& rawValue, const QString& prettyValue);
    void errorOccurred(const QString& error);
    void finished();

private:
    QString formatValue(void* variable);
    QString formatTimeTicks(unsigned long ticks);
    QString formatOctetString(const unsigned char* data, size_t length);
    
    DeviceConfig m_config;
    QString m_mibPath;
    std::atomic<bool> m_isRunning;
};

#endif // SNMPWORKER_H
