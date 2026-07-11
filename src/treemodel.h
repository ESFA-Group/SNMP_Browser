#ifndef TREEMODEL_H
#define TREEMODEL_H

#include <QAbstractItemModel>
#include <QModelIndex>
#include <QVariant>
#include <QList>
#include <memory>

class TreeItem
{
public:
    explicit TreeItem(const QString& oid, const QString& value, const QString& rawValue,
                      const QString& valueType = QString(), TreeItem* parent = nullptr);
    ~TreeItem();

    void appendChild(TreeItem* child);
    TreeItem* child(int row);
    int childCount() const;
    int columnCount() const;
    QVariant data(int column) const;
    QString rawValue() const;
    QString valueType() const;
    int row() const;
    TreeItem* parentItem();
    bool isGroup() const;
    void setExpanded(bool expanded);
    bool isExpanded() const;

private:
    QList<TreeItem*> m_children;
    QString m_oid;
    QString m_value;
    QString m_rawValue;
    QString m_valueType;
    TreeItem* m_parent;
    bool m_expanded;
};

class TreeModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(int itemCount READ itemCount NOTIFY itemCountChanged)

public:
    enum TreeRoles {
        OidRole = Qt::UserRole + 1,
        ValueRole,
        RawValueRole,
        IsGroupRole,
        IsExpandedRole,
        ValueTypeRole,
        ChildCountRole
    };

    explicit TreeModel(QObject* parent = nullptr);
    ~TreeModel();

    // QAbstractItemModel interface
    QVariant data(const QModelIndex& index, int role) const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
    QModelIndex index(int row, int column, const QModelIndex& parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex& index) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Custom methods
    Q_INVOKABLE void addItem(const QString& oid, const QString& rawValue, const QString& prettyValue);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QString getValueAt(int groupIndex, int childIndex) const;
    Q_INVOKABLE QString getRawValueAt(int groupIndex, int childIndex) const;
    
    int itemCount() const;

signals:
    void itemCountChanged();

private:
    TreeItem* findOrCreateGroup(const QString& groupName);
    
    TreeItem* m_rootItem;
    QMap<QString, TreeItem*> m_groups;
    int m_itemCount;
};

#endif // TREEMODEL_H
