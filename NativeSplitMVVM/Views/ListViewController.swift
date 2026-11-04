import UIKit
import Combine

@MainActor
final class ListViewController: UITableViewController, UISearchResultsUpdating {
    let viewModel: ListViewModel
    var onSelect: ((DemoItem) -> Void)?
    private var subscriptions = Set<AnyCancellable>()
    private let searchController = UISearchController(searchResultsController: nil)

    init(viewModel: ListViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
        title = viewModel.tab.title
        navigationItem.backButtonTitle = "返回"
    }
    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "list.\(viewModel.tab.rawValue)"
        tableView.rowHeight = 78
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .systemBackground
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索\(viewModel.tab.title)"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        viewModel.$query.sink { [weak self] _ in
            // @Published emits before assignment; reload on the next main run loop.
            DispatchQueue.main.async { self?.tableView.reloadData(); self?.restoreSelection() }
        }.store(in: &subscriptions)
        viewModel.$selectedID.sink { [weak self] _ in
            DispatchQueue.main.async { self?.restoreSelection() }
        }.store(in: &subscriptions)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearsSelectionOnViewWillAppear = false
        restoreSelection()
    }

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.query = searchController.searchBar.text ?? ""
    }

    private func restoreSelection() {
        if let row = viewModel.filteredItems.firstIndex(where: { $0.id == viewModel.selectedID }) {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        } else if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: false)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredItems.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.filteredItems[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = item.title
        configuration.secondaryText = item.subtitle
        configuration.secondaryTextProperties.color = .secondaryLabel
        configuration.image = UIImage(systemName: item.symbol)
        configuration.imageProperties.tintColor = .systemBlue
        configuration.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        cell.contentConfiguration = configuration
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "item.\(item.id)"
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.filteredItems[indexPath.row]
        searchController.isActive = false
        onSelect?(item)
    }
}
