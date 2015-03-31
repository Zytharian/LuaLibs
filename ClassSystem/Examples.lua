require("ModuleEnvUnpack")(require("ClassSystem"), _ENV or getfenv())

class 'Example1' (function (this)
	function this:init (arg1, arg2, ...)
		print(arg1)
	end

	function this.member:Apples ()
		print "Apples"
	end

	this.member.HowMany = 4
	this.member.ASDF = "123"
	
	function this.set:HowMany (_, NewValue)
		if type(NewValue) ~= "number" or math.floor(NewValue) ~= NewValue then
			error "Pineapples"
		else
			print("nv: "..NewValue)
			self.HowMany = NewValue
		end
	end
	--this.set.ASDF = "string"

	this.get.ASDF    = true
	this.get.HowMany = true
	this.get.Apples  = true
end)

local inst = new 'Example1'()
inst.HowMany = 5
inst:Apples()
inst.Apples()
