# class Context



- namespace: mybatis.completion









---



## fields
---

### Context.kind
---
```lua
Context.kind : mybatis.completion.ContextKind
```










### Context.bufnr
---
```lua
Context.bufnr : integer?
```



buffer the completion was requested in








### Context.value_node
---
```lua
Context.value_node : TSNode?
```



the AttValue node being completed








### Context.namespace
---
```lua
Context.namespace : string?
```



mapper namespace (`method` context)








### Context.type
---
```lua
Context.type : string?
```



owning entity type (`field` context)
