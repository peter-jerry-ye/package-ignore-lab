---
defaults:
  output_stream: combined
---

# pnpm：独立 workspace 文件能否包含外部包？

这里的 `parent` 和 `child` 是兄弟目录，`child` **不在 `parent/` 内**。

```text
./
├── parent/
│   ├── package.json
│   └── pnpm-workspace.yaml  # packages: ["../child"]
└── child/package.json
```

本测试只确认从 workspace 根目录显式枚举成员，不测试打包，也不假定从 `child` 执行命令会自动找到兄弟目录的配置。

## 隔离环境

```scrut {fail_fast: true}
$ source "$TESTDIR/../../scripts/environment.sh"
```

## 创建兄弟目录，进入 workspace 根目录

```scrut
$ mkdir parent child
> cd parent
```

## 写入父包配置

```scrut
$ cat > package.json <<'EOF'
> {"name":"parent","private":true}
> EOF
```

## 在独立文件中声明外部成员

```scrut
$ cat > pnpm-workspace.yaml <<'EOF'
> packages:
>   - ../child
> EOF
```

## 写入外部包配置

```scrut
$ cat > ../child/package.json <<'EOF'
> {"name":"child","version":"1.0.0"}
> EOF
```

## 从 workspace 根目录枚举包

`list` 不安装依赖。JSON 中包含临时目录的绝对路径，所以用 `jq` 只保留每个包的名称并排序，**不筛选任何包**。根包 `parent` 也在结果里。

```scrut
$ pnpm --recursive list --depth -1 --json | jq 'map(.name) | sort'
[
  "child",
  "parent"
]
```

来源：[pnpm 的 workspace 配置与路径模式](https://pnpm.io/settings#packages)。
