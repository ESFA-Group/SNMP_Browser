#ifndef TREEFILTERPROXYMODEL_H
#define TREEFILTERPROXYMODEL_H

#include <QSortFilterProxyModel>
#include <QTimer>

class TreeFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    Q_PROPERTY(int matchCount READ matchCount NOTIFY matchCountChanged)

public:
    explicit TreeFilterProxyModel(QObject* parent = nullptr);

    QString filterText() const;
    void setFilterText(const QString& text);
    int matchCount() const;

signals:
    void filterTextChanged();
    void matchCountChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;

private:
    void scheduleRecount();
    void recountMatches();
    int countLeaves(const QModelIndex& parent) const;

    QString m_filterText;
    int m_matchCount;
    QTimer m_recountTimer;
};

#endif // TREEFILTERPROXYMODEL_H
