# 验证记录

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

## 仍需手动核验

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
