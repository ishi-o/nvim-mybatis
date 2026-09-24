--- @module 'mybatis.constants'

local MYBATIS_FILETYPE = "mybatis.xml"

local MYBATIS_LANGUAGE = "mybatis"

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
	MYBATIS_FILETYPE = MYBATIS_FILETYPE,
	MYBATIS_LANGUAGE = MYBATIS_LANGUAGE,
	TYPE_ATTRIBUTES = TYPE_ATTRIBUTES,
	CRUD_TAGS = CRUD_TAGS,
}
