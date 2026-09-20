---
defaults:
  output_stream: combined
---

# 如何读 Scrut：先写一个文件，再读回来

Scrut 测试必须放在 Markdown 的 `scrut` fenced code block 里。代码块中的前缀含义是：

- `$ `：这一段 shell 命令的第一行。
- `> `：同一段命令的后续行。Scrut 去掉这个前缀后，把剩余内容交给 Bash。
- 没有前缀的行：预期输出，不是待执行命令。
- `[128]` 等独立行：预期的非零退出码。没有这一行时要求成功退出。

`>` 是 Scrut 的续行标记，并不是把所有后续行写进文件。真正的文件写入由 shell 的 `cat > 文件 <<'EOF'` 完成。**去掉 Scrut 前缀后，YAML 缩进必须保留，结束标记 `EOF` 必须顶格。**

本文件也是 CI 会执行的测试，不只是语法示意。

## 创建目录

```scrut
$ mkdir parent
```

## 把 heredoc 内容写入 parent/pubspec.yaml

这里 `EOF` 之间的 3 行就是文件内容；`'EOF'` 的引号表示不要展开其中的 shell 变量。该命令没有 stdout，所以代码块中没有预期输出。

```scrut
$ cat > parent/pubspec.yaml <<'EOF'
> name: parent
> environment:
>   sdk: '>=3.6.0 <4.0.0'
> EOF
```

上面的 Scrut 代码实际执行的是下面这段 Bash。`bash` 代码块只用于说明，不会被 Scrut 当成测试：

```bash
cat > parent/pubspec.yaml <<'EOF'
name: parent
environment:
  sdk: '>=3.6.0 <4.0.0'
EOF
```

## 读回文件，核对原样保留的内容和缩进

```scrut
$ cat parent/pubspec.yaml
name: parent
environment:
  sdk: '>=3.6.0 <4.0.0'
```

包管理器测试接下来做的就是同样的事：分别写 parent、child 的 manifest，再创建观察用的文件，最后执行打包并比较输出。文件内容中的 `_` 不需要写成 `\_`，续行中的 `>` 也不要改成 Markdown 引用段落。

参考：[Scrut 官方多行命令测试](https://github.com/facebookincubator/scrut/blob/v0.4.3/selftest/cases/multiline.md)。
