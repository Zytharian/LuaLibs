--[[
	ClassSystem.lua
	Version: 4.0
	Created: April 11, 2012
	Updated: December 16, 2013

	Author: Zytharian

	See documentation file.
]]


-- Utility functions and setup
local unpack = unpack or table.unpack -- 5.1 - unpack, 5.2 - table.unpack

local ExpectType = (function (Input, ExpectedType)
	if type(Input) ~= ExpectedType then
		error(ExpectedType .. " expected, got " .. type(Input), 3)
	end
end)

local Warn = (function (Msg)
	print("WARNING: " .. Msg)
end)

local Check = (function (Condition, Msg, Level)
	if not Condition then
		error(Msg, Level or 3)
	end
end)

local Fail = (function (Msg, Level)
	error(Msg, Level or 3)
end)

--
-- ========== --
-- ========== --
-- ========== --
--

-- LuaCS table declaration
local LuaCS = {}

-- LuaCS internal variables
local ClassList = {}
--[[
[ClassName] = { bool abstract, string extends = "ClassName",
	function init, table members table get, table set, table meta }
]]

do --Contain these few variables in the scope of only the LuaCS.class function

-- Used for responding to __index and __newindex metamethod invokations
-- when this.get.VarName and/or this.set.VarName are set to true during definition.
local Default_Get = (function (self, MemberName)
		return self[MemberName]
end)
local Default_Set = (function (self, MemberName, NewVal)
		self[MemberName] = NewVal
end)

-- These two are set as the __index and __newindex metamethods of the 'this' table
-- to alert to attempts to change the definition after 'class' has processed the table.
local Temp_M_Index = (function (self, Index)
	Fail("Attempt to access definition table after definition completed.")
end)
local Temp_M_NewIndex = (function (self, Index, NewVal)
	Fail("Attempt to change definition table after definition completed.")
end)

-- LuaCS::class
LuaCS.class = (function (ClassName)
	ExpectType(ClassName, "string")
	Check(not LuaCS.ClassExists(ClassName), "Cannot redefine class '" .. ClassName .. "'")

	local Constructor = {} -- Returned by function for fancy syntax magic

	-- Table used internally to store the definition of the class
	local Data = {abstract = false, extends = nil,
	init = nil, member = {}, get = {}, set = {}, meta = {}}

	-- Table passed to function defining the class
	local Temp = {get = {}, set = {}, member = {}, meta = {}, init = nil}

	local GetDefinition = (function (Def)
		ExpectType(Def, "function")

		-- Call definition function with the temp table to get initial
		-- class definition data
		Def(Temp)

		-- The rest of this function is verifying the temp table data
		-- and transfering stuff to the final data table

		if type(Temp.init) == "function" then
			Data.init = Temp.init
		elseif Temp.init ~= nil then
			Warn("Attmpt to set constructor of '" .. ClassName .. "' with type '" ..
				type(Temp.init) .."'. Skipping...")
		end
		Temp.init = nil

		for i,v in next, Temp.get do
			if type(v) == "boolean" and v then
				Data.get[i] = Default_Get
			elseif type(v) == "function" then
				Data.get[i] = v
			else
				Warn("The getter '" .. i .. "' in definition of '" .. ClassName ..
				"' must be a function or the boolean 'true'. Skipping...")
			end
		end
		Temp.get = nil

		for i,v in next, Temp.set do
			if type(v) == "boolean"  and v then
				Data.set[i] = Default_Set
			elseif type(v) == "function" then
				Data.set[i] = v
			else
				Warn("The setter '" .. i .. "' in definition of '" .. ClassName ..
				"' must be a function or the boolean 'true'. Skipping...")
			end
		end
		Temp.set = nil

		for i,v in next, Temp.member do
			-- Used to warn against accidently setting a class/table as a member
			-- Essentially if you have an intance var that's a table/userdata
			-- it should probably be created/set in the constructor
			if type(v) == "table" or type(v) == "userdata" then
				Warn("Member '" .. i .. "' in definition of '" .. ClassName ..
					"'cannot be a table or userdata. Skipping...")
			else
				Data.member[i] = v
			end
		end
		Temp.member = nil

		for i,v in next, Temp.meta do
			if type(v) ~= "function" then
				Warn("The metamethod '" .. i .. "' in definition of '" .. ClassName ..
				"' must be a function. Skipping...")
			else
				Data.meta[i] = v
			end
		end
		Temp.meta = nil

		for i,v in next, Temp do
			Warn("Extra index '" .. i .. "' in definition of '" ..
				ClassName .. "'. Skipping...")
		end

		-- Protect certain metamethods
		Data.meta.__index     = nil
		Data.meta.__newindex  = nil
		Data.meta.__metatable = nil
		Data.meta.__mode      = nil

		-- Clear temp table
		for i,v in next, Temp do
			Temp[i] = nil
		end

		-- Force temp table to error on any further usage
		setmetatable(Temp, {
			__index = Temp_M_Index;
			__newindex = Temp_M_NewIndex;
			__metatable = "Cannot change definition table after definition complete.";
		})

		ClassList[ClassName] = Data
	end)

	setmetatable(Constructor,{
		__call = (function (tbl,Func)
			ExpectType(Func, "function")
			GetDefinition(Func)
		end);
	})
	function Constructor:extends (OtherClass)
		Check(not Data.extends,"cannot extend multiple classes")
		Check(LuaCS.ClassExists(OtherClass),"can only extend existing classes")
		Data.extends = OtherClass
		return Constructor
	end
	function Constructor:abstract ()
		Data.abstract = true
		return Constructor
	end

	return Constructor
end)

