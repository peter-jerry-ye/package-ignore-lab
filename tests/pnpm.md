---
defaults:
  output_stream: combined
---

# pnpm：嵌套包与 ignore

所有清单来自真实 CLI 的完整 `files` 字段，只排序，不筛选文件。每一步接着上一步的文件状态执行。`secret.txt` 和 `.env` 只有虚构的测试文字。

## 隔离环境 / Isolated environment

```scrut {fail_fast: true}
$ source "$TESTDIR/../scripts/environment.sh"
```

## 创建普通嵌套包，尚未声明 workspace

```scrut
$ mkdir -p repo/editor/editor
> cd repo
> cat > package.json <<'EOF'
> {"name":"ignore-lab-root","version":"1.0.0"}
> EOF
> cat > editor/package.json <<'EOF'
> {"name":"ignore-lab-editor","version":"1.0.0"}
> EOF
> printf 'root\n' > root.txt
> printf 'public\n' > editor/public.txt
> printf 'fake fixture\n' | tee secret.txt editor/secret.txt >/dev/null
> printf 'NOT_A_SECRET=fixture\n' | tee .env editor/.env >/dev/null
> printf 'nested data\n' > editor/editor/inside.txt
> git init -q
```

## 默认打包父包是否包含子包？

```scrut
$ pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "editor/.env",
  "editor/editor/inside.txt",
  "editor/package.json",
  "editor/public.txt",
  "editor/secret.txt",
  "package.json",
  "root.txt",
  "secret.txt"
]
```

## 普通嵌套包：父规则 secret.txt 是否继承？

```scrut
$ printf 'secret.txt\n' > .npmignore
> cd editor
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "editor/inside.txt",
  "package.json",
  "public.txt",
  "secret.txt"
]
```

## 声明 workspace 后，同一条父规则是否继承？

```scrut
$ cd ..
> printf 'packages:\n  - editor\n' > pnpm-workspace.yaml
> cd editor
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "editor/inside.txt",
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
  "editor/inside.txt",
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
  "editor/inside.txt",
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
  "editor/inside.txt",
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
  "editor/inside.txt",
  "package.json",
  "public.txt"
]
```

## 父规则 /editor：父包清单

```scrut
$ cd ..
> printf '/editor\n' > .npmignore
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  ".npmignore",
  "package.json",
  "pnpm-workspace.yaml",
  "root.txt",
  "secret.txt"
]
```

## 父规则 /editor：子包会空吗？里面的 editor/ 呢？

```scrut
$ cd editor
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "package.json",
  "public.txt",
  "secret.txt"
]
```

## 改用父 .gitignore 的 /editor，结果相同吗？

```scrut
$ cd ..
> mv .npmignore .gitignore
> cd editor
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
> cat > editor/package.json <<'EOF'
> {"name":"ignore-lab-editor","version":"1.0.0","files":["secret.txt"]}
> EOF
> cd editor
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
> cat > editor/package.json <<'EOF'
> {"name":"ignore-lab-editor","version":"1.0.0"}
> EOF
> pnpm pack --dry-run --json | jq '[.files[].path] | sort'
[
  ".env",
  "editor/.env",
  "editor/editor/inside.txt",
  "editor/package.json",
  "editor/public.txt",
  "editor/secret.txt",
  "package.json",
  "pnpm-workspace.yaml",
  "root.txt",
  "secret.txt"
]
```

## 显式 -r --include-workspace-root 的结果

```scrut
$ pnpm pack -r --include-workspace-root --dry-run --json | jq 'map({name, files: ([.files[].path] | sort)}) | sort_by(.name)'
[
  {
    "name": "ignore-lab-editor",
    "files": [
      ".env",
      "editor/inside.txt",
      "package.json",
      "public.txt",
      "secret.txt"
    ]
  },
  {
    "name": "ignore-lab-root",
    "files": [
      ".env",
      "editor/.env",
      "editor/editor/inside.txt",
      "editor/package.json",
      "editor/public.txt",
      "editor/secret.txt",
      "package.json",
      "pnpm-workspace.yaml",
      "root.txt",
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
  "editor/.env",
  "editor/editor/inside.txt",
  "editor/package.json",
  "editor/public.txt",
  "editor/secret.txt",
  "package.json",
  "pnpm-workspace.yaml",
  "root.txt",
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
> tar -tzf "$LAB_TMP/artifacts/ignore-lab-root-1.0.0.tgz" | LC_ALL=C sort
package/.env
package/editor/.env
package/editor/editor/inside.txt
package/editor/package.json
package/editor/public.txt
package/editor/secret.txt
package/package.json
package/pnpm-workspace.yaml
package/root.txt
package/secret.txt
```
