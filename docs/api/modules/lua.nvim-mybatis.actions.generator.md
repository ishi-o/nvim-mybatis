# global lua.nvim-mybatis.actions.generator








---

## methods
---

### M.get_crud_args
---
```lua
function M.get_crud_args(bufnr: integer) ->  mybatis.action.CrudTagArgs?
```
@param `bufnr` - Java source file buffer number






Get the arguments used to generate a CRUD tag at the current cursor.








### M.generate_tag
---
```lua
function M.generate_tag(
  range: lsp.Range,
  context: lsp.CodeActionContext,
  bufnr: integer
) ->  lsp.CodeAction?
```





CodeAction: Generate MyBatis Tag








### M.generate_tag_command
---
```lua
function M.generate_tag_command(bufnr: integer?) -> generated boolean
```
@param `bufnr` - Java source file buffer number


@return `generated` - whether the cursor is on a mapper method





Generate a CRUD tag directly from the current mapper method.








### M.get_code_actions
---
```lua
function M.get_code_actions(
  range: lsp.Range,
  context: lsp.CodeActionContext,
  bufnr: integer
) ->  lsp.CodeAction[]
```





Get All CodeAction











## fields
---

### M.SUPPORT_CMDS
---
```lua
M.SUPPORT_CMDS : table<string,function>
```



All support commands
