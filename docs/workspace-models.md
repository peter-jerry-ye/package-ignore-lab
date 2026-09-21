# Workspace 声明文件和目录边界是两个问题

| 工具 | 声明位置 | 成员可以是 `../child` 这样的外部目录吗？ | 证据 |
| --- | --- | --- | --- |
| Dart pub | `pubspec.yaml` 的 `workspace`；成员声明 `resolution: workspace` | 不可以，成员必须是声明目录的子目录 | [Scrut](../tests/workspace-paths/dart.md)、[官方诊断](https://dart.dev/tools/diagnostics/workspace_value_not_subdirectory) |
| npm | `package.json` 的 `workspaces` | 可以：从根目录枚举会识别外部成员 | [Scrut](../tests/workspace-paths/npm.md)、[声明文档](https://docs.npmjs.com/cli/v11/configuring-npm/package-json/#workspaces) |
| pnpm | 独立的 `pnpm-workspace.yaml` 的 `packages` | 可以：从根目录枚举会识别外部成员 | [Scrut](../tests/workspace-paths/pnpm.md)、[配置文档](https://pnpm.io/settings#packages) |
| Cargo | `Cargo.toml` 的 `[workspace]`；允许没有 `[package]` 的 virtual manifest | 可以；外部成员可用 `package.workspace` 指回 workspace 根目录 | [Cargo workspace 文档](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-members-and-exclude-fields)、[成员的 workspace 字段](https://doc.rust-lang.org/cargo/reference/manifest.html#the-workspace-field) |
| Go | 独立的 `go.work` 的 `use` | 可以；官方示例就有 `../othermod`，也接受绝对路径 | [Go Modules Reference](https://go.dev/ref/mod#go-work-file-use) |

因此，按声明位置分类，Dart/npm 更接近 Cargo，pnpm 更接近 Go；但 **“写在 manifest 里”不意味着成员必须位于该目录内**，Cargo/npm 就是反例。应分别讨论声明文件、成员路径限制、workspace 的查找方式，以及打包时 ignore 的边界。

上表前三项有自动执行的最小测试。Cargo/Go 的结论引用官方文档，本仓库没有为它们增加工具安装或 CI 测试。

## 外部成员和自动发现不是同一件事

这三个测试从 `parent` 执行命令。即使 `parent` 声明了 `../child`，也不能据此断言从 `child` 执行命令会自动知道兄弟目录中的 workspace。

Cargo 为这种布局提供显式的 `package.workspace` 字段。Go 默认向上找 `go.work`，也可以通过 `GOWORK` 指定它；这解释了为什么“允许外部成员”不等于“任意目录都能自动找到同一个 workspace”。[Cargo 文档](https://doc.rust-lang.org/cargo/reference/manifest.html#the-workspace-field)、[Go workspace 模式](https://go.dev/ref/mod#workspaces)

npm 文档主要用嵌套目录示例，但成员解析实现会展开相对目录模式；`../child` 的支持在这里由实际命令确认。这个测试只验证成员枚举，不将它推广为所有安装、打包和自动发现行为的保证。[npm 实现](https://github.com/npm/map-workspaces/blob/v5.0.3/lib/index.js)

## 与本仓库 ignore 测试的关系

Workspace 成员列表决定哪些包一起参与工具操作；它并不自动决定发布包包含哪些文件，也不自动决定应该继承哪个目录的 ignore。Dart 和 npm 在这两层上采用不同规则，不能根据 workspace 声明语法推导打包语义。请分别查看 [只在 child 建 Git 仓库的测试](../tests/child-git/)与[没有 Git 的测试](../tests/without-git/)。
