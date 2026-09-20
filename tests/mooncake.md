---
defaults:
  output_stream: combined
---

# Mooncake：嵌套 module、workspace 与 ignore

使用真正的 `moon package` 生成 ZIP，再直接读取 ZIP 的全部条目。没有调用发布接口。测试记录当前行为；“默认跳过嵌套 module”是尚未实现的提案。

## 隔离环境 / Isolated environment

```scrut {fail_fast: true}
$ source "$TESTDIR/../scripts/environment.sh"
```

## 创建原始问题中的 root + editor workspace

```scrut
$ mkdir -p repo/editor/editor
> cd repo
> cat > moon.mod <<'EOF'
> name = "ignore_lab/root"
> version = "0.1.0"
> license = "MIT"
> readme = "README.md"
> repository = "https://github.com/peter-jerry-ye/package-ignore-lab"
> EOF
> cat > editor/moon.mod <<'EOF'
> name = "ignore_lab/editor"
> version = "0.1.0"
> license = "MIT"
> readme = "README.md"
> repository = "https://github.com/peter-jerry-ye/package-ignore-lab"
> EOF
> printf 'members = ["./", "./editor"]\n' > moon.work
> : > moon.pkg
> : > editor/moon.pkg
> printf 'pub fn value() -> Int { 1 }\n' | tee main.mbt editor/main.mbt >/dev/null
> printf 'fixture\n' | tee README.md editor/README.md >/dev/null
> printf 'fake fixture\n' | tee secret.txt editor/secret.txt >/dev/null
> printf 'NOT_A_SECRET=fixture\n' | tee .env editor/.env >/dev/null
> printf 'nested data\n' > editor/editor/inside.txt
> git init -q
```

## 父包默认是否包含 editor？

```scrut
$ moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-root-0.1.0.zip"
[
  "README.md",
  "editor/README.md",
  "editor/editor/inside.txt",
  "editor/main.mbt",
  "editor/moon.mod",
  "editor/moon.pkg",
  "editor/secret.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "moon.work",
  "secret.txt"
]
```

## 单独选择子 module

```scrut
$ cd editor
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "editor/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 父 .moonignore /editor：父包清单

```scrut
$ cd ..
> printf '/editor\n' > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-root-0.1.0.zip"
[
  "README.md",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "moon.work",
  "secret.txt"
]
```

## 同一规则：子包是否为空？

```scrut
$ cd editor
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[]
```

## 空的子 .moonignore 能救回吗？

```scrut
$ : > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[]
```

## 子 .moonignore !** 能救回吗？

```scrut
$ printf '!**\n' > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[]
```

## 父 /editor/editor 只排除内层目录

```scrut
$ rm .moonignore
> printf '/editor/editor\n' > ../.moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 父 /secret.txt 是否影响子包同名文件？

```scrut
$ printf '/secret.txt\n' > ../.moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "editor/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 父 basename secret.txt 是否继承？

```scrut
$ printf 'secret.txt\n' > ../.moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "editor/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg"
]
```

## 空的子 .moonignore 是否停止父规则继承？

```scrut
$ : > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "editor/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg"
]
```

## 子 !secret.txt 覆盖父文件规则

```scrut
$ printf '!secret.txt\n' > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "editor/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 重新包含目录后，独立文件排除是否仍有效？

```scrut
$ rm .moonignore
> printf '/editor/\n!/editor/\nsecret.txt\n' > ../.moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "editor/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg"
]
```

## 改用父 .gitignore /editor

```scrut
$ printf '/editor\n' > ../.moonignore
> mv ../.moonignore ../.gitignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[]
```

## 移除 moon.work 是否仍复现？

```scrut
$ rm ../moon.work
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[]
```

## 没有 Git 仓库时，父规则是否仍然继承？

```scrut
$ mv ../.git "$LAB_TMP/git-backup"
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-editor-0.1.0.zip"
[
  "README.md",
  "editor/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```
