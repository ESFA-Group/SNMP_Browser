#include "treemodel.h"
#include <QDebug>
#include <QRegularExpression>

// Classify a variable binding by the type prefix net-snmp puts in the raw
// value ("INTEGER: 5", "Timeticks: (123) ...", ...) so the UI can color-code
// and badge values by kind.
static QString detectValueType(const QString& rawValue, const QString& prettyValue)
{
    static const QRegularExpression macRe(
        QStringLiteral("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$"));
    if (macRe.match(prettyValue).hasMatch())
        return QStringLiteral("mac");

    const int colon = rawValue.indexOf(':');
    const QString prefix = colon > 0 ? rawValue.left(colon).trimmed() : QString();

    if (prefix == "INTEGER" || prefix == "Counter32" || prefix == "Counter64" ||
        prefix == "Gauge32" || prefix == "Unsigned32" || prefix == "UInteger32")
        return QStringLiteral("number");
    if (prefix == "STRING")
        return QStringLiteral("text");
    if (prefix == "Hex-STRING" || prefix == "BITS" || prefix == "Opaque")
        return QStringLiteral("hex");
    if (prefix == "IpAddress" || prefix == "Network Address")
        return QStringLiteral("ip");
    if (prefix == "Timeticks")
        return QStringLiteral("time");
    if (prefix == "OID" || prefix == "OBJECT IDENTIFIER")
        return QStringLiteral("oid");
    return QStringLiteral("other");
}

// TreeItem implementation
TreeItem::TreeItem(const QString& oid, const QString& value, const QString& rawValue,
                   const QString& valueType, TreeItem* parent)
    : m_oid(oid)
    , m_value(value)
    , m_rawValue(rawValue)
    , m_valueType(valueType)
    , m_parent(parent)
    , m_expanded(true)
{
}

TreeItem::~TreeItem()
{
    qDeleteAll(m_children);
}

void TreeItem::appendChild(TreeItem* child)
{
    m_children.append(child);
}

TreeItem* TreeItem::child(int row)
{
    if (row < 0 || row >= m_children.size())
        return nullptr;
    return m_children.at(row);
}

int TreeItem::childCount() const
{
    return m_children.size();
}

int TreeItem::columnCount() const
{
    return 2; // OID/Name and Value
}

QVariant TreeItem::data(int column) const
{
    switch (column) {
        case 0: return m_oid;
        case 1: return m_value;
        default: return QVariant();
    }
}

QString TreeItem::rawValue() const
{
    return m_rawValue;
}

QString TreeItem::valueType() const
{
    return m_valueType;
}

int TreeItem::row() const
{
    if (m_parent) {
        return m_parent->m_children.indexOf(const_cast<TreeItem*>(this));
    }
    return 0;
}

TreeItem* TreeItem::parentItem()
{
    return m_parent;
}

bool TreeItem::isGroup() const
{
    return m_value.isEmpty() && !m_children.isEmpty();
}

void TreeItem::setExpanded(bool expanded)
{
    m_expanded = expanded;
}

bool TreeItem::isExpanded() const
{
    return m_expanded;
}

// TreeModel implementation
TreeModel::TreeModel(QObject* parent)
    : QAbstractItemModel(parent)
    , m_itemCount(0)
{
    m_rootItem = new TreeItem("Root", "", "");
}

TreeModel::~TreeModel()
{
    delete m_rootItem;
}

QHash<int, QByteArray> TreeModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[OidRole] = "oid";
    roles[ValueRole] = "value";
    roles[RawValueRole] = "rawValue";
    roles[IsGroupRole] = "isGroup";
    roles[IsExpandedRole] = "isExpanded";
    roles[ValueTypeRole] = "valueType";
    roles[ChildCountRole] = "childCount";
    roles[Qt::DisplayRole] = "display";
    return roles;
}

QModelIndex TreeModel::index(int row, int column, const QModelIndex& parent) const
{
    if (!hasIndex(row, column, parent))
        return QModelIndex();

    TreeItem* parentItem;
    if (!parent.isValid())
        parentItem = m_rootItem;
    else
        parentItem = static_cast<TreeItem*>(parent.internalPointer());

    TreeItem* childItem = parentItem->child(row);
    if (childItem)
        return createIndex(row, column, childItem);
    return QModelIndex();
}

