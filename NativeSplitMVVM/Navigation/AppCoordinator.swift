import UIKit

/// Owns navigation only. Screen data lives in the ViewModels.
@MainActor
final class AppCoordinator: NSObject {
    let splitViewController = UISplitViewController(nibName: nil, bundle: nil)
    let tabBarController = UITabBarController()
    let detailNavigationController = UINavigationController()
    let viewModel = AppViewModel()
    private(set) var state = NavigationState()
    private var navigationControllers: [AppTab: UINavigationController] = [:]
    private var roots: [AppTab: ListViewController] = [:]
    private var isRendering = false
    private var isCompact = true

    func start(in window: UIWindow) {
        for tab in AppTab.allCases {
            guard let listModel = viewModel.lists[tab] else { continue }
            let root = ListViewController(viewModel: listModel)
            root.onSelect = { [weak self] item in self?.select(item, in: tab) }
            let navigation = UINavigationController(rootViewController: root)
            navigation.delegate = self
            navigation.tabBarItem = UITabBarItem(title: tab.title,
                image: UIImage(systemName: tab.symbol), tag: tab.rawValue)
            navigation.tabBarItem.accessibilityIdentifier = "tab.\(tab.rawValue)"
            roots[tab] = root
            navigationControllers[tab] = navigation
        }
        tabBarController.viewControllers = AppTab.allCases.compactMap { navigationControllers[$0] }
        tabBarController.delegate = self
        // Select the standard tab-bar mode on newer systems. This is not a
        // promise of a fixed bottom-bar frame across every Duo pose.
        if #available(iOS 18.0, *) { tabBarController.mode = .tabBar }
        detailNavigationController.delegate = self
        detailNavigationController.setViewControllers([makePlaceholder()], animated: false)
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        splitViewController.preferredPrimaryColumnWidthFraction = 0.38
        splitViewController.minimumPrimaryColumnWidth = 280
        splitViewController.maximumPrimaryColumnWidth = 420
        splitViewController.viewControllers = [tabBarController, detailNavigationController]
        window.rootViewController = splitViewController
        window.tintColor = .systemBlue
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        isCompact = splitViewController.isCollapsed
        if isCompact { renderCompact() } else { renderExpanded() }
    }

    private var activeNavigation: UINavigationController? {
        isCompact ? navigationControllers[state.selectedTab] : detailNavigationController
    }

    private func select(_ item: DemoItem, in tab: AppTab) {
        guard let navigation = activeNavigation, navigation.transitionCoordinator == nil else { return }
        captureCurrentChat()
        state.select(item.id, in: tab)
        viewModel.lists[tab]?.selectedID = item.id
        let screens = makeDetailStack(for: tab, compact: isCompact)
        let prefix: [UIViewController] = isCompact ? roots[tab].map { [$0] } ?? [] : []
        navigation.setViewControllers(prefix + screens, animated: isCompact)
    }

    private func showInfo(itemID: String) {
        guard let navigation = activeNavigation,
              navigation.transitionCoordinator == nil,
              state.selectedTab == .messages,
              let route = state.routes[.messages],
              route.itemID == itemID, !route.showsInfo,
              let item = viewModel.item(itemID, in: .messages) else { return }
        state.setInfoVisible(true, in: .messages)
        let controller = ChatInfoViewController(viewModel: viewModel.chat(for: item))
        controller.hidesBottomBarWhenPushed = isCompact
        navigation.pushViewController(controller, animated: true)
    }

    private func makeDetailStack(for tab: AppTab, compact: Bool) -> [UIViewController] {
        guard let route = state.routes[tab], let item = viewModel.item(route.itemID, in: tab) else { return [] }
        let screens: [UIViewController]
        if tab == .messages {
            let chatModel = viewModel.chat(for: item)
            let chat = ChatViewController(viewModel: chatModel)
            chat.onShowInfo = { [weak self] in self?.showInfo(itemID: item.id) }
            screens = route.showsInfo ? [chat, ChatInfoViewController(viewModel: chatModel)] : [chat]
        } else {
            screens = [SummaryViewController(title: item.title,
                subtitle: "\(item.subtitle)\n\n此 Tab 的选择独立保存。切回消息可恢复原会话路径。",
                symbol: item.symbol)]
        }
        for screen in screens { screen.hidesBottomBarWhenPushed = compact }
        if let first = screens.first {
            updateSidebarButton(on: first, compact: compact)
        }
        return screens
    }

