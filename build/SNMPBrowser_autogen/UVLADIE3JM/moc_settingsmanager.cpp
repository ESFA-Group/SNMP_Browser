/****************************************************************************
** Meta object code from reading C++ file 'settingsmanager.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.4.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../src/settingsmanager.h"
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'settingsmanager.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.4.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
namespace {
struct qt_meta_stringdata_SettingsManager_t {
    uint offsetsAndSizes[36];
    char stringdata0[16];
    char stringdata1[10];
    char stringdata2[1];
    char stringdata3[12];
    char stringdata4[16];
    char stringdata5[15];
    char stringdata6[15];
    char stringdata7[15];
    char stringdata8[13];
    char stringdata9[5];
    char stringdata10[5];
    char stringdata11[3];
    char stringdata12[5];
    char stringdata13[9];
    char stringdata14[8];
    char stringdata15[8];
    char stringdata16[8];
    char stringdata17[6];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_SettingsManager_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_SettingsManager_t qt_meta_stringdata_SettingsManager = {
    {
        QT_MOC_LITERAL(0, 15),  // "SettingsManager"
        QT_MOC_LITERAL(16, 9),  // "ipChanged"
        QT_MOC_LITERAL(26, 0),  // ""
        QT_MOC_LITERAL(27, 11),  // "portChanged"
        QT_MOC_LITERAL(39, 15),  // "usernameChanged"
        QT_MOC_LITERAL(55, 14),  // "authKeyChanged"
        QT_MOC_LITERAL(70, 14),  // "privKeyChanged"
        QT_MOC_LITERAL(85, 14),  // "mibPathChanged"
        QT_MOC_LITERAL(100, 12),  // "themeChanged"
        QT_MOC_LITERAL(113, 4),  // "save"
        QT_MOC_LITERAL(118, 4),  // "load"
        QT_MOC_LITERAL(123, 2),  // "ip"
        QT_MOC_LITERAL(126, 4),  // "port"
        QT_MOC_LITERAL(131, 8),  // "username"
        QT_MOC_LITERAL(140, 7),  // "authKey"
        QT_MOC_LITERAL(148, 7),  // "privKey"
        QT_MOC_LITERAL(156, 7),  // "mibPath"
        QT_MOC_LITERAL(164, 5)   // "theme"
    },
    "SettingsManager",
    "ipChanged",
    "",
    "portChanged",
    "usernameChanged",
    "authKeyChanged",
    "privKeyChanged",
    "mibPathChanged",
    "themeChanged",
    "save",
    "load",
    "ip",
    "port",
    "username",
    "authKey",
    "privKey",
    "mibPath",
    "theme"
};
#undef QT_MOC_LITERAL
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_SettingsManager[] = {

 // content:
      10,       // revision
       0,       // classname
       0,    0, // classinfo
       9,   14, // methods
       7,   77, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       7,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    0,   68,    2, 0x06,    8 /* Public */,
       3,    0,   69,    2, 0x06,    9 /* Public */,
       4,    0,   70,    2, 0x06,   10 /* Public */,
       5,    0,   71,    2, 0x06,   11 /* Public */,
       6,    0,   72,    2, 0x06,   12 /* Public */,
       7,    0,   73,    2, 0x06,   13 /* Public */,
       8,    0,   74,    2, 0x06,   14 /* Public */,

 // methods: name, argc, parameters, tag, flags, initial metatype offsets
       9,    0,   75,    2, 0x02,   15 /* Public */,
      10,    0,   76,    2, 0x02,   16 /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,

 // methods: parameters
    QMetaType::Void,
    QMetaType::Void,

 // properties: name, type, flags
      11, QMetaType::QString, 0x00015103, uint(0), 0,
      12, QMetaType::Int, 0x00015103, uint(1), 0,
      13, QMetaType::QString, 0x00015103, uint(2), 0,
      14, QMetaType::QString, 0x00015103, uint(3), 0,
      15, QMetaType::QString, 0x00015103, uint(4), 0,
      16, QMetaType::QString, 0x00015103, uint(5), 0,
      17, QMetaType::QString, 0x00015103, uint(6), 0,

       0        // eod
};

Q_CONSTINIT const QMetaObject SettingsManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_SettingsManager.offsetsAndSizes,
    qt_meta_data_SettingsManager,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_SettingsManager_t,
        // property 'ip'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // property 'port'
        QtPrivate::TypeAndForceComplete<int, std::true_type>,
        // property 'username'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // property 'authKey'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // property 'privKey'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // property 'mibPath'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // property 'theme'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<SettingsManager, std::true_type>,
        // method 'ipChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'portChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'usernameChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'authKeyChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'privKeyChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'mibPathChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'themeChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'save'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'load'
        QtPrivate::TypeAndForceComplete<void, std::false_type>
    >,
    nullptr
} };

void SettingsManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<SettingsManager *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->ipChanged(); break;
        case 1: _t->portChanged(); break;
        case 2: _t->usernameChanged(); break;
        case 3: _t->authKeyChanged(); break;
        case 4: _t->privKeyChanged(); break;
        case 5: _t->mibPathChanged(); break;
        case 6: _t->themeChanged(); break;
        case 7: _t->save(); break;
        case 8: _t->load(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (SettingsManager::*)();
            if (_t _q_method = &SettingsManager::ipChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (SettingsManager::*)();
            if (_t _q_method = &SettingsManager::portChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (SettingsManager::*)();
            if (_t _q_method = &SettingsManager::usernameChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (SettingsManager::*)();
            if (_t _q_method = &SettingsManager::authKeyChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (SettingsManager::*)();
            if (_t _q_method = &SettingsManager::privKeyChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 4;
                return;
            }
        }
        {
            using _t = void (SettingsManager::*)();
            if (_t _q_method = &SettingsManager::mibPathChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 5;
                return;
            }
        }
        {
            using _t = void (SettingsManager::*)();
            if (_t _q_method = &SettingsManager::themeChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 6;
                return;
            }
        }
    }else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<SettingsManager *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = _t->ip(); break;
        case 1: *reinterpret_cast< int*>(_v) = _t->port(); break;
        case 2: *reinterpret_cast< QString*>(_v) = _t->username(); break;
        case 3: *reinterpret_cast< QString*>(_v) = _t->authKey(); break;
        case 4: *reinterpret_cast< QString*>(_v) = _t->privKey(); break;
        case 5: *reinterpret_cast< QString*>(_v) = _t->mibPath(); break;
        case 6: *reinterpret_cast< QString*>(_v) = _t->theme(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        auto *_t = static_cast<SettingsManager *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setIp(*reinterpret_cast< QString*>(_v)); break;
        case 1: _t->setPort(*reinterpret_cast< int*>(_v)); break;
        case 2: _t->setUsername(*reinterpret_cast< QString*>(_v)); break;
        case 3: _t->setAuthKey(*reinterpret_cast< QString*>(_v)); break;
        case 4: _t->setPrivKey(*reinterpret_cast< QString*>(_v)); break;
        case 5: _t->setMibPath(*reinterpret_cast< QString*>(_v)); break;
        case 6: _t->setTheme(*reinterpret_cast< QString*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    } else if (_c == QMetaObject::BindableProperty) {
    }
    (void)_a;
}

const QMetaObject *SettingsManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *SettingsManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_SettingsManager.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int SettingsManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 9)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 9;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 9)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 9;
    }else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 7;
    }
    return _id;
}

// SIGNAL 0
void SettingsManager::ipChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void SettingsManager::portChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void SettingsManager::usernameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void SettingsManager::authKeyChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void SettingsManager::privKeyChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void SettingsManager::mibPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void SettingsManager::themeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