QModelIndex TreeModel::parent(const QModelIndex& index) const
{
    if (!index.isValid())
        return QModelIndex();

    TreeItem* childItem = static_cast<TreeItem*>(index.internalPointer());
    TreeItem* parentItem = childItem->parentItem();

    if (parentItem == m_rootItem)
        return QModelIndex();

    return createIndex(parentItem->row(), 0, parentItem);
}

int TreeModel::rowCount(const QModelIndex& parent) const
{
    TreeItem* parentItem;
    if (!parent.isValid())
        parentItem = m_rootItem;
    else
        parentItem = static_cast<TreeItem*>(parent.internalPointer());

    return parentItem->childCount();
}

int TreeModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return 2;
}

QVariant TreeModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    TreeItem* item = static_cast<TreeItem*>(index.internalPointer());

    switch (role) {
        case Qt::DisplayRole:
            return item->data(index.column());
        case OidRole:
            return item->data(0);
        case ValueRole:
            return item->data(1);
        case RawValueRole:
            return item->rawValue();
        case IsGroupRole:
            return item->isGroup();
        case IsExpandedRole:
            return item->isExpanded();
        case ValueTypeRole:
            return item->valueType();
        case ChildCountRole:
            return item->childCount();
        default:
            return QVariant();
    }
}

Qt::ItemFlags TreeModel::flags(const QModelIndex& index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return QAbstractItemModel::flags(index);
}

QVariant TreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
        switch (section) {
            case 0: return "OID / Parameter";
            case 1: return "Value";
        }
    }
    return QVariant();
}

TreeItem* TreeModel::findOrCreateGroup(const QString& groupName)
{
    if (m_groups.contains(groupName)) {
        return m_groups[groupName];
    }
    
    int row = m_rootItem->childCount();
    beginInsertRows(QModelIndex(), row, row);
    
    TreeItem* groupItem = new TreeItem(groupName, "", "", "", m_rootItem);
    m_rootItem->appendChild(groupItem);
    m_groups[groupName] = groupItem;
    
    endInsertRows();
    
    return groupItem;
}

void TreeModel::addItem(const QString& oid, const QString& rawValue, const QString& prettyValue)
{
    QString groupName;
    QString displayText;
    
    if (oid.contains("::")) {
        int pos = oid.indexOf("::");
        groupName = oid.left(pos);
        displayText = oid.mid(pos + 2);
    } else {
        groupName = "Raw / Unknown";
        displayText = oid;
    }
    
    TreeItem* groupItem = findOrCreateGroup(groupName);
    
    QModelIndex parentIndex = createIndex(groupItem->row(), 0, groupItem);
    int row = groupItem->childCount();
    
    beginInsertRows(parentIndex, row, row);

    TreeItem* childItem = new TreeItem(displayText, prettyValue, rawValue,
                                       detectValueType(rawValue, prettyValue), groupItem);
    groupItem->appendChild(childItem);

    endInsertRows();

    // Keep the group's child-count badge in the view up to date.
    emit dataChanged(parentIndex, parentIndex, {ChildCountRole});

    m_itemCount++;
    emit itemCountChanged();
}

void TreeModel::clear()
{
    beginResetModel();
    
    delete m_rootItem;
    m_rootItem = new TreeItem("Root", "", "", "");
    m_groups.clear();
    m_itemCount = 0;
    
    endResetModel();
    emit itemCountChanged();
}

QString TreeModel::getValueAt(int groupIndex, int childIndex) const
{
    TreeItem* group = m_rootItem->child(groupIndex);
    if (group) {
        TreeItem* child = group->child(childIndex);
        if (child) {
            return child->data(1).toString();
        }
    }
    return QString();
}

QString TreeModel::getRawValueAt(int groupIndex, int childIndex) const
{
    TreeItem* group = m_rootItem->child(groupIndex);
    if (group) {
        TreeItem* child = group->child(childIndex);
        if (child) {
            return child->rawValue();
        }
    }
    return QString();
}

int TreeModel::itemCount() const
{
    return m_itemCount;
}
