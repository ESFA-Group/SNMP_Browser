#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QIcon>

#include "snmpcontroller.h"
#include "treemodel.h"
#include "settingsmanager.h"

int main(int argc, char *argv[])
{
#ifdef Q_OS_WIN
    // Some Windows VMs, RDP sessions, and older GPU drivers create a valid
    // frameless window but fail to render the Qt Quick scene with the default
    // hardware graphics backend, leaving the app as a large black rectangle.
    // Force software rendering for the packaged Windows build before the QML
    // engine creates any scene graph resources.
    if (qEnvironmentVariableIsEmpty("QT_QUICK_BACKEND")) {
        qputenv("QT_QUICK_BACKEND", "software");
    }
    if (qEnvironmentVariableIsEmpty("QSG_RHI_BACKEND")) {
        qputenv("QSG_RHI_BACKEND", "software");
    }
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
#endif

    QGuiApplication app(argc, argv);
    
    // Set application info
    app.setOrganizationName("ESFA Group");
    app.setOrganizationDomain("esfagroup.com");
    app.setApplicationName("SNMPBrowser");
    app.setApplicationVersion("1.0.0");
    
    // Set Quick Controls style
    QQuickStyle::setStyle("Basic");
    
    // Register QML types
    qmlRegisterType<TreeModel>("SNMPBrowser", 1, 0, "TreeModel");
    qmlRegisterType<SettingsManager>("SNMPBrowser", 1, 0, "SettingsManager");
    
    // Create controller
    SnmpController controller;
    
    // Set up QML engine
    QQmlApplicationEngine engine;
    
    // Expose controller to QML
    engine.rootContext()->setContextProperty("controller", &controller);
    
    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    return app.exec();
}
