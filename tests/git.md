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
$ mkdir -p parent/child/child
> cd parent
> git init -q
> printf 'fixture\n' | tee child/public.txt child/secret.txt child/child/inside.txt >/dev/null
> printf '/child\n' > .gitignore
```

## 父 /child 排除子目录里的文件

```scrut
$ git check-ignore --no-index -v child/public.txt
.gitignore:1:/child\tchild/public.txt (escaped)
```

## 子规则 !** 不能穿过已排除的祖先

```scrut
$ printf '!**\n' > child/.gitignore
> git check-ignore --no-index -v child/public.txt
.gitignore:1:/child\tchild/public.txt (escaped)
```

## 父级重新允许目录，保留独立文件过滤

```scrut
$ rm child/.gitignore
> printf '/child/\n!/child/\nsecret.txt\n' > .gitignore
> git check-ignore --no-index -v child/secret.txt
.gitignore:3:secret.txt\tchild/secret.txt (escaped)
```

## 父 /secret.txt 不匹配 child/secret.txt

```scrut
$ printf '/secret.txt\n' > .gitignore
> git check-ignore --no-index -v child/secret.txt
[1]
```

## 父 /child/child 的锚点

```scrut
$ printf '/child/child\n' > .gitignore
> git check-ignore --no-index -v child/child/inside.txt
.gitignore:1:/child/child\tchild/child/inside.txt (escaped)
```
