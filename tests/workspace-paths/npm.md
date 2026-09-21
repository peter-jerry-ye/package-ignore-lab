---
defaults:
  output_stream: combined
---

# npm：workspace 能否包含根目录之外的包？

这里故意让 `parent` 和 `child` 成为兄弟目录。名称沿用其它测试，但 `child` **不在 `parent/` 内**。

```text
./
├── parent/package.json  # workspaces: ["../child"]
└── child/package.json
```

本测试只确认从 `parent` 显式枚举 workspace 成员，不测试打包，也不假定在 `child` 中执行命令会自动找到兄弟目录里的 workspace。

## 隔离环境

```scrut {fail_fast: true}
$ source "$TESTDIR/../../scripts/environment.sh"
```

## 创建兄弟目录，进入 workspace 根目录

```scrut
$ mkdir parent child
> cd parent
```

## 父配置列出外部成员

```scrut
$ cat > package.json <<'EOF'
> {"name":"parent","private":true,"workspaces":["../child"]}
> EOF
```

## 写入外部包配置

```scrut
$ cat > ../child/package.json <<'EOF'
> {"name":"child","version":"1.0.0"}
> EOF
```

## 从 workspace 根目录枚举成员

用 `--json` 显式选择 JSON，保留完整输出；不安装依赖，也不访问包注册表。

```scrut
$ npm pkg get name --workspaces --json
{
  "child": "child"
}
```

来源：[npm workspace 声明](https://docs.npmjs.com/cli/v11/configuring-npm/package-json/#workspaces)、[官方成员路径解析实现](https://github.com/npm/map-workspaces/blob/v5.0.3/lib/index.js)。文档通常使用子目录示例；这里通过命令确认 `../child` 也被识别。
