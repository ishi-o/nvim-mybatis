# alias ContextKind
---

- namespace: mybatis.completion



```lua
(alias) ContextKind = ("class"|"method"|"field"|"refid")
    | "class" -- completion of fully-qualified java class names
    | "method" -- completion of mapper interface method names
    | "field" -- completion of entity field names
    | "refid" -- completion of `<sql id>` fragment ids

```
