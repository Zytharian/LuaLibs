local LuaUT = require("UnitTests.lua")

local q = 0

LuaUT.Test "Operator" {

	 __Setup = (function ()
		q = q + 1
	 end),
	 
	TestCheckWithBoolean = (function()
		LuaUT.Check(true)
	end);
	
	TestCheckWithBooleanFail = (function()
		LuaUT.Check(false)
	end);

	TestCheckEquals = (function ()
		local Result = 10/2
		LuaUT.CheckEquals(Result, 5)
	end),
	
	TestCheckEqualsFail = (function ()
		LuaUT.CheckEquals("Butterflies", 6)
	end),

	TestCheckWithFunction = (function ()
		LuaUT.Check(function ()
			print "test check w/ function runnning"
		end)
	end),
	
	TestCheckWithFunctionFail = (function ()
		LuaUT.Check(function ()
			error "Should appear in output"
		end)
	end),
	
	TestFail = (function ()
		LuaUT.Fail()
	end),
	
	TestInverseCheck = (function ()
		LuaUT.InverseCheck(false)
	end),
	
	TestInverseCheckWithFunction = (function ()
		LuaUT.InverseCheck(function () error() end)
	end),
	
	TestInverseCheckFail = (function ()
		LuaUT.InverseCheck(true)
	end),
	
	TestInverseCheckWithFunctionFail = (function ()
		LuaUT.InverseCheck(function () end)
	end),

}
LuaUT.RunTest "Operator"

print("Time __Setup called: " .. q .. ", should be " .. 11)