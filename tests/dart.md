---
defaults:
  output_stream: combined
---

# Dart pub：嵌套 package、workspace 与 ignore

这里运行 `publish --dry-run --skip-validation`，验证文件选择；没有上传，也没有证明发布验证会接受空包。保留 CLI 的完整输出；这里的所有文件均小于 1 KB，无需过滤或归一化。

## 隔离环境 / Isolated environment

```scrut {fail_fast: true}
$ source "$TESTDIR/../scripts/environment.sh"
```

## 创建包含 editor 的 workspace

```scrut
$ mkdir -p repo/lib repo/editor/lib repo/editor/editor
> cd repo
> cat > pubspec.yaml <<'EOF'
> name: ignore_lab_root
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> workspace:
>   - editor
> EOF
> cat > editor/pubspec.yaml <<'EOF'
> name: ignore_lab_editor
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> resolution: workspace
> EOF
> printf 'int value() => 1;\n' | tee lib/root.dart editor/lib/editor.dart >/dev/null
> printf 'fake fixture\n' | tee secret.txt editor/secret.txt >/dev/null
> printf 'NOT_A_SECRET=fixture\n' | tee .env editor/.env >/dev/null
> printf 'nested data\n' > editor/editor/inside.txt
> git init -q
```

## 父包默认是否包含带 pubspec.yaml 的子包？

```scrut
$ dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_root 1.0.0 to https://pub.dev:
├── editor
│   ├── editor
│   │   └── inside.txt (<1 KB)
│   ├── lib
│   │   └── editor.dart (<1 KB)
│   ├── pubspec.yaml (<1 KB)
│   └── secret.txt (<1 KB)
├── lib
│   └── root.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 单独选择子包

```scrut
$ cd editor
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:
├── editor
│   └── inside.txt (<1 KB)
├── lib
│   └── editor.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 父 .pubignore 的 /editor：父包清单

```scrut
$ cd ..
> printf '/editor\n' > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_root 1.0.0 to https://pub.dev:
├── lib
│   └── root.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 同一规则：子包清单

```scrut
$ cd editor
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 空的子 .pubignore 能救回被忽略的包吗？

```scrut
$ : > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 子 .pubignore 的 !** 能救回吗？

```scrut
$ printf '!**\n' > .pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 父 /editor/editor 只排除内层目录

```scrut
$ rm .pubignore
> printf '/editor/editor\n' > ../.pubignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:
├── lib
│   └── editor.dart (<1 KB)
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
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:
├── editor
│   └── inside.txt (<1 KB)
├── lib
│   └── editor.dart (<1 KB)
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
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:
├── editor
│   └── inside.txt (<1 KB)
├── lib
│   └── editor.dart (<1 KB)
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
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:
├── editor
│   └── inside.txt (<1 KB)
├── lib
│   └── editor.dart (<1 KB)
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
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:
├── editor
│   └── inside.txt (<1 KB)
├── lib
│   └── editor.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 改用父 .gitignore /editor

```scrut
$ rm .pubignore
> printf '/editor\n' > ../.pubignore
> mv ../.pubignore ../.gitignore
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 移除 workspace 声明后是否仍被祖先忽略？

```scrut
$ cat > ../pubspec.yaml <<'EOF'
> name: ignore_lab_root
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> EOF
> cat > pubspec.yaml <<'EOF'
> name: ignore_lab_editor
> version: 1.0.0
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> EOF
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 没有 Git 仓库时，父规则是否仍然继承？

```scrut
$ mv ../.git "$LAB_TMP/git-backup"
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_editor 1.0.0 to https://pub.dev:
├── editor
│   └── inside.txt (<1 KB)
├── lib
│   └── editor.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```

## 嵌套 example 设置 publish_to: none 后会随父包出现吗？

```scrut
$ cd ..
> rm .gitignore
> mv editor example
> cat > example/pubspec.yaml <<'EOF'
> name: ignore_lab_example
> publish_to: none
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> dependencies:
>   ignore_lab_root:
>     path: ../
> EOF
> dart --suppress-analytics pub publish --dry-run --skip-validation 2>&1
Running with `skip-validation`. No client-side validation is done.
Publishing ignore_lab_root 1.0.0 to https://pub.dev:
├── example
│   ├── editor
│   │   └── inside.txt (<1 KB)
│   ├── lib
│   │   └── editor.dart (<1 KB)
│   ├── pubspec.yaml (<1 KB)
│   └── secret.txt (<1 KB)
├── lib
│   └── root.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── secret.txt (<1 KB)

Total compressed archive size: <1 KB.
The server may enforce additional checks.

Package has 0 warnings.
```
