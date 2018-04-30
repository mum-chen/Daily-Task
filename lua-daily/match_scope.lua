local function discriminate_scope(s)
	local prefix, content, suffix = string.match(s, "^(_*)([^%s]-)(_*)$")
	if #content == 0 then
		return "illegal"
	elseif #prefix == 0 then
		return "public"
	elseif #prefix == 1 then
		return "protected"
	elseif #prefix >= 2 and #suffix >= 2 then
		return "attribute"
	else
		return "private"
	end
end

local function match_scope(scope)
	return function(v)
		return discriminate_scope(v) == scope and v or nil
	end
end

local Cases = {
	[""]                = "illegal",
	["_"]               = "illegal",
	["__"]              = "illegal",
	["____"]            = "illegal",
	["f"]               = "public",
	["f_b"]             = "public",
	["foo"]             = "public",
	["foo_bar"]         = "public",
	["_f"]              = "protected",
	["_f_b"]            = "protected",
	["_foo"]            = "protected",
	["_foo_bar"]        = "protected",
	["__f"]             = "private",
	["__f_b"]           = "private",
	["__f__b"]          = "private",
	["__foo"]           = "private",
	["__foo_bar"]       = "private",
	["__foo__bar"]      = "private",
	["___foo_bar"]      = "private",
	["___foo__bar"]     = "private",
	["__f__"]           = "attribute",
	["__f_b__"]         = "attribute",
	["__f__b__"]        = "attribute",
	["__foo__"]         = "attribute",
	["__foo_bar__"]     = "attribute",
	["__foo__bar__"]    = "attribute",
	["___foo_bar__"]    = "attribute",
	["___foo__bar__"]   = "attribute",
}

local function test_case(case, scope)
	local t = {}
	local k, v
	for k, v in pairs(case) do
		t[k] =  v == scope and k or nil
	end
	return t
end

local scopes = {"public", "protected", "private", "attribute"}

local scope
for _, scope in ipairs(scopes) do
	local f = match_scope(scope)
	local test = test_case(Cases, scope)
	local case
	for case, _ in pairs(Cases) do
		local r1 = f(case)
		local r2 = test[case]
		assert(r1 == r2,
			("error in %s: excpeted %s, got %s"):format(
				scope, tostring(r2), tostring(r1)))
	end
	print(("------ %s success -----"):format(scope))
end
