---
defaults:
  output_stream: combined
---

# mooncake：只有 child 是 Git 仓库

本文件只在 `parent/child/` 初始化 Git。`parent/` 在仓库外，workspace 配置和父 ignore 仍放在 `parent/`。这样可以直接观察子包的 Git 边界是否阻止 workspace 父规则的继承。

父、子目录分别命名为 `parent`、`child`，包名也用这两个名称作后缀。`parent/child/child/inside.txt` 中最内层的 `child/` **只是普通数据目录，没有 manifest**，用于区分父规则 `/child` 究竟匹配哪里。

```text
parent/                   # 父包，在 Git 仓库外
├── moon.mod
├── secret.txt
└── child/                # 独立子包
    ├── moon.mod
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
