# Package ignore lab

[![验证行为](https://github.com/peter-jerry-ye/package-ignore-lab/actions/workflows/verify.yml/badge.svg)](https://github.com/peter-jerry-ye/package-ignore-lab/actions/workflows/verify.yml)

用可执行的 Markdown 验证嵌套包、workspace 和 ignore 的关系。**直接读下面的表和测试文档即可，无需翻 CI 日志。**

每个测试文档先用 `mkdir`、`cat <<EOF`、`printf` 创建文件，再执行真正的打包命令。代码块中 `$` 是命令，`>` 是命令续行，其余是必须匹配的输出。GitHub Actions 用最新版工具重新执行；输出改变就失败，不会自动“更新成通过”。

## 验证了什么

对应目录是：

```text
repo/                         # Git 根，也是父包
├── <父包 manifest>
├── <workspace 配置>
├── <ignore 文件>
├── secret.txt
└── editor/                   # 独立子包
    ├── <子包 manifest>
    ├── secret.txt
    ├── public.txt            # Dart/MoonBit 对应 lib/*.dart / main.mbt
    └── editor/
        └── inside.txt        # 专门用来观察 /editor 的锚点
```

| 场景 | Mooncake | Dart pub | npm | pnpm |
| --- | --- | --- | --- | --- |
| 没有 ignore，打包父包 | 包含子包 | 包含子包 | 包含子包 | 包含子包 |
| 父 ignore 写 `/editor`，打包父包 | 排除子包 | 排除子包 | 排除子包 | 排除子包 |
| 同一条 `/editor`，进入 workspace 子包打包 | **空 ZIP** | **空文件清单** | 子包有内容，排除它里面的 `editor/` | 子包有内容，排除它里面的 `editor/` |
| 父 ignore 写 `/secret.txt`，打包子包 | 保留子包的 `secret.txt` | 保留子包的 `secret.txt` | 排除子包的 `secret.txt` | 排除子包的 `secret.txt` |
| 父 ignore 写 `secret.txt`，打包 workspace 子包 | 排除 | 排除 | 排除 | 排除 |
| 上一场景中给子包加空的专用 ignore 文件 | 仍排除 | 仍排除 | 仍排除 | **重新包含** |
| 子专用 ignore 写 `!secret.txt` | 重新包含 | 重新包含 | 重新包含 | 重新包含 |
| 根本没有 workspace 声明，父规则是否仍继承 | Git 仓库内仍继承 | Git 仓库内仍继承 | 普通嵌套包不继承 | 普通嵌套包不继承 |

表中的“父 ignore”分别是 `.moonignore`、`.pubignore`、`.npmignore`、`.npmignore`。前两列的继承场景在 Git 仓库中；后两列标注 workspace 的场景都有对应 workspace 配置。不能把这些前提省略后泛化成“所有嵌套包”。

直接查看完整输入输出：

- [Mooncake：17 个测试块](tests/mooncake.md)：检查实际 ZIP 的**全部条目**；还验证移除 `moon.work`、移除 `.git`、父目录重新包含后的文件过滤。
- [Dart：17 个测试块](tests/dart.md)：保留 dry-run **完整输出**；还验证 `publish_to: none` 的嵌套示例仍可出现在父包清单中。
- [npm：16 个测试块](tests/npm.md)：完整文件清单、父规则锚点、allowlist，以及显式递归打包与普通打包的区别；最后检查实际 tarball。
- [pnpm：18 个测试块](tests/pnpm.md)：相同对照，加上 `.pnpmignore` 不作为 ignore 配置、递归打包仍包含子包；最后检查实际 tarball。
- [Git：7 个测试块](tests/git.md)：用 `git check-ignore --no-index -v` 显示命中的规则、来源和行号。

总计 **75 个可执行代码块**，包括 fixture 创建步骤。

## 这些测试的边界

- Dart 使用 `publish --dry-run --skip-validation`，用于观察文件选择；空清单**不代表正常发布验证会接受空包**。没有上传任何包。
- Mooncake 使用 `moon package` 创建 ZIP，没有调用 `moon publish`。
- npm/pnpm 的 JSON 只提取全部文件路径并排序；不按文件名筛选，也不隐藏意外文件。Dart 输出不做归一化。stdout、stderr 和退出码都参与断言，shell 开启 `set -euo pipefail`。
- 每个文档有独立临时目录；同一文档内各步骤按顺序共享状态。所有 `secret.txt`、`.env` 都是明确写出的虚构数据。
- “默认跳过嵌套 module，可显式包含”是 Mooncake 的[提案](https://github.com/moonbitlang/mooncake/issues/59)，不是这些工具已经实现的行为。
- 测试可以证明某个例子会发生什么，不能证明维护者当年的设计动机。Flutter 的[官方嵌套示例配置](https://github.com/flutter/packages/blob/main/packages/url_launcher/url_launcher/example/pubspec.yaml)明确说明它随插件打包；**“兼容既有示例可能是 Dart 不改默认值的原因”仍然只是推断**。
- [npm CVE-2022-29244 公告](https://github.com/npm/cli/security/advisories/GHSA-hj9c-8jmm-8c52)是历史资料。这个仓库按最新版运行，不把历史版本对照或“其他软件是否构成 CVE”算作已验证结论。

## 运行

GitHub Actions 自动安装最新版 Node、npm、pnpm、Dart、MoonBit 和 Scrut。Node 用 `setup-node`，Dart 用 `setup-dart`，MoonBit 用 `setup-moonbit`，Scrut 使用上游最新 release。实际版本会随测试一起输出。升级导致行为改变时，CI 会失败，需人工检查差异。

自己运行时，需要 Bash、Git、Python 3、jq、tar，以及上述 CLI。Node 可以用 [nvm](https://github.com/nvm-sh/nvm)：

```bash
nvm install
nvm use
npm install --global npm@latest pnpm@latest
```

其他工具使用各自的安装方式：[Dart](https://dart.dev/get-dart)、[MoonBit](https://www.moonbitlang.com/download/)、[Scrut](https://github.com/facebookincubator/scrut)。安装后：

```bash
./scripts/test.sh
# 或只运行一个文档：
scrut test tests/dart.md
```

Scrut 就是负责执行和比较 Markdown 的工具，无需额外的 fixture DSL。创建目录和文件的 shell 命令都在测试文档里；共用的 [environment.sh](scripts/environment.sh) 只配置临时缓存、隔离 Git 全局配置和启用 shell 错误检查。

要调查工具升级后的差异，可生成旁边的 `.md.new` 文件，不覆盖已有预期：

```bash
scrut update --assume-yes tests
```

审阅差异后再修改测试；CI 永远只运行 `test`。
