---
defaults:
  output_stream: combined
---

# dart：有 Git 仓库

本文件从独立临时目录开始，在 `parent/` 执行 `git init`，整个文档始终有这个 Git 仓库。

父、子目录分别命名为 `parent`、`child`，包名也用这两个名称作后缀。`parent/child/child/inside.txt` 中最内层的 `child/` **只是普通数据目录，没有 manifest**，用于区分父规则 `/child` 究竟匹配哪里。

```text
parent/                   # 父包，也是 Git 根
├── pubspec.yaml
├── secret.txt
└── child/                # 独立子包
    ├── pubspec.yaml
    ├── secret.txt
    └── child/inside.txt  # 普通文件，检验规则锚点
```

第一次读 Scrut 可先看[语法示例](../syntax.md)。每个小节接着上一个小节的状态执行，输出不筛选文件。

## 隔离环境

```scrut {fail_fast: true}
$ source "$TESTDIR/../../scripts/environment.sh"
```

## 创建目录，进入父包

```scrut
$ mkdir -p parent/lib parent/child/lib parent/child/child
> cd parent
```

下面两份 `pubspec.yaml` 声明两个独立 package。父包的 `workspace` 列出子包；子包用 `resolution: workspace` 加入。YAML 的 `sdk` 和 `- child` 前各保留两个空格。

## 写入父包配置

```scrut
$ cat > pubspec.yaml <<'EOF'
> name: ignore_lab_parent
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> workspace:
>   - child
> EOF
```

## 写入子包配置

```scrut
$ cat > child/pubspec.yaml <<'EOF'
> name: ignore_lab_child
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> resolution: workspace
> EOF
```

## 写入最小代码和观察用的文件

```scrut
$ printf 'int value() => 1;\n' > lib/parent.dart
> printf 'int value() => 1;\n' > child/lib/child.dart
> printf 'fake fixture\n' > secret.txt
> printf 'fake fixture\n' > child/secret.txt
> printf 'NOT_A_SECRET=fixture\n' > .env
> printf 'NOT_A_SECRET=fixture\n' > child/.env
> printf 'nested data\n' > child/child/inside.txt
```

## 建立并确认 Git 仓库

```scrut
$ git init -q
> git rev-parse --is-inside-work-tree
true
```

## 父包默认是否包含带 pubspec.yaml 的子包？

```scrut
$ dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_parent 1.0.0 to https://pub.dev:
├── child
│   ├── child
│   │   └── inside.txt (<1 KB)
│   ├── lib
│   │   └── child.dart (<1 KB)
│   ├── pubspec.yaml (<1 KB)
│   └── secret.txt (<1 KB)
├── lib
│   └── parent.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 单独选择子包

```scrut
$ cd child
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:
├── child
│   └── inside.txt (<1 KB)
├── lib
│   └── child.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 父 .pubignore 的 /child：父包清单

```scrut
$ cd ..
> printf '/child\n' > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_parent 1.0.0 to https://pub.dev:
├── lib
│   └── parent.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 同一规则：子包清单

```scrut
$ cd child
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 增加空的子 .pubignore，结果会变吗？

```scrut
$ : > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 子 .pubignore 的 !** 能救回吗？

```scrut
$ printf '!**\n' > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 父 /child/child 是否影响内层目录？

```scrut
$ rm .pubignore
> printf '/child/child\n' > ../.pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:
├── lib
│   └── child.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 父 /secret.txt 是否影响子包同名文件？

```scrut
$ printf '/secret.txt\n' > ../.pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:
├── child
│   └── inside.txt (<1 KB)
├── lib
│   └── child.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 父 basename secret.txt 是否继承？

```scrut
$ printf 'secret.txt\n' > ../.pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:
├── child
│   └── inside.txt (<1 KB)
├── lib
│   └── child.dart (<1 KB)
└── pubspec.yaml (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 空的子 .pubignore 会停止父规则继承吗？

```scrut
$ : > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:
├── child
│   └── inside.txt (<1 KB)
├── lib
│   └── child.dart (<1 KB)
└── pubspec.yaml (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 子规则 !secret.txt 是否能覆盖父文件规则？

```scrut
$ printf '!secret.txt\n' > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:
├── child
│   └── inside.txt (<1 KB)
├── lib
│   └── child.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 改用父 .gitignore /child

```scrut
$ rm .pubignore
> printf '/child\n' > ../.pubignore
> mv ../.pubignore ../.gitignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 移除 workspace 声明后是否仍被祖先忽略？

```scrut
$ cat > ../pubspec.yaml <<'EOF'
> name: ignore_lab_parent
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> EOF
> cat > pubspec.yaml <<'EOF'
> name: ignore_lab_child
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> EOF
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_child 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 把 child 用作示例并设置 publish_to: none，还会随父包出现吗？

```scrut
$ cd ..
> rm .gitignore
> cat > child/pubspec.yaml <<'EOF'
> name: ignore_lab_child
> publish_to: none
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> dependencies:
>   ignore_lab_parent:
>     path: ../
> EOF
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_parent 1.0.0 to https://pub.dev:
├── child
│   ├── child
│   │   └── inside.txt (<1 KB)
│   ├── lib
│   │   └── child.dart (<1 KB)
│   ├── pubspec.yaml (<1 KB)
│   └── secret.txt (<1 KB)
├── lib
│   └── parent.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```
