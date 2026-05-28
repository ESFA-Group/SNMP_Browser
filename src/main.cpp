#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickView>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QScreen>
#include <QTimer>
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

    auto activeScreenGeometry = []() -> QRect {
        QScreen *screen = QGuiApplication::screenAt(QCursor::pos());
        if (!screen) {
            screen = QGuiApplication::primaryScreen();
        }
        return screen ? screen->availableGeometry() : QRect(0, 0, 1280, 720);
    };

    auto centerOnScreen = [activeScreenGeometry](QWindow *window) {
        if (!window) {
            return;
        }

        const QRect screenGeometry = activeScreenGeometry();
        const QSize windowSize = window->size();
        const int x = screenGeometry.x() + (screenGeometry.width() - windowSize.width()) / 2;
        const int y = screenGeometry.y() + (screenGeometry.height() - windowSize.height()) / 2;
        window->setPosition(qMax(screenGeometry.x(), x), qMax(screenGeometry.y(), y));
    };

    QQuickView splashView;
    const QRect splashGeometry = activeScreenGeometry();

    // On Linux/Wayland, compositors are allowed to ignore exact top-level window
    // positions. Use a transparent screen-sized overlay and center the visible
    // splash card inside QML, so the card appears centered even when setPosition()
    // is ignored by the window manager.
    splashView.setFlags(Qt::Tool | Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
    splashView.setColor(Qt::transparent);
    splashView.setResizeMode(QQuickView::SizeRootObjectToView);
    splashView.setGeometry(splashGeometry);
    splashView.setSource(QUrl(QStringLiteral("qrc:/qml/SplashScreen.qml")));
    splashView.show();
    splashView.raise();
    splashView.requestActivate();
    
    // Register QML types
    qmlRegisterType<TreeModel>("SNMPBrowser", 1, 0, "TreeModel");
    qmlRegisterType<SettingsManager>("SNMPBrowser", 1, 0, "SettingsManager");
    
    // Create controller
    SnmpController controller;
    
    // Set up QML engine
    QQmlApplicationEngine engine;
    
    // Expose controller to QML
    engine.rootContext()->setContextProperty("controller", &controller);
    
    // Load main QML file only after the splash duration. This avoids creating
    // or showing the main window behind the splash during startup.
    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    bool mainWindowLoaded = false;

    auto loadMainWindow = [&]() {
        if (mainWindowLoaded) {
            return;
        }

        mainWindowLoaded = true;
        splashView.close();
        engine.load(url);
    };
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, centerOnScreen](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
            return;
        }

        if (obj && url == objUrl) {
            if (auto *window = qobject_cast<QWindow *>(obj)) {
                window->setFlag(Qt::WindowStaysOnTopHint, true);
                centerOnScreen(window);
                window->show();
                window->raise();
                window->requestActivate();

                QTimer::singleShot(150, window, [window, centerOnScreen]() {
                    centerOnScreen(window);
                    window->raise();
                    window->requestActivate();
                });
            }
        }
    }, Qt::QueuedConnection);

    QTimer::singleShot(1800, &app, loadMainWindow);
    
    return app.exec();
}
