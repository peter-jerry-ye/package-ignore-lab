---
defaults:
  output_stream: combined
---

# pnpm：无 Git 仓库

本文件从独立临时目录开始，全程不执行 `git init`，并断言 Git 找不到仓库。

父、子目录分别命名为 `parent`、`child`，包名也用这两个名称作后缀。`parent/child/child/inside.txt` 中最内层的 `child/` **只是普通数据目录，没有 manifest**，用于区分父规则 `/child` 究竟匹配哪里。

```text
parent/                   # 父包，没有 Git 仓库
├── package.json
├── secret.txt
└── child/                # 独立子包
    ├── package.json
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

下一条 Git 命令必须以状态码 128 失败，表示此目录不在 Git 仓库内；这里只隐藏其依系统语言变化的错误文字。打包命令的 stderr 仍完整检查。

## 确认没有 Git 仓库

```scrut
$ git rev-parse --is-inside-work-tree 2>/dev/null
[128]
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

## 子包有空 .npmignore 时

```scrut
$ : > .npmignore
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  ".npmignore",
  "child/inside.txt",
  "package.json",
  "public.txt",
  "secret.txt"
]
```

## 子包显式 !secret.txt 时

```scrut
$ printf '!secret.txt\n' > .npmignore
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  ".npmignore",
  "child/inside.txt",
  "package.json",
  "public.txt",
  "secret.txt"
]
```

## 父规则 .env 是否继承？

```scrut
$ rm .npmignore
> printf '.env\n' > ../.npmignore
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  "child/inside.txt",
  "package.json",
  "public.txt",
  "secret.txt"
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

## files allowlist 与父 secret.txt 规则

```scrut
$ cd ..
> rm .gitignore
> printf 'secret.txt\n' > .npmignore
> cat > child/package.json <<'EOF'
> {"name":"ignore-lab-child","version":"1.0.0","files":["secret.txt"]}
> EOF
> cd child
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  "package.json",
  "secret.txt"
]
```

## 恢复无 ignore/allowlist：仅声明 workspace 会排除成员吗？

```scrut
$ cd ..
> rm .npmignore
> cat > child/package.json <<'EOF'
> {"name":"ignore-lab-child","version":"1.0.0"}
> EOF
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "child/.env",
  "child/child/inside.txt",
  "child/package.json",
  "child/public.txt",
  "child/secret.txt",
  "package.json",
  "parent.txt",
  "pnpm-workspace.yaml",
  "secret.txt"
]
```

## 显式 -r --include-workspace-root 的结果

```scrut
$ pnpm pack -r --include-workspace-root --dry-run --json | jq 'map({name, files: ([.files[].path] | sort)}) | sort_by(.name)'
[
  {
    "name": "ignore-lab-child",
    "files": [
      ".env",
      "child/inside.txt",
      "package.json",
      "public.txt",
      "secret.txt"
    ]
  },
  {
    "name": "ignore-lab-parent",
    "files": [
      ".env",
      "child/.env",
      "child/child/inside.txt",
      "child/package.json",
      "child/public.txt",
      "child/secret.txt",
      "package.json",
      "parent.txt",
      "pnpm-workspace.yaml",
      "secret.txt"
    ]
  }
]
```

## .pnpmignore 是有效的排除配置吗？

```scrut
$ printf 'secret.txt\n' > .pnpmignore
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  ".pnpmignore",
  "child/.env",
  "child/child/inside.txt",
  "child/package.json",
  "child/public.txt",
  "child/secret.txt",
  "package.json",
  "parent.txt",
  "pnpm-workspace.yaml",
  "secret.txt"
]
```

## 清理 .pnpmignore

```scrut
$ rm .pnpmignore
```

## 实际生成 tarball，核对它的完整清单

```scrut
$ pnpm pack --json --pack-destination "$LAB_TMP/artifacts" > "$LAB_TMP/pack-result.json"
> tar -tzf "$LAB_TMP/artifacts/ignore-lab-parent-1.0.0.tgz" | LC_ALL=C sort
package/.env
package/child/.env
package/child/child/inside.txt
package/child/package.json
package/child/public.txt
package/child/secret.txt
package/package.json
package/parent.txt
package/pnpm-workspace.yaml
package/secret.txt
```
