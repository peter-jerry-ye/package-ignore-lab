---
defaults:
  output_stream: combined
---

# dart：只有 child 是 Git 仓库

本文件只在 `parent/child/` 初始化 Git。`parent/` 在仓库外，workspace 配置和父 ignore 仍放在 `parent/`。这样可以直接观察子包的 Git 边界是否阻止 workspace 父规则的继承。

父、子目录分别命名为 `parent`、`child`，包名也用这两个名称作后缀。`parent/child/child/inside.txt` 中最内层的 `child/` **只是普通数据目录，没有 manifest**，用于区分父规则 `/child` 究竟匹配哪里。

```text
parent/                   # 父包，在 Git 仓库外
├── pubspec.yaml
├── secret.txt
└── child/                # 独立子包
    ├── pubspec.yaml
    ├── .git/             # 只有子包是 Git 仓库
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

## 只在 child 初始化 Git

```scrut
$ git init -q child
> test -d child/.git
```

## 确认 parent 不在 Git 仓库内

仅这条预期失败的查询隐藏 Git 的错误文字，打包命令的输出完整保留。

```scrut
$ git rev-parse --is-inside-work-tree 2>/dev/null
[128]
```

## 确认 child 在自己的 Git 仓库内

```scrut
$ git -C child rev-parse --is-inside-work-tree
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
$ printf '/child\n' > ../.pubignore
> mv ../.pubignore ../.gitignore
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

## 移除 workspace 声明后结果会变吗？

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
