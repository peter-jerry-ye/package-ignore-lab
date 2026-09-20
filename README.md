# Package ignore lab

[![验证行为](https://github.com/peter-jerry-ye/package-ignore-lab/actions/workflows/verify.yml/badge.svg)](https://github.com/peter-jerry-ye/package-ignore-lab/actions/workflows/verify.yml)

用可执行的 Markdown 验证嵌套包、workspace 和 ignore 的关系。直接读结论表和测试文档即可，无需翻 CI 日志。

## 先看懂测试怎么写

[最小 Scrut 示例](tests/syntax.md)会创建一个文件、写入 YAML，再读回来核对内容。它也由 CI 执行。

- `$ ` 是一段 shell 命令的第一行，`> ` 是同一段命令的续行；Scrut 会移除这些前缀。
- 去掉前缀后，`cat > 文件 <<'EOF'` 是普通 Bash heredoc，`EOF` 之间的文字原样写入文件。
- 没有这些前缀的行是预期输出，`[128]` 等独立行是预期退出码。

因此“创建目录、写 parent 配置、写 child 配置、写测试文件”都是准备步骤；真正执行打包的步骤在它们之后。各步骤已拆成小节。YAML 缩进必须保留，结束标记 `EOF` 须顶格，整个 Scrut 测试放在 fenced code block 中，不能改成 Markdown 引用段落。

## 分开看两个条件

**是否有 Git 仓库**和**是否声明 workspace**是两项独立条件。每个包管理器有两份独立测试：

| 工具 | 始终有 Git 仓库 | 始终没有 Git 仓库 |
| --- | --- | --- |
| Mooncake | [with-git/mooncake.md](tests/with-git/mooncake.md) | [without-git/mooncake.md](tests/without-git/mooncake.md) |
| Dart pub | [with-git/dart.md](tests/with-git/dart.md) | [without-git/dart.md](tests/without-git/dart.md) |
| npm | [with-git/npm.md](tests/with-git/npm.md) | [without-git/npm.md](tests/without-git/npm.md) |
| pnpm | [with-git/pnpm.md](tests/with-git/pnpm.md) | [without-git/pnpm.md](tests/without-git/pnpm.md) |

有 Git 的测试在 `parent/` 执行 `git init`，并断言 `git rev-parse --is-inside-work-tree` 输出 `true`。无 Git 的测试从全新临时目录开始，全程不执行 `git init`，并断言同一条查询命令以状态码 128 失败。测试不会中途移走 `.git` 来切换场景。

目录统一为：

```text
parent/                      # 父包；有 Git 时也是 Git 根
├── <父包 manifest>
├── <workspace 配置>
├── <ignore 文件>
├── secret.txt
└── child/                   # 独立子包
    ├── <子包 manifest>
    ├── secret.txt
    ├── <最小代码>
    └── child/
        └── inside.txt       # 普通文件，不是第三个包
```

最内层 `child/` 没有 manifest，只用于观察父规则 `/child` 的锚点：它排除的是 `parent/child/`，还是打包子包时被重新解释为 `parent/child/child/`？

## 已验证的结果

下面每行都**已声明 workspace，在 `parent/child/` 打包子包，ignore 规则写在 `parent/`**。专用 ignore 文件分别为 `.moonignore`、`.pubignore`、`.npmignore`、`.npmignore`。

| 父规则 | Git 仓库 | Mooncake | Dart pub | npm | pnpm |
| --- | --- | --- | --- | --- | --- |
| `/child` | 有 | **空 ZIP** | **空文件清单** | 有内容，排除内部 `child/` | 有内容，排除内部 `child/` |
| `/child` | 无 | 有内容，保留内部 `child/` | 有内容，保留内部 `child/` | 有内容，排除内部 `child/` | 有内容，排除内部 `child/` |
| `secret.txt` | 有 | 排除子包同名文件 | 排除子包同名文件 | 排除子包同名文件 | 排除子包同名文件 |
| `secret.txt` | 无 | **保留**子包同名文件 | **保留**子包同名文件 | 排除子包同名文件 | 排除子包同名文件 |
| `/secret.txt` | 有 | 保留子包同名文件 | 保留子包同名文件 | 排除子包同名文件 | 排除子包同名文件 |
| `/secret.txt` | 无 | 保留子包同名文件 | 保留子包同名文件 | 排除子包同名文件 | 排除子包同名文件 |

另外，每份测试都检查：

- 没有 ignore 时，打包 parent 会包含 child；父 ignore 写 `/child` 后，打包 parent 会排除 child。这在有无 Git 时都成立。
- npm/pnpm 从“未声明 workspace”开始：普通嵌套子包不继承父 ignore；声明 workspace 后才发生继承。有无 Git 分别验证。
- Mooncake/Dart 还会移除 workspace 声明：有 Git 时仍继承祖先规则，无 Git 时不继承。**workspace 本身不等于 Git 仓库。**
- 空的子 ignore、否定规则、`.gitignore` 回退等细节，直接看对应文件的完整输出。

额外的 [Git 自身对照](tests/git.md)用 `git check-ignore --no-index -v` 展示命中的规则、来源和行号。

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
scrut test tests/with-git/dart.md
scrut test tests/without-git/dart.md
```

Scrut 就是负责执行和比较 Markdown 的工具，无需额外的 fixture DSL。创建目录和文件的 shell 命令都在测试文档里；共用的 [environment.sh](scripts/environment.sh) 只配置临时缓存、隔离 Git 全局配置和启用 shell 错误检查。

要调查工具升级后的差异，可生成旁边的 `.md.new` 文件，不覆盖已有预期：

```bash
scrut update --assume-yes tests
```

审阅差异后再修改测试；CI 永远只运行 `test`。
