local args = { ... }

if #args < 1 then
	return error(("Usage: %s <project root> [output file]"):format(fs.getName(shell.getRunningProgram())))
end

local root = shell.resolve(args[1])
local outFile = shell.resolve(args[2] or "bundle.lua")

if not fs.isDir(root) then
	return error("Project root must be a directory")
end

-- recursively collect input files
local function collectSources(dir)
	local sources = {}

	for i, path in ipairs(fs.list(dir)) do
		local absPath = fs.combine(dir, path)

		if fs.isDir(absPath) then
			for k, v in pairs(collectSources(absPath)) do
				sources[fs.combine(path, k)] = v
			end
		else
			local f = fs.open(absPath, "r")
			sources[path] = f.readAll()
			f.close()
		end
	end

	return sources
end

local sources = collectSources(root)
if not sources["main.lua"] then printError("Warning: main.lua missing") end

local output = [[
-- bundle created using crunch
-- https://github.com/apemanzilla/crunch

]]

-- input contents
output = output .. "local sources = {\n"

for k, v in pairs(sources) do
	output = output .. ([[	[%q] = %q,
]]):format(k, v)
end

output = output .. "}\n\n"

-- module loader
output = output .. [[
assert(package, "package API is required")
table.insert(package.loaders, 1, function(name)
	for path in package.path:gmatch("[^;]+") do
		local p = name:gsub("%.", "/")
		local test = path:gsub("%?", p)
		if sources[test] then
			return function(...)
				return load(sources[test], name, nil, _ENV)(...)
			end
		end
	end

	return nil, "no matching embedded file"
end)

]]

-- launcher
output = output .. [[
load(sources["main.lua"] or "", "main.lua", nil, _ENV)(...)
]]

-- write output
local f = fs.open(outFile, "w")
f.write(output)
f.close()

print("Output successfully written to " .. outFile)
