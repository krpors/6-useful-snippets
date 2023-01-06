local Object = require("classic")

--[[
    This multimap represents a data structure where a single key can have
    multiple value. For instance: ["key"] = {1, 5, 9, 10}. This multimap
    does not allow double values.
]]
local MultiMap = Object:extend()

function MultiMap:new()
	self.table = {}
end

function MultiMap:add(key, val)
	if self.table[key] == nil then
        -- Initialize a new table for the given key
		self.table[key] = {}
	end

    -- Add a new value to the given key. Using 'true' like this as a set
    -- will successfully disallow duplicate values for the given key.
	self.table[key][val] = true
end

function MultiMap:combinations()
	local list = {}
	for multimapKey, valueList in pairs(self.table) do
		for valueKey, bool in pairs(valueList) do
			table.insert(list, {
				first = multimapKey,
				second = valueKey,
			})
		end
	end

	return list
end

return MultiMap
