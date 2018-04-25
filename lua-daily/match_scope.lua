local function match_scope(scope)
	local pattern = ({
		public = "^[^_][^%s]*$",
		protected = "^_[^_][^%s]*$",
		private = "^__[^%s]*[^_%s]+$",
		attribute = "^__[^%s]+__$",
	})[scope]
	assert(pattern,
		("Not found pattern for %s"):format(tostring(scope)))
	return function(v)
		return string.match(v, pattern)
	end
end

local Cases = {
	"",
	"_",
	"__",
	"____",
	"f",
	"_f",
	"__f",
	"__f__",
	"f_b",
	"_f_b",
	"__f_b",
	"__f__b",
	"__f_b__",
	"__f__b__",
	"foo",
	"_foo",
	"__foo",
	"__foo__",
	"foo_bar",
	"_foo_bar",
	"__foo_bar",
	"__foo_bar__",
	"__foo__bar",
	"__foo__bar__",
	"___foo_bar",
	"___foo__bar",
	"___foo_bar__",
	"___foo__bar__",
}

local function reverse(t)
	local _t = {}
	local v
	for _, v in ipairs(t) do
		_t[v] = v
	end
	return _t
end

local test_case = {}
test_case.public = {
	func = match_scope("public"),
	result = {
		"f",
		"f_b",
		"foo",
		"foo_bar",
	}
}

test_case.protected = {
	func = match_scope("protected"),
	result = {
		"_f",
		"_f_b",
		"_foo",
		"_foo_bar",
	},
}

test_case.private = {
	func = match_scope("private"),
	result = {
		"__f",
		"__f_b",
		"__f__b",
		"__foo",
		"__foo_bar",
		"__foo__bar",
		"___foo_bar",
		"___foo__bar",
	}
}

test_case.attribute = {
	func = match_scope("attribute"),
	result = {
		"__f__",
		"__f_b__",
		"__f__b__",
		"__foo__",
		"__foo_bar__",
		"__foo__bar__",
		"___foo_bar__",
		"___foo__bar__",
	}
}

local k, v
for k, v in pairs(test_case) do
	local f = v.func
	local res = reverse(v.result)
	for _, case in pairs(Cases) do
		local r1 = f(case)
		local r2 = res[case]
		assert(r1 == r2,
			("error in %s: excpeted %s, got %s"):format(
				k, tostring(r2), tostring(r1)))
	end
	print(("------ %s success -----"):format(k))
end
