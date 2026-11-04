# 验证记录

## 2026-11-04：Duo 实际姿态切换复核

在 Xcode 27.2 / iOS 27.2 的 iPhone Duo Simulator 上，使用 **Device Hub** 的 Closed、Partially Open、Open 按钮执行了同一进程内连续 14 次姿态切换。App 源码为 `836510747283b8b4f745dcdf773724817850d7cc`；XcodeBuildMCP `build_run_sim` 重新构建、安装和启动成功，构建日志包含 `BUILD SUCCEEDED`。本次只补充验证文档和截图，没有修改业务代码。

通过 Device Hub 的界面操作、无障碍值和实际截图核验以下路径，均未观察到 Tab 丢失、导航跳错、草稿丢失或串会话：

| 场景 | 实际结果 |
| --- | --- |
| Closed 聊天输入 `Duo-fold-draft-1104` → Open | 左侧列表及三个原生 Tab 恢复，右侧仍为果子聊天，草稿内容一致 |
| Open 聊天信息打开免打扰 → Closed → Open | 两种布局均停留在聊天信息，`info.muted` 保持 `1`；单栏详情隐藏 Tab，展开后左栏 Tab 恢复 |
| 信息页 → 工作台 → 日程 → Closed → Open → 消息 | 工作台选择及日程详情保持；回消息恢复果子聊天信息和免打扰，返回聊天后原草稿仍在 |
| 信息页返回聊天 → Closed → 返回列表 → Open | 不会恢复已经 pop 的信息页或聊天；右侧显示“选择一个项目” |
| 重新选择果子 | 路由已清除，但会话草稿仍为 `Duo-fold-draft-1104` |
| 更新为 `Duo-keyboard-draft-1104` → Partially Open → Closed → Open | 半展开时输入栏位于软件键盘上方；折叠时键盘收起，草稿保留，再展开内容一致 |
| 设计讨论组输入 `Team-only-draft` → 果子 | 两个会话分别保留自己的草稿，没有混用 |
| 果子发送 → Closed → Open | 已发送文本仍显示在消息列表；草稿为空，没有因开合恢复已发送文本 |
| 再选设计讨论组 | 草稿仍为 `Team-only-draft` |
| 通讯录 → 小林 → Closed → Open → 消息 | 通讯录 Tab 和小林详情保持；切回消息恢复设计讨论组及其草稿 |

这轮验证通过 CUA 操作真实模拟器界面完成，**不是新增 XCTest 通过数量**，也不是通过旋转代替折叠。完整的可复现步骤及证据索引见 [Duo 验证记录](Validation/duo-fold-validation.md)。此前 2026-11-03 的 Duo 开合未验证结论由本节补充；历史记录仍保留如下。

边界：尚未验证取消交互式返回手势、切换动画中连续点击、长列表锚点、进程终止恢复、全部窗口尺寸、真机及 iOS 15 runtime。键盘焦点不在恢复范围内，折叠时主动收起符合当前实现。

## 2026-11-03：首次验证

日期：2026-11-03（Asia/Shanghai）。工程通过 Xcode MCP `XcodeNewProject` 创建，App、XCTest、UI Test Target 均由模板生成，业务代码为 UIKit + MVVM + Coordinator。

## 已确认

- Xcode 27.2 / Build 27B52。
- App 最低部署版本为 iOS 15.0，使用 Swift 5 language mode。
- Xcode MCP `BuildProject(buildForTesting: true)` 成功，App 与测试 Target 编译通过。
- iPhone 18 Pro / iOS 27.2：4 个单元测试通过，0 失败。
  - 各 Tab 独立保存导航路径。
  - 选择新会话清除旧聊天信息路径。
  - 宽窄页面共享会话 ViewModel，保留草稿、设置且不同会话相互隔离。
  - 发送过滤空白，成功后清空草稿并追加消息。
- iPhone 18 Pro / iOS 27.2：2 个 UI 测试通过，0 失败。
  - 聊天 → 聊天信息 → 返回：草稿保留、免打扰设置保留。
  - 在聊天信息页旋转、返回聊天后再旋转：保持当前导航位置，没有重新出现已经 pop 的聊天信息页。
- Duo / iOS 27.2 特殊 runtime：App 安装、启动成功，外屏单栏页面实际截图见 `Validation/duo-outer.png`。截图中原生 Tab 被系统放在右边缘，符合交由系统自适应的实现策略。

