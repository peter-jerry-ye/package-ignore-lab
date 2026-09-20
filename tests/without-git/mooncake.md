---
defaults:
  output_stream: combined
---

# mooncake：无 Git 仓库

本文件从独立临时目录开始，全程不执行 `git init`，并断言 Git 找不到仓库。

父、子目录分别命名为 `parent`、`child`，包名也用这两个名称作后缀。`parent/child/child/inside.txt` 中最内层的 `child/` **只是普通数据目录，没有 manifest**，用于区分父规则 `/child` 究竟匹配哪里。

```text
parent/                   # 父包，没有 Git 仓库
├── moon.mod
├── secret.txt
└── child/                # 独立子包
    ├── moon.mod
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
$ mkdir -p parent/child/child
> cd parent
```

## 写入父包配置

```scrut
$ cat > moon.mod <<'EOF'
> name = "ignore_lab/parent"
> version = "0.1.0"
> license = "MIT"
> readme = "README.md"
> repository = "https://github.com/peter-jerry-ye/package-ignore-lab"
> EOF
```

## 写入子包配置

```scrut
$ cat > child/moon.mod <<'EOF'
> name = "ignore_lab/child"
> version = "0.1.0"
> license = "MIT"
> readme = "README.md"
> repository = "https://github.com/peter-jerry-ye/package-ignore-lab"
> EOF
```

## 声明 workspace

```scrut
$ printf 'members = ["./", "./child"]\n' > moon.work
```

## 写入最小代码和观察用的文件

```scrut
$ : > moon.pkg
> : > child/moon.pkg
> printf 'pub fn value() -> Int { 1 }\n' > main.mbt
> printf 'pub fn value() -> Int { 1 }\n' > child/main.mbt
> printf 'fixture\n' > README.md
> printf 'fixture\n' > child/README.md
> printf 'fake fixture\n' > secret.txt
> printf 'fake fixture\n' > child/secret.txt
> printf 'NOT_A_SECRET=fixture\n' > .env
> printf 'NOT_A_SECRET=fixture\n' > child/.env
> printf 'nested data\n' > child/child/inside.txt
```

下一条 Git 命令必须以状态码 128 失败，表示此目录不在 Git 仓库内；这里只隐藏其依系统语言变化的错误文字。打包命令的 stderr 仍完整检查。

## 确认没有 Git 仓库

```scrut
$ git rev-parse --is-inside-work-tree 2>/dev/null
[128]
```

## 父包默认是否包含 child？

```scrut
$ moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-parent-0.1.0.zip"
[
  "README.md",
  "child/README.md",
  "child/child/inside.txt",
  "child/main.mbt",
  "child/moon.mod",
  "child/moon.pkg",
  "child/secret.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "moon.work",
  "secret.txt"
]
```

## 单独选择子 module

```scrut
$ cd child
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 父 .moonignore /child：父包清单

```scrut
$ cd ..
> printf '/child\n' > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-parent-0.1.0.zip"
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
$ cd child
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 增加空的子 .moonignore，结果会变吗？

```scrut
$ : > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 子 .moonignore 的 !** 会包含哪些文件？

```scrut
$ printf '!**\n' > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  ".env",
  ".moonignore",
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 父 /child/child 是否影响内层目录？

```scrut
$ rm .moonignore
> printf '/child/child\n' > ../.moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
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
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
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
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 父规则加空的子 .moonignore：文件仍在吗？

```scrut
$ : > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 子规则 !secret.txt 对结果有何影响？

```scrut
$ printf '!secret.txt\n' > .moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 父规则同时排除并重新包含目录：子包会继承吗？

```scrut
$ rm .moonignore
> printf '/child/\n!/child/\nsecret.txt\n' > ../.moonignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 改用父 .gitignore /child

```scrut
$ printf '/child\n' > ../.moonignore
> mv ../.moonignore ../.gitignore
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```

## 移除 moon.work 后结果会变吗？

```scrut
$ rm ../moon.work
> moon --quiet --target-dir "$LAB_TMP/artifacts" package
> python3 -c 'import json,sys,zipfile; print(json.dumps(sorted(zipfile.ZipFile(sys.argv[1]).namelist()), indent=2))' "$LAB_TMP/artifacts/publish/ignore_lab-child-0.1.0.zip"
[
  "README.md",
  "child/inside.txt",
  "main.mbt",
  "moon.mod",
  "moon.pkg",
  "secret.txt"
]
```