end -- end scope of LuaCS::class function

-- LuaCS::new
LuaCS.new = (function (ClassName)
	Check(LuaCS.ClassExists(ClassName),"class does not exist")
	Check(not ClassList[ClassName].abstract,"cannot create a structural class")

	return (function (...) -- Get arguments for constructor
		local this = { proxy = {}, member = {}, get = {}, set = {}, meta = {} }

		-- Hangle inheritance
		for _,class in next, LuaCS.ClassAncestry(ClassName) do

			-- Copy members from |ClassList| table to |this| table.
			local CpyTbl = {
				[ClassList[class].get] = this.get;
				[ClassList[class].set] = this.set;
				[ClassList[class].member] = this.member;
				[ClassList[class].meta] = this.meta;
			}

			for from,to in next, CpyTbl do
				for i,v in next, from do
					to[i] = v
				end
			end

			-- Initialize each class
			if ClassList[class].init then
				ClassList[class].init(this.member, ...)
			end
		end

		-- Metatable for the proxy table that will be returned by 'new'.
		local Meta = {
			__index = (function (t,i)
				if this.get[i] then
					local get = this.get[i](this.member,i)
					if type(get) == "function" then
						return (function (...) -- Proxy function
							local tbl = {...}
							if tbl[1] == this.proxy or tbl[1] == this.member then
								table.remove(tbl, 1)
							end
							return get(this.member, unpack(tbl))
						end)
					else
						return get
					end
				else
					Fail("member '"..i.."' cannot be indexed")
				end
			end);
			__newindex = (function (t,i,v)
				if this.set[i] then
					this.set[i](this.member,i,v)
				else
					Fail("member '"..i.."' cannot be set")
				end
			end);
			__metatable = "The metatable is locked"
		}

		for i,v in next, this.meta do
			Meta[i] = (function (Proxy, ...)
				return v(this.member, ...)
			end)
		end

		setmetatable(this.proxy, Meta)

		return this.proxy
	end)
end)

-- LuaCS::ClassExists
LuaCS.ClassExists = (function (ClassName)
	ExpectType(ClassName, "string")
	return ClassList[ClassName] and true or false
end)

-- LuaCS::ClassAncestry
LuaCS.ClassAncestry = (function (ClassName)
	Check(LuaCS.ClassExists(ClassName),"class does not exist")
	local Heritance = {[1]=ClassName}
	while ClassList[ClassName].extends do
		ClassName = ClassList[ClassName].extends
		table.insert(Heritance,1,ClassName)
	end
	return Heritance
end)

return LuaCS

--Zytharian