- iPad (A16) / iOS 27.2：直接安装启动成功，实际截图确认左侧 Tab + 列表、右侧独立占位详情布局，见 `Validation/ipad-expanded.jpg`。这是一张布局证据，不代表全部展开交互已通过。

- iPad (A16) / iOS 27.2：随后通过 XcodeBuildMCP 重试展开交互测试，底层日志记录 **1 test passed, 0 failures** 和 **TEST EXECUTE SUCCEEDED**。覆盖右侧信息页时操作左侧 Tab、切换 Tab 恢复路径、选择新会话重置详情；见 `Validation/ipad-ui-summary.txt`（原始 `ipad-ui-test.txt` 保留在本地）。

## 环境中断与证据边界

- 初次 `RunAllTests` 长时间未结束，由本次任务主动停止，工具返回 cancelled。该轮不计入通过数量；后续指定测试运行取得了上述 4 + 2 项通过结果。
- iPad (A16) 的 `testExpandedTabAndDetailAreIndependent` 首次尝试返回 `BSServiceConnectionErrorDomain Code=3` / XPC reply error，没有取得通过结果。随后 Xcode MCP 的重试连接返回 `Transport closed`。再切换至 XcodeBuildMCP 后底层测试通过，但 MCP 调用本身超过 300 秒返回超时；通过结论来自已完成的底层测试日志，而不是超时返回值。
- Duo 的自动化层级读取多次超时，通用截图工具也无法自动选择两个显示屏。改用指定 display 的 simctl 截图；display 3 当时为黑屏，保留为 `Validation/duo-inactive-display.png`，不作为展开成功证据。
- 本机 Simulator 前端为较旧版本，本次没有取得可用的 Duo 姿态切换控制；没有完成 Duo 展开及动态开合验证。
- iPhone 旋转测试不等同于 Split 折叠 / 展开测试：若设备尺寸类别保持 compact，该测试只覆盖旋转时的状态保持。
- 没有 iOS 15 runtime，未执行 iOS 15 运行测试，也未进行真机验证。
- Xcode 27.2 的 XCTest dylib 链接最低版本高于 15.0，测试 Target 构建出现对应 warning；这是测试工具链限制。App 目标以 iOS 15.0 编译成功，但不能据此声称 iOS 15 已实测。

## 首次验证时的待核验项（状态更新见上方 2026-11-04 记录）

1. Duo Open / Landscape 下：左栏为 Tab + 列表，右栏为详情导航。
2. 聊天信息页反复开合：折叠后仍在信息页，展开后左侧回列表、右侧仍在信息页。
3. 单栏完整返回及取消返回手势后展开：路由与最终显示页面一致。
4. 在 Duo 上复核右侧处于信息页时切换 Tab 再返回（该路径已在 iPad 自动化通过）。
5. 多条消息长列表、键盘显示、窗口缩放、Dynamic Type、分屏窗口。
6. 用可运行 iOS 15 的设备 / 工具链验证基础系统版本。

`Validation/` 保存构建日志及成功测试的摘要；完整 xcresult 仍位于本机 Xcode 工具的 ActionArtifacts 目录，未打包进示例压缩包。

## 用户截图中的空白圆形按钮

已将右侧 `displayModeButtonItem` 改为按显示模式安装：双栏并排时移除；仅在 secondary-only 或 overlay 模式提供侧栏入口。上述 7 项测试在这次按钮外观修正之前运行；最终修正的编译与截图结果单独记录，不混同为整套测试重跑。

最终按钮修正后，XcodeBuildMCP 再次构建成功（215.9 秒），并重新安装启动到 iPad (A16)。最终编译摘要见 `Validation/build-summary.txt`，原始 `final-build.txt` 保留在本地。

最终截图 `Validation/ipad-fixed.jpg` 与无障碍层级共同确认右侧空白按钮已移除（此前 6 个可操作项减少为 5 个，空标签按钮消失）。尝试点击左侧 Hide Sidebar 后自动化快照未呈现稳定变化，未将隐藏/恢复循环记为通过。

## GitHub 提交范围

仓库包含源码、测试、说明、截图与不含本机路径的结果摘要。原始构建日志、iPad 测试完整日志、Xcode 用户配置通过 `.gitignore` 排除，仍保留在本地交付目录。
