--- @module 'mybatis.constants'

--- XML attributes whose values can refer to Java types.
--- @type string[]
local TYPE_ATTRIBUTES = {
	"namespace",
	"resultType",
	"parameterType",
	"type",
	"javaType",
	"ofType",
	"typeHandler",
}

--- XML tags whose `id` attributes refer to mapper methods.
--- @type string[]
local CRUD_TAGS = {
	"select",
	"update",
	"delete",
	"insert",
}

return {
	TYPE_ATTRIBUTES = TYPE_ATTRIBUTES,
	CRUD_TAGS = CRUD_TAGS,
}
