# NativeSplitMVVM

UIKit 原生 Tab + 经典 Split 示例，最低部署版本 **iOS 15.0**。由 Xcode MCP 的 iOS App 模板生成工程与 XCTest / UI Test Target，使用纯代码业务界面，无第三方依赖。

## 打开与运行

打开 `NativeSplitMVVM.xcodeproj`，选择 `NativeSplitMVVM` Scheme，再选择 iPhone、iPad 或 iPhone Duo Simulator，运行即可。工程由 Xcode 27.2 生成；iOS 15.0 是 App 最低运行版本，不表示工程格式可以由旧版 Xcode 打开。模拟器无需开发团队；真机运行需选择自己的 Signing Team。

## 控制器结构

展开：

```text
UIWindow
└── UISplitViewController（classic / .unspecified）
    ├── UITabBarController
    │   ├── UINavigationController → 消息列表
    │   ├── UINavigationController → 工作台列表
    │   └── UINavigationController → 通讯录列表
    └── UINavigationController → 聊天 → 聊天信息
```

折叠：

```text
UISplitViewController（collapsed）
└── UITabBarController
    └── 当前 Tab 的 UINavigationController
        └── 列表 → 聊天 → 聊天信息
```

使用 `UISplitViewController(nibName: nil, bundle: nil)`，不是 `.doubleColumn`。经典 Split 通过 `viewControllers` 设置两侧。不要把本工程改成 `setViewController(tab, for: .primary)`；列式 Split 不支持直接把 Tab 控制器作为 primary。

## MVVM 职责

| 目录 | 职责 |
| --- | --- |
| Application | App / Scene 入口；每个 Scene 强引用自己的 Coordinator |
| Models | 演示数据、消息锚点、按 Tab 保存的导航状态 |
| ViewModels | 列表搜索、会话消息、草稿、免打扰和置顶状态；Combine 输出 |
| Views | UIKit 布局、绑定 ViewModel、将用户意图回调给 Coordinator |
| Navigation | 原生容器组合、详情 push、Tab 路由恢复、单双栏转换 |

宽窄布局创建各自的详情 ViewController，共享同一个 `ChatViewModel`。不会把同一个控制器实例同时装到两个导航栈。真实业务应将数据订阅、网络连接与发送队列放在 Repository / Service，不由页面是否出现决定。

## 操作示例

1. 消息列表选择“果子”。
2. 输入草稿，点击右上角“聊天信息”。
3. 打开“消息免打扰”，返回；草稿仍保留。
4. 展开状态下切换“工作台”并选择日程，再切回消息；恢复消息 Tab 的详情路径。
5. 展开状态下在聊天信息页面选择另一个会话；右侧重置到新聊天，左侧 Tab 不参与 push。
6. 旋转或改变可用窗口尺寸；若系统触发 Split 折叠 / 展开，业务路径随之呈现。

折叠状态进入详情后使用 `hidesBottomBarWhenPushed` 隐藏 Tab，返回列表恢复。展开状态右侧不在 Tab 容器内，无需隐藏左侧 Tab。

## 转换与返回手势

- `collapseSecondary:onto:`：从共享路由重建各 Tab 的单栏栈，返回 `true`，阻止 UIKit 再执行默认合并。
- `separateSecondaryFrom:`：左侧恢复各自列表，右侧按当前 Tab 路由重建，返回右侧导航控制器。
- `UINavigationControllerDelegate.didShow`：用已经完成的导航栈同步返回状态；交互式返回取消也以最终实际页面为准。
- 重建栈时通过 `isRendering` 阻止同步回调改写路由。
- 切换前保存草稿和可见消息 ID / 行内偏移。键盘会主动收起，键盘焦点不属于本示例的恢复范围。

## iOS 15 与 Duo

基础功能使用 iOS 15 可用 API，包括 Combine、`UIListContentConfiguration` 与 `keyboardLayoutGuide`。iOS 18 的 Tab mode 使用 availability 判断。根据 Split 的实际折叠 / 展开回调进行布局，不通过设备型号、`UIScreen.main` 或强制 size class 判定。

原生 Tab 的业务归属在左栏；其水平 / 垂直、顶部 / 底部及系统按钮的实际布局由 OS 管理。本例不修改系统 tabBar 的 frame、不搬动私有子视图，也不保证所有 Duo 姿态下都保持截图里的左下角胶囊。Duo 展开时若当前窗口仍为紧凑宽度，也可能保持单栏。

## 范围

这是导航架构示例，不是企业微信完整 UI 克隆。工作台、通讯录详情为占位示例。消息、草稿、设置和导航路径保存在当前进程内，未实现数据库持久化、真实网络、未读数或后台恢复。

实际编译、自动化测试和模拟器验证结果见 `VALIDATION.md`。最终 iPad 预览见 `Validation/ipad-fixed.jpg`。

右侧系统侧栏按钮按显示模式安装：双栏并排时不添加，避免较新系统产生无图标的玻璃圆形；secondary-only 或 overlay 模式才提供该入口。
