require("ModuleEnvUnpack.lua")(require("ClassSystem.lua"), _ENV or getfenv())
local unpack = unpack or table.unpack --5.1 - unpack, 5.2 - table.unpack

-- Define standard classes
class 'Connection' (function (this)
	-- Dcn(true) disconnects listener, disconnect Dcn(false) returns bool isConnected
	function this:init (Dcn)
		assert(type(Dcn) == "function")
		self.Dcn = Dcn
	end

	function this.member:Disconnect ()
		self.Dcn(true)
	end

	-- Set up 'Connected' property
	function this.get:Connected (MemberName)
		return self.Dcn(false)
	end

	this.get.Disconnect = true
end)

class 'Signal' (function (this)

	function this:init ()
		self.Connections = {} --[i] = {function handler, Class::Listener listener}
	end

	function this.member:Connect (f)
		local t
		local Dcn = (function (bool)
			if bool then -- disconnect
				for i,v in next, self.Connections do
					if v == t then
						table.remove(self.Connections,i)
					end
				end
			else -- is connected
				for i,v in next, self.Connections do
					if v == t then
						return true
					end
				end
				return false
			end
		end)
		local Lisnr = new 'Connection' (Dcn)

		t = {handler=f,listener=Lisnr}
		table.insert(self.Connections, t)
		return Lisnr
	end
	function this.member:Fire (...)
		local tbl = {} --So we don't fire it if someone connects when we fire one of the events
		for i,v in next, self.Connections do
			table.insert(tbl,v)
		end
		for i,v in next, tbl do
			local thread = coroutine.create(v.handler) --creates new thread
			local b, err = coroutine.resume(thread, ...) --Runs the thread
			if not b then
				print("Connection error: "..err)
				print("Disconnecting because of exception")
				v.listener:Disconnect()
			end
		end
	end
	function this.member:DisconnectAll ()
		self.Connections = {}
	end

	this.get.Connect		= true
	this.get.Fire 			= true
	this.get.DisconnectAll 	= true
end)

class 'EnumItem' (function (this)

	function this:init (Name, Id)
		if type(Name) ~= "string" or type(Id) ~= "number" then
			error("string and number expected as initializer",3)
		end
		self.Name = Name
		self.Id = Id
	end

	this.member.Name 	= "None"
	this.member.Id 		= 0

	this.get.Name 		= true
	this.get.Id 		= true
end)

class 'Enum' (function (this)

	function this:init (Tbl)
		self.Items = {}
		for i,v in next, Tbl do
			self.Items[i] = new 'EnumItem' (v,i) --v = name, i = id
		end
	end

	function this.member:GetEnumItems ()
		local Tbl = {}
		for i,v in next,self.Items do
			Tbl[i] = v
		end
		return Tbl
	end

	function this.member:GetItem (Name)
		if type(Name) == "number" then
			if not self.Items[Name] then
				error("EnumItem Id "..Name.." does not exist",3)
			end
			return self.Items[Name]
		elseif type(Name) == "string" then
			for i,v in next, self.Items do
				if v.Name == Name then
					return v
				end
			end
			error("EnumItem Name "..Name.." does not exist",3)
		else
			error("string or number expected",3)
		end
	end

	this.get.GetItem 		= true
	this.get.GetEnumItems 	= true
end)

class 'Instance' : abstract() (function (this)

	function this.member:IsA(SuperClass)
		for i,v in next, ClassAncestry(self.ClassName) do
			if v == SuperClass then
				return true
			end
		end
		return false
	end
	
	this.member.ClassName = "Instance" -- Read-only
	
	this.get.ClassName	= true
	this.get.IsA		= true
end)

--Zytharian
