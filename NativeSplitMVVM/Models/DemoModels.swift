import Foundation

enum AppTab: Int, CaseIterable {
    case messages, workspace, contacts
    var title: String { ["消息", "工作台", "通讯录"][rawValue] }
    var symbol: String { ["bubble.left.and.bubble.right", "square.grid.2x2", "person.2"][rawValue] }
}

struct DemoItem: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
}

struct Message: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isOutgoing: Bool
    init(text: String, isOutgoing: Bool) {
        id = UUID()
        self.text = text
        self.isOutgoing = isOutgoing
    }
}

struct MessageAnchor {
    let messageID: UUID
    let offsetFromRowTop: Double
}

struct DetailRoute: Equatable {
    let itemID: String
    var showsInfo = false
}

/// Scene-scoped route state. UIKit objects never enter the model.
struct NavigationState {
    var selectedTab: AppTab = .messages
    private(set) var routes: [AppTab: DetailRoute] = [:]
    mutating func select(_ itemID: String, in tab: AppTab) {
        routes[tab] = DetailRoute(itemID: itemID)
    }
    mutating func setInfoVisible(_ visible: Bool, in tab: AppTab) {
        guard var route = routes[tab] else { return }
        route.showsInfo = visible
        routes[tab] = route
    }
    mutating func returnToList(in tab: AppTab) { routes[tab] = nil }
}

/// In-memory demo repository. Replace this boundary with persistence/networking.
final class DemoRepository {
    func items(for tab: AppTab) -> [DemoItem] {
        switch tab {
        case .messages:
            return [
                DemoItem(id: "guozi", title: "果子", subtitle: "一起看看新的分栏界面", symbol: "person.crop.circle.fill"),
                DemoItem(id: "team", title: "设计讨论组", subtitle: "MVVM · UIKit · iOS 15+", symbol: "person.3.fill"),
                DemoItem(id: "support", title: "我的客服", subtitle: "你好，有什么可以帮助你？", symbol: "headphones")
            ]
        case .workspace:
            return [
                DemoItem(id: "schedule", title: "日程", subtitle: "本周的工作安排", symbol: "calendar"),
                DemoItem(id: "documents", title: "文档", subtitle: "团队共享资料", symbol: "doc.text")
            ]
        case .contacts:
            return [
                DemoItem(id: "contact-guozi", title: "果子", subtitle: "产品设计", symbol: "person.crop.circle"),
                DemoItem(id: "contact-lin", title: "小林", subtitle: "iOS 开发", symbol: "person.crop.circle")
            ]
        }
    }
}
