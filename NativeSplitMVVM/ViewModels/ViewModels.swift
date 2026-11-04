import Foundation
import Combine

@MainActor
final class ListViewModel {
    let tab: AppTab
    let items: [DemoItem]
    @Published var query = ""
    @Published var selectedID: String?
    var filteredItems: [DemoItem] {
        query.isEmpty ? items : items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }
    init(tab: AppTab, repository: DemoRepository) {
        self.tab = tab
        items = repository.items(for: tab)
    }
}

@MainActor
final class ChatViewModel {
    let item: DemoItem
    @Published private(set) var messages: [Message]
    @Published var draft = ""
    @Published var isMuted = false
    @Published var isPinned = false
    var scrollAnchor: MessageAnchor?

    init(item: DemoItem) {
        self.item = item
        messages = [
            Message(text: "你好！这里是原生 UIKit 分栏示例。", isOutgoing: false),
            Message(text: "左侧 Tab 和右侧导航栈可以独立工作。", isOutgoing: false),
            Message(text: "点击右上角进入聊天信息，再试试切换窗口尺寸。", isOutgoing: false),
            Message(text: "草稿、会话设置和消息位置由共享 ViewModel 保存。", isOutgoing: true)
        ]
    }

    @discardableResult
    func send() -> Bool {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        messages.append(Message(text: text, isOutgoing: true))
        draft = ""
        return true
    }
}

/// Shares business state between compact and expanded controller instances.
@MainActor
final class AppViewModel {
    private let repository: DemoRepository
    let lists: [AppTab: ListViewModel]
    private var chats: [String: ChatViewModel] = [:]

    init() {
        let repository = DemoRepository()
        self.repository = repository
        lists = Dictionary(uniqueKeysWithValues: AppTab.allCases.map {
            ($0, ListViewModel(tab: $0, repository: repository))
        })
    }

    func item(_ id: String, in tab: AppTab) -> DemoItem? {
        lists[tab]?.items.first { $0.id == id }
    }

    func chat(for item: DemoItem) -> ChatViewModel {
        if let existing = chats[item.id] { return existing }
        let model = ChatViewModel(item: item)
        chats[item.id] = model
        return model
    }
}
