---
defaults:
  output_stream: combined
---

# Dart：workspace 能否包含根目录之外的包？

这里的 `parent` 和 `child` 是兄弟目录，`child` **不在 `parent/` 内**。

```text
./
├── parent/pubspec.yaml  # workspace: ["../child"]
└── child/pubspec.yaml   # resolution: workspace
```

与正常的嵌套 workspace 相比，唯一要验证的路径条件是 `../child` 是否被允许。本测试预期 pub 在读取配置时明确拒绝它。

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
$ cat > pubspec.yaml <<'EOF'
> name: parent
> publish_to: none
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> workspace:
>   - ../child
> EOF
```

## 写入外部包配置

```scrut
$ cat > ../child/pubspec.yaml <<'EOF'
> name: child
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> resolution: workspace
> EOF
```

## 尝试离线解析 workspace

`--offline` 防止访问包注册表。保留完整错误输出以及退出码 65；失败必须来自成员目录限制。

```scrut
$ dart --suppress-analytics pub get --offline
Error on line 6, column 5 of pubspec.yaml: "workspace" members must be subdirectories
  ╷
6 │   - ../child
  │     ^^^^^^^^
  ╵
[65]
```

来源：[官方子目录限制诊断](https://dart.dev/tools/diagnostics/workspace_value_not_subdirectory)、[pub 的实际校验](https://github.com/dart-lang/pub/blob/master/lib/src/pubspec.dart#L79-L89)。
