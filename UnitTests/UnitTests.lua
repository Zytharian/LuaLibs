--[[
	UnitTests.lua
	Version: 1.0
	Released: December 12, 2013
	Updated: N/A

	Author: Zytharian

	See documentation file for help.
]]

local TestRegistry = {} -- Formatted as { string TestName = table TestCode }

-- Utility functions
local OutputPrefix = (function ()
	return "[UNIT TEST] "
end)

local GetPrefix = (function (TestName, Subtest)
	return OutputPrefix() .. TestName .. 
		(Subtest and ".".. Subtest or "").." >"
end)

local ExpectType = (function (Input, ExpectedType)
	if type(Input) ~= ExpectedType then
		error(OutputPrefix() .. ExpectedType .. " expected, got " .. type(Input), 3)
	end
end)

local LuaUT = {

	-- void Test(string TestName)(table TestTable)
	-- Creates a test that can be ran later
	Test = (function (TestName)
		ExpectType(TestName, "string")
		if TestRegistry[TestName] then
			error(OutputPrefix() .. "test " .. TestName .." already exists", 2)
		end
		
		return (function (TestTable)
			ExpectType(TestTable, "table")
			TestRegistry[TestName] = TestTable
		end)
	end);

	-- void RunTest(string TestName)
	-- Runs a defined test and outputs the results.
	RunTest = (function (TestName) 
		if not TestRegistry[TestName] then
			error(OutputPrefix() .. "test " .. TestName .. " does not exist", 2)
		end
		
		print(GetPrefix(TestName) .. "Starting test") 
		
		local Setup = TestRegistry[TestName].__Setup
		local TotalSubtests, PassedSubtests = 0, 0
		
		for i,v in next, TestRegistry[TestName] do
			if i ~= "__Setup" and type(v) == "function" then 
				TotalSubtests = TotalSubtests + 1
				if Setup then
					Setup()
				end
				
				local Ret, Err = pcall(v)
				
				if not Ret then
					print(GetPrefix(TestName, i) .. "Failed : " .. Err)
				else
					PassedSubtests = PassedSubtests + 1
					print(GetPrefix(TestName, i) .. "Passed")
				end
				
			end
		end
		
		print(GetPrefix(TestName) .. "Test complete. Out of " .. 
			TotalSubtests .. " subtests, " .. PassedSubtests .. 
			" passed and " .. TotalSubtests - PassedSubtests .. " failed")		
	end);
	
	-- void Fail()
	-- Used to indicate that a subtest has failed.
	Fail = (function ()
		error("Test explicitly failed", 2)
	end);

	-- void Check(function ToCheck) or Check(bool ToCheck)
	-- If function then the function is called and if the 
	-- function errors or returns false, then indicates 
	-- the subtest has failed. If boolean and boolean is 
	-- false or nil, also indicates the subtest has failed.
	Check = (function (ToCheck)
		if type(ToCheck) == "function" then
			local Ret, Err = pcall(ToCheck)
			if Ret == false then
				error("Check failed for " .. tostring(ToCheck) .. " : " .. Err, 2)
			end
		elseif not ToCheck then
			error("Check failed", 2)
		end
	end);
	
	-- void CheckEquals(type ToCheck, type Expected)
	-- Compares the two arguments, if they are equal
	-- the check passes, otherwise the check fails.
	CheckEquals = (function (ToCheck, Expected)
		if ToCheck ~= Expected then
			error("CheckEquals failed. Expected <" .. tostring(Expected) ..
				"> got <" .. tostring(ToCheck) .. ">", 2)
		end
	end);
	
	-- void InverseCheck(function ToCheck) or InverseCheck(bool ToCheck)
	-- Acts exactly like Check() but in the opposite manner.
	-- If a function is passed, it must error for the check to pass, 
	-- and if a boolean is passed, then it must be false or nil.
	InverseCheck = (function (ToCheck)
		if type(ToCheck) == "function" then
			local Ret, Err = pcall(ToCheck)
			if Ret == true then
				error("InverseCheck failed for " .. tostring(ToCheck) .. " : did not error", 2)
			end
		elseif ToCheck then
			error("InverseCheck failed", 2)
		end
	end);

}

return LuaUT

-- Zytharian