    private func makePlaceholder() -> UIViewController {
        let controller = SummaryViewController(title: "选择一个项目",
            subtitle: "左侧切换功能，右侧独立浏览详情。", symbol: "rectangle.split.2x1")
        updateSidebarButton(on: controller, compact: isCompact)
        return controller
    }

    /// A classic displayModeButtonItem can leave an empty glass background on
    /// newer OS versions when both columns are already visible. Install it only
    /// when the secondary needs an explicit way to reveal/dismiss the sidebar.
    private func updateSidebarButton(on controller: UIViewController,
                                     compact: Bool,
                                     displayMode: UISplitViewController.DisplayMode? = nil) {
        let mode = displayMode ?? splitViewController.displayMode
        let needsButton = !compact && (mode == .secondaryOnly || mode == .oneOverSecondary)
        controller.navigationItem.leftBarButtonItem = needsButton
            ? splitViewController.displayModeButtonItem : nil
        controller.navigationItem.leftItemsSupplementBackButton = true
    }

    private func captureCurrentChat() {
        for controller in activeNavigation?.viewControllers ?? [] {
            (controller as? ChatViewController)?.captureTransientState()
        }
        splitViewController.viewIfLoaded?.endEditing(true)
    }

    private func renderCompact() {
        isRendering = true
        defer { isRendering = false }
        for tab in AppTab.allCases {
            guard let navigation = navigationControllers[tab], let root = roots[tab] else { continue }
            navigation.setViewControllers([root] + makeDetailStack(for: tab, compact: true), animated: false)
        }
        // Hidden wide controllers do not own active business operations.
        detailNavigationController.setViewControllers([makePlaceholder()], animated: false)
    }

    private func renderExpanded() {
        isRendering = true
        defer { isRendering = false }
        for tab in AppTab.allCases {
            guard let navigation = navigationControllers[tab], let root = roots[tab] else { continue }
            navigation.setViewControllers([root], animated: false)
        }
        let screens = makeDetailStack(for: state.selectedTab, compact: false)
        detailNavigationController.setViewControllers(screens.isEmpty ? [makePlaceholder()] : screens, animated: false)
    }
}

extension AppCoordinator: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController,
                             willChangeTo displayMode: UISplitViewController.DisplayMode) {
        guard let root = detailNavigationController.viewControllers.first else { return }
        updateSidebarButton(on: root, compact: isCompact, displayMode: displayMode)
    }
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        tabBarController
    }
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        tabBarController
    }
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        captureCurrentChat()
        isCompact = true
        renderCompact()
        return true
    }
    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        captureCurrentChat()
        isCompact = false
        renderExpanded()
        return detailNavigationController
    }
}

extension AppCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        captureCurrentChat()
        return activeNavigation?.transitionCoordinator == nil
    }
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController) {
        guard let tab = AppTab(rawValue: tabBarController.selectedIndex) else { return }
        state.selectedTab = tab
        if !isCompact { renderExpanded() }
    }
}

extension AppCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController, animated: Bool) {
        // didShow observes the completed stack, including a cancelled interactive pop.
        guard !isRendering, navigationController === activeNavigation,
              navigationController.topViewController === viewController else { return }
        let tab = state.selectedTab
        if let chat = viewController as? ChatViewController {
            state.select(chat.viewModel.item.id, in: tab)
        } else if viewController is ChatInfoViewController {
            state.setInfoVisible(true, in: tab)
        } else if viewController is ListViewController, isCompact {
            state.returnToList(in: tab)
            viewModel.lists[tab]?.selectedID = nil
        }
    }
}
