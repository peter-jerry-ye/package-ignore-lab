---
defaults:
  output_stream: combined
---

# Git 本身的对照

使用 `git check-ignore --no-index` 验证规则，不混入“文件是否已经被 Git 跟踪”的另一个因素。输出保留匹配规则的来源和行号。

## 隔离环境 / Isolated environment

```scrut {fail_fast: true}
$ source "$TESTDIR/../scripts/environment.sh"
```

## 创建祖先与子目录

```scrut
$ mkdir -p repo/editor/editor
> cd repo
> git init -q
> printf 'fixture\n' | tee editor/public.txt editor/secret.txt editor/editor/inside.txt >/dev/null
> printf '/editor\n' > .gitignore
```

## 父 /editor 排除子目录里的文件

```scrut
$ git check-ignore --no-index -v editor/public.txt
.gitignore:1:/editor\teditor/public.txt (escaped)
```

## 子规则 !** 不能穿过已排除的祖先

```scrut
$ printf '!**\n' > editor/.gitignore
> git check-ignore --no-index -v editor/public.txt
.gitignore:1:/editor\teditor/public.txt (escaped)
```

## 父级重新允许目录，保留独立文件过滤

```scrut
$ rm editor/.gitignore
> printf '/editor/\n!/editor/\nsecret.txt\n' > .gitignore
> git check-ignore --no-index -v editor/secret.txt
.gitignore:3:secret.txt\teditor/secret.txt (escaped)
```

## 父 /secret.txt 不匹配 editor/secret.txt

```scrut
$ printf '/secret.txt\n' > .gitignore
> git check-ignore --no-index -v editor/secret.txt
[1]
```

## 父 /editor/editor 的锚点

```scrut
$ printf '/editor/editor\n' > .gitignore
> git check-ignore --no-index -v editor/editor/inside.txt
.gitignore:1:/editor/editor\teditor/editor/inside.txt (escaped)
```
