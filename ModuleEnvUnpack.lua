--[[
	ModuleEnvUnpack.lua
	Version: 1.0
	Released: December 12, 2013
	Updated: N/A

	Author: Zytharian

	Unpacks a table into another table. Specifically for unpacking
	a module into the environment. See usage section below.
	
	Example Usage:
		require("ModuleEnvUnpack.lua") (
			require("SomeOtherLibrary.lua"), _ENV or getfenv(0))
		)
]]

return function (TableToUnpack, Environment)
	for i,v in next, TableToUnpack do
		Environment[i] = v	
	end
end