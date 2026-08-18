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










### Backend.refresh
---
```lua
function Backend.refresh()-> nil
```










### Backend.is_available
---
```lua
function Backend.is_available()-> boolean
```










### Backend.on_change
---
```lua
function Backend.on_change(calback: fun())-> nil
```













## fields
---

### Backend.name
---
```lua
Backend.name : mybatis.completion.Provider
```










### Backend.get_completion_items_sync
---
```lua
Backend.get_completion_items_sync : (fun(partial: string, ctx: mybatis.completion.Context) -> lsp.CompletionItem[])?
```
