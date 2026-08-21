# class Backend



- namespace: mybatis.completion









---

## methods
---

### Backend.get_completion_items
---
```lua
function Backend.get_completion_items(
  partial: string,
  ctx: mybatis.completion.Context {
    kind = mybatis.completion.ContextKind,
    bufnr = integer?,
    value_node = TSNode?,
    namespace = string?,
    type = string?,
},
  callback: fun(items: lsp.CompletionItem[])
)-> nil
```










### Backend.is_available
---
```lua
function Backend.is_available()-> boolean
```













## fields
---

### Backend.get_completion_items_sync
---
```lua
Backend.get_completion_items_sync : (fun(partial: string, ctx: mybatis.completion.Context) -> lsp.CompletionItem[])?
```
