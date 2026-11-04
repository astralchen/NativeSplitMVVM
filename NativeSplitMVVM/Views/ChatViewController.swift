import UIKit
import Combine

@MainActor
final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    let viewModel: ChatViewModel
    var onShowInfo: (() -> Void)?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let textField = UITextField()
    private var subscriptions = Set<AnyCancellable>()
    private var didRestoreAnchor = false
    private var wantsScrollToBottom = false

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = viewModel.item.title
        navigationItem.backButtonTitle = "聊天"
    }
    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "chat.screen"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"), style: .plain,
            target: self, action: #selector(showInfo))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "聊天信息"
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "chat.info"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.accessibilityIdentifier = "chat.messages"

        textField.placeholder = "输入消息，切换布局后草稿仍保留"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.returnKeyType = .send
        textField.delegate = self
        textField.accessibilityIdentifier = "chat.draft"
        textField.addTarget(self, action: #selector(draftChanged), for: .editingChanged)
        textField.text = viewModel.draft
        let send = UIButton(type: .system)
        send.setTitle("发送", for: .normal)
        send.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        send.accessibilityIdentifier = "chat.send"
        send.setContentHuggingPriority(.required, for: .horizontal)
        send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        let composer = UIStackView(arrangedSubviews: [textField, send])
        composer.axis = .horizontal
        composer.spacing = 12
        composer.alignment = .center
        for child in [tableView, composer] {
            child.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child)
        }
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safe.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -8),
            composer.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            composer.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            composer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8),
            composer.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        viewModel.$messages.receive(on: RunLoop.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
            if self.wantsScrollToBottom {
                self.wantsScrollToBottom = false
                self.scrollToBottom()
            }
        }.store(in: &subscriptions)
        viewModel.$draft.receive(on: RunLoop.main).sink { [weak self] draft in
            guard self?.textField.text != draft else { return }
            self?.textField.text = draft
        }.store(in: &subscriptions)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didRestoreAnchor, tableView.bounds.height > 0 else { return }
        didRestoreAnchor = true
        if let anchor = viewModel.scrollAnchor,
           let row = viewModel.messages.firstIndex(where: { $0.id == anchor.messageID }) {
            tableView.layoutIfNeeded()
            let rect = tableView.rectForRow(at: IndexPath(row: row, section: 0))
            let y = rect.minY + CGFloat(anchor.offsetFromRowTop) - tableView.adjustedContentInset.top
            let lower = -tableView.adjustedContentInset.top
            let upper = max(lower, tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
            tableView.setContentOffset(CGPoint(x: 0, y: min(upper, max(lower, y))), animated: false)
        }
    }

    func captureTransientState() {
        guard isViewLoaded else { return }
        viewModel.draft = textField.text ?? ""
        guard let index = tableView.indexPathsForVisibleRows?.sorted().first,
              viewModel.messages.indices.contains(index.row) else { return }
        let rect = tableView.rectForRow(at: index)
        viewModel.scrollAnchor = MessageAnchor(
            messageID: viewModel.messages[index.row].id,
            offsetFromRowTop: Double(tableView.contentOffset.y + tableView.adjustedContentInset.top - rect.minY))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureTransientState()
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { captureTransientState() }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { captureTransientState() }
    }
    @objc private func showInfo() { captureTransientState(); onShowInfo?() }
    @objc private func draftChanged() { viewModel.draft = textField.text ?? "" }
    @objc private func sendMessage() {
        draftChanged()
        wantsScrollToBottom = true
        if !viewModel.send() { wantsScrollToBottom = false }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { sendMessage(); return false }
    private func scrollToBottom() {
        guard !viewModel.messages.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: viewModel.messages.count - 1, section: 0), at: .bottom, animated: false)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewModel.messages.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.messages[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        var content = cell.defaultContentConfiguration()
        content.text = message.text
        content.textProperties.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = message.isOutgoing ? .right : .natural
        content.attributedText = NSAttributedString(string: message.text, attributes: [.paragraphStyle: paragraph])
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        cell.contentConfiguration = content
        cell.backgroundColor = message.isOutgoing ? UIColor.systemBlue.withAlphaComponent(0.09) : .secondarySystemGroupedBackground
        cell.selectionStyle = .none
        return cell
    }
}
