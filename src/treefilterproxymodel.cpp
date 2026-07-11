#include "treefilterproxymodel.h"
#include "treemodel.h"

TreeFilterProxyModel::TreeFilterProxyModel(QObject* parent)
    : QSortFilterProxyModel(parent)
    , m_matchCount(0)
{
    setRecursiveFilteringEnabled(true);
    setFilterCaseSensitivity(Qt::CaseInsensitive);

    // Recounting walks the whole tree; compress bursts of row insertions
    // during a scan into one recount.
    m_recountTimer.setSingleShot(true);
    m_recountTimer.setInterval(100);
    connect(&m_recountTimer, &QTimer::timeout, this, &TreeFilterProxyModel::recountMatches);

    connect(this, &QAbstractItemModel::rowsInserted, this, &TreeFilterProxyModel::scheduleRecount);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &TreeFilterProxyModel::scheduleRecount);
    connect(this, &QAbstractItemModel::modelReset, this, &TreeFilterProxyModel::scheduleRecount);
}

QString TreeFilterProxyModel::filterText() const
{
    return m_filterText;
}

void TreeFilterProxyModel::setFilterText(const QString& text)
{
    if (m_filterText == text)
        return;

    m_filterText = text;
    invalidateFilter();
    emit filterTextChanged();
    scheduleRecount();
}

int TreeFilterProxyModel::matchCount() const
{
    return m_matchCount;
}

bool TreeFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    if (m_filterText.isEmpty())
        return true;

    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;

    const QString oid = idx.data(TreeModel::OidRole).toString();
    const QString value = idx.data(TreeModel::ValueRole).toString();

    return oid.contains(m_filterText, Qt::CaseInsensitive)
        || value.contains(m_filterText, Qt::CaseInsensitive);
}

void TreeFilterProxyModel::scheduleRecount()
{
    m_recountTimer.start();
}

int TreeFilterProxyModel::countLeaves(const QModelIndex& parent) const
{
    int count = 0;
    const int rows = rowCount(parent);
    for (int i = 0; i < rows; ++i) {
        const QModelIndex idx = index(i, 0, parent);
        if (rowCount(idx) > 0)
            count += countLeaves(idx);
        else if (!idx.data(TreeModel::IsGroupRole).toBool())
            ++count;
    }
    return count;
}

void TreeFilterProxyModel::recountMatches()
{
    const int count = countLeaves(QModelIndex());
    if (count != m_matchCount) {
        m_matchCount = count;
        emit matchCountChanged();
    }
}
