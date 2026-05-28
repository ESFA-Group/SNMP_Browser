#ifndef MIBCOMPILERWORKER_H
#define MIBCOMPILERWORKER_H

#include <QObject>
#include <QString>
#include <atomic>

class MibCompilerWorker : public QObject
{
    Q_OBJECT

public:
    explicit MibCompilerWorker(const QString& mibPath, QObject* parent = nullptr);
    ~MibCompilerWorker();

public slots:
    void doWork();

signals:
    void progressMessage(const QString& message);
    void finished(const QString& report);

private:
    QString m_mibPath;
};

#endif // MIBCOMPILERWORKER_H
