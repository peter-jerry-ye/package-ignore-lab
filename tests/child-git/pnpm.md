---
defaults:
  output_stream: combined
---

# pnpm：只有 child 是 Git 仓库

本文件只在 `parent/child/` 初始化 Git。`parent/` 在仓库外，workspace 配置和父 ignore 仍放在 `parent/`。这样可以直接观察子包的 Git 边界是否阻止 workspace 父规则的继承。

父、子目录分别命名为 `parent`、`child`，包名也用这两个名称作后缀。`parent/child/child/inside.txt` 中最内层的 `child/` **只是普通数据目录，没有 manifest**，用于区分父规则 `/child` 究竟匹配哪里。

```text
parent/                   # 父包，在 Git 仓库外
├── package.json
├── secret.txt
└── child/                # 独立子包
    ├── package.json
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

先创建两个独立包，暂不声明 workspace。后面单独添加 workspace 配置，比较同一条规则前后的结果。

## 写入父包配置

```scrut
$ cat > package.json <<'EOF'
> {"name":"ignore-lab-parent","version":"1.0.0"}
> EOF
```

## 写入子包配置

```scrut
$ cat > child/package.json <<'EOF'
> {"name":"ignore-lab-child","version":"1.0.0"}
> EOF
```

## 写入最小代码和观察用的文件

```scrut
$ printf 'parent\n' > parent.txt
> printf 'public\n' > child/public.txt
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

## 默认打包父包是否包含子包？

```scrut
$ pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "child/.env",
  "child/child/inside.txt",
  "child/package.json",
  "child/public.txt",
  "child/secret.txt",
  "package.json",
  "parent.txt",
  "secret.txt"
]
```

## 普通嵌套包：父规则 secret.txt 是否继承？

```scrut
$ printf 'secret.txt\n' > .npmignore
> cd child
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "child/inside.txt",
  "package.json",
  "public.txt",
  "secret.txt"
]
```

## 声明 workspace 后，同一条父规则是否继承？

```scrut
$ cd ..
> printf 'packages:\n  - child\n' > pnpm-workspace.yaml
> cd child
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "child/inside.txt",
  "package.json",
  "public.txt"
]
```

## 父规则 /secret.txt 的锚点在哪里？

```scrut
$ printf '/secret.txt\n' > ../.npmignore
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "child/inside.txt",
  "package.json",
  "public.txt"
]
```

## 父规则 /child：父包清单

```scrut
$ cd ..
> printf '/child\n' > .npmignore
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  ".npmignore",
  "package.json",
  "parent.txt",
  "pnpm-workspace.yaml",
  "secret.txt"
]
```

## 父规则 /child：子包会空吗？里面的 child/ 呢？

```scrut
$ cd child
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "package.json",
  "public.txt",
  "secret.txt"
]
```

## 改用父 .gitignore 的 /child，结果相同吗？

```scrut
$ cd ..
> mv .npmignore .gitignore
> cd child
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "package.json",
  "public.txt",
  "secret.txt"
]
```
