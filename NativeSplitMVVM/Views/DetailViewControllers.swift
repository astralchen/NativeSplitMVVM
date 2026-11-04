import UIKit
import Combine

@MainActor
final class ChatInfoViewController: UITableViewController {
    let viewModel: ChatViewModel
    private var subscriptions = Set<AnyCancellable>()
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = "聊天信息"
    }
    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "chat.info.screen"
        viewModel.$isMuted.combineLatest(viewModel.$isPinned)
            .receive(on: RunLoop.main).sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &subscriptions)
    }
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 1 ? 2 : 1 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        if indexPath.section == 0 {
            cell.textLabel?.text = viewModel.item.title
            cell.detailTextLabel?.text = "当前会话"
            cell.imageView?.image = UIImage(systemName: "person.crop.circle.fill")
        } else if indexPath.section == 1 {
            let toggle = UISwitch()
            if indexPath.row == 0 {
                cell.textLabel?.text = "消息免打扰"
                toggle.isOn = viewModel.isMuted
                toggle.accessibilityIdentifier = "info.muted"
                toggle.addTarget(self, action: #selector(mutedChanged(_:)), for: .valueChanged)
            } else {
                cell.textLabel?.text = "置顶聊天"
                toggle.isOn = viewModel.isPinned
                toggle.accessibilityIdentifier = "info.pinned"
                toggle.addTarget(self, action: #selector(pinnedChanged(_:)), for: .valueChanged)
            }
            cell.accessoryView = toggle
        } else {
            cell.textLabel?.text = "布局切换后设置仍保留"
            cell.detailTextLabel?.text = "宽窄页面实例共享同一个 ChatViewModel"
            cell.detailTextLabel?.numberOfLines = 0
        }
        return cell
    }
    @objc private func mutedChanged(_ sender: UISwitch) { viewModel.isMuted = sender.isOn }
    @objc private func pinnedChanged(_ sender: UISwitch) { viewModel.isPinned = sender.isOn }
}

final class SummaryViewController: UIViewController {
    init(title: String, subtitle: String, symbol: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = .systemBlue
        let heading = UILabel()
        heading.text = title
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.textAlignment = .center
        heading.adjustsFontForContentSizeCategory = true
        let body = UILabel()
        body.text = subtitle
        body.font = .preferredFont(forTextStyle: .body)
        body.textColor = .secondaryLabel
        body.textAlignment = .center
        body.numberOfLines = 0
        body.adjustsFontForContentSizeCategory = true
        let stack = UIStackView(arrangedSubviews: [icon, heading, body])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        view.backgroundColor = .systemGroupedBackground
        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalToConstant: 54),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -28)
        ])
    }
    required init?(coder: NSCoder) { fatalError("Use designated initializer") }
}
