#ifndef SNMPCONTROLLER_H
#define SNMPCONTROLLER_H

#include <QObject>
#include <QThread>
#include <QString>
#include <QUrl>
#include "deviceconfig.h"
#include "treemodel.h"
#include "treefilterproxymodel.h"
#include "settingsmanager.h"

class SnmpWorker;
class MibCompilerWorker;

class SnmpController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY isScanningChanged)
    Q_PROPERTY(bool isCompiling READ isCompiling NOTIFY isCompilingChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(TreeModel* treeModel READ treeModel CONSTANT)
    Q_PROPERTY(TreeFilterProxyModel* proxyModel READ proxyModel CONSTANT)
    Q_PROPERTY(SettingsManager* settings READ settings CONSTANT)
    Q_PROPERTY(bool canExport READ canExport NOTIFY canExportChanged)

public:
    explicit SnmpController(QObject* parent = nullptr);
    ~SnmpController();

    bool isScanning() const;
    bool isCompiling() const;
    QString statusMessage() const;
    TreeModel* treeModel() const;
    TreeFilterProxyModel* proxyModel() const;
    SettingsManager* settings() const;
    bool canExport() const;

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();
    Q_INVOKABLE void compileMibs();
    Q_INVOKABLE void selectMibFolder(const QUrl& folderUrl);
    Q_INVOKABLE void exportSnapshot(const QUrl& fileUrl);
    Q_INVOKABLE void copyToClipboard(const QString& text);

signals:
    void isScanningChanged();
    void isCompilingChanged();
    void statusMessageChanged();
    void canExportChanged();
    void errorOccurred(const QString& title, const QString& message);
    void infoMessage(const QString& title, const QString& message);
    void compileFinished(const QString& report);

private slots:
    void onWorkerLog(const QString& message);
    void onWorkerResult(const QString& oid, const QString& rawValue, const QString& prettyValue);
    void onWorkerError(const QString& error);
    void onWorkerFinished();
    void onCompileProgress(const QString& message);
    void onCompileFinished(const QString& report);

private:
    void setStatusMessage(const QString& message);
    void cleanupWorker();
    void cleanupCompiler();

    bool m_isScanning;
    bool m_isCompiling;
    QString m_statusMessage;
    
    TreeModel* m_treeModel;
    TreeFilterProxyModel* m_proxyModel;
    SettingsManager* m_settings;
    
    QThread* m_workerThread;
    SnmpWorker* m_worker;
    
    QThread* m_compilerThread;
    MibCompilerWorker* m_compiler;
};

#endif // SNMPCONTROLLER_H
