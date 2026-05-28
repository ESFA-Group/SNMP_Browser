#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>

#include "snmpcontroller.h"
#include "treemodel.h"
#include "settingsmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Set application info
    app.setOrganizationName("MyCompany");
    app.setOrganizationDomain("mycompany.com");
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
