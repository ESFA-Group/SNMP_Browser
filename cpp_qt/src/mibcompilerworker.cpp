#include "mibcompilerworker.h"
#include <QDir>
#include <QFileInfo>
#include <QDebug>

#include <net-snmp/net-snmp-config.h>
#include <net-snmp/net-snmp-includes.h>

MibCompilerWorker::MibCompilerWorker(const QString& mibPath, QObject* parent)
    : QObject(parent)
    , m_mibPath(mibPath)
{
}

MibCompilerWorker::~MibCompilerWorker()
{
}

void MibCompilerWorker::doWork()
{
    emit progressMessage("Initializing Compiler...");
    
    if (!QDir(m_mibPath).exists()) {
        emit finished("Error: MIB folder path does not exist.");
        return;
    }
    
    // Initialize SNMP for MIB loading
    init_snmp("mibcompiler");
    
    // Add MIB directory
    add_mibdir(m_mibPath.toLocal8Bit().constData());
    
    QStringList results;
    int errors = 0;
    int processedCount = 0;
    
    QDir mibDir(m_mibPath);
    QStringList filters;
    filters << "*.mib" << "*.my" << "*.txt" << "*.smi";
    QStringList mibFiles = mibDir.entryList(filters, QDir::Files);
    
    for (const QString& filename : mibFiles) {
        QString modName = QFileInfo(filename).baseName();
        emit progressMessage(QString("Compiling: %1...").arg(modName));
        
        // Try to load the module
        struct tree* mibTree = read_module(modName.toLocal8Bit().constData());
        
        if (mibTree != nullptr) {
            results.append(QString("✔ %1: Compiled & Loaded").arg(modName));
            processedCount++;
        } else {
            errors++;
            results.append(QString("✘ %1: Failed to load").arg(modName));
        }
    }
    
    QString report;
    if (processedCount == 0) {
        report = QString("No valid MIB files found in folder.\nChecked for: .mib, .my, .txt, .smi");
    } else {
        report = QString("Processed %1 files.\n%2 Errors.\n\n%3")
                     .arg(processedCount)
                     .arg(errors)
                     .arg(results.join("\n"));
    }
    
    emit finished(report);
}
