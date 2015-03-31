require("ModuleEnvUnpack.lua")(require("ClassSystem.lua"), _ENV or getfenv())
require("ModuleEnvUnpack.lua")(require("UnitTests.lua"), _ENV or getfenv())

Test "Class" {

	BasicInstantiation = (function ()
		class 'Class_Test1' (function (this) end)
		local Obj = new 'Class_Test1' ()
		Check(Obj)
	end);

	Constructor = (function ()
		local ConstructorHasRun = false
		class 'Class_Test2' (function (this)
			function this:init ()
				ConstructorHasRun = true
			end
		end)
		local Obj = new 'Class_Test2' ()

		Check(ConstructorHasRun)
	end);

	ConstructorArguments = (function ()
		local Arg1 = nil
		class 'Class_Test3' (function (this)
			function this:init (PassedArg1)
				Check(type(self) == "table", "constructor must have a self variable")
				Arg1 = PassedArg1
			end
		end)
		local Obj = new 'Class_Test3' ("hi")

		CheckEquals(Arg1, "hi")
	end);

	Methods = (function ()
		local MethodHasRun = false
		class 'Class_Test4' (function (this)
			function this.member:Test ()
				MethodHasRun = true
			end
			this.get.Test = true
		end)
		local Obj = new 'Class_Test4' ()
		Obj:Test()

		Check(MethodHasRun)
	end);

	MethodArguments = (function ()
		local Arg1 = nil
		class 'Class_Test5' (function (this)
			function this.member:Test (PassedArg1)
				Check(type(self) == "table", "method must have a self variable")
				Arg1 = PassedArg1
			end
			this.get.Test = true
		end)
		local Obj = new 'Class_Test5' ()
		Obj:Test("hi")

		CheckEquals(Arg1, "hi")
	end);

	DefaultGetter = (function ()
		class 'Class_Test6' (function (this)
			this.member.val = 5

			this.get.val = true
		end)

		local Obj = new 'Class_Test6' ()
		Check(function ()
			CheckEquals(Obj.val, 5)
		end)
	end);

	DefaultSetter = (function ()
		class 'Class_Test7' (function (this)
			this.member.val = 5

			this.get.val = true
			this.set.val = true
		end)

		local Obj = new 'Class_Test7' ()
		Check(function ()
			Obj.val = 100
			CheckEquals(Obj.val, 100)
		end)
	end);

	StoringVariables = (function ()
		class 'Class_Test8' (function (this)
			this.member.val = 5

			function this.member:Test()
				self.val = self.val + 100
			end

			this.set.val = true
			this.get.val = true
			this.get.Test = true
		end)
		local Obj = new 'Class_Test8' ()

		CheckEquals(Obj.val, 5)
		Obj:Test()
		CheckEquals(Obj.val, 105)
	end);

	CustomGetter = (function ()
		class 'Class_Test9' (function (this)
			this.member.val = 5

			function this.get:val (Val)
				return 100
			end

			function this.member:Test()
				CheckEquals(self.val, 5)
			end

			this.get.Test = true
		end)
		local Obj = new 'Class_Test9' ()

		CheckEquals(Obj.val, 100)
		Obj:Test()
	end);

	CustomSetter = (function ()
		class 'Class_Test10' (function (this)
			this.member.val = 5

			function this.set:val (Val, NewVal)
				self.val = NewVal * 2
			end
			this.get.val = true

			function this.member:Test()
				self.val = 100
			end
			this.get.Test = true
		end)
		local Obj = new 'Class_Test10' ()

		Obj.val = 4
		CheckEquals(Obj.val, 8)
		Obj:Test()
		CheckEquals(Obj.val, 100)

	end);

	PrivateMember = (function ()
		class 'Class_Test11' (function (this)
			this.member.val = 5
		end)
		local Obj = new 'Class_Test11' ()

		InverseCheck(function ()
			local PrivMem = Obj.val
		end)
	end);
}

Test 'Inheritance' {

	AbstractInstantiation = (function ()
		class 'Inheritance_Test1' : abstract() (function (this) end)

		InverseCheck(function ()
			new 'Inheritance_Test1' ()
		end)
	end);

	BasicInheritance = (function ()
		class 'Inheritance_Test2' : abstract() (function (this) end)
		class 'Inheritance_Test3' : extends 'Inheritance_Test2' (function (this) end)
		Check(function ()
			Check(new 'Inheritance_Test3' ())
		end)
	end);

	MethodOverride = (function ()
		local TestRan = "None"
		class 'Inheritance_Test4' : abstract() (function (this) 
			function this.member:Test()
				TestRan = "Base"
			end
			this.get.Test = true
		end)
		class 'Inheritance_Test5' : extends 'Inheritance_Test4' (function (this) 
			function this.member:Test()
				TestRan = "Subclass"
			end
		end)
		local Obj = new 'Inheritance_Test5' ()
		
		Obj:Test()
		CheckEquals(TestRan, "Subclass")
	end);

	BaseConstructor = (function ()
		local BaseConstructorRan = false
		class 'Inheritance_Test6' : abstract() (function (this)
			function this:init ()
				BaseConstructorRan = true
			end
		end)
		class 'Inheritance_Test7' : extends 'Inheritance_Test6' (function (this) end)
		
		local Obj = new 'Inheritance_Test7' ()
		
		Check(BaseConstructorRan)
	end);

	SubclassConstructor = (function ()
		local SubConstructorRan = false
		class 'Inheritance_Test8' : abstract() (function (this)	end)
		class 'Inheritance_Test9' : extends 'Inheritance_Test8' (function (this)
			function this:init ()
				SubConstructorRan = true
			end
		end)
		
		local Obj = new 'Inheritance_Test9' ()
		
		Check(SubConstructorRan)
	end);

	AllConstructorsRunInOrder = (function ()
		local SubConstructorRan, BaseConstructorRan = false, false
		local RunNum = 0 -- Base runs first
		class 'Inheritance_Test10' : abstract() (function (this)	
			function this:init ()
				BaseConstructorRan = true
				RunNum = RunNum + 1
				CheckEquals(RunNum, 1)
			end
		end)
		class 'Inheritance_Test11' : extends 'Inheritance_Test10' (function (this)
			function this:init ()
				SubConstructorRan = true
				RunNum = RunNum + 1
				CheckEquals(RunNum, 2)
			end
		end)
		
		local Obj = new 'Inheritance_Test11' ()
		
		Check(BaseConstructorRan)
		Check(SubConstructorRan)
	end);

	HasBaseMembers = (function ()
		class 'Inheritance_Test12' : abstract() (function (this)
			this.member.TestVar = 5		
			this.get.TestVar = true
		end)
		class 'Inheritance_Test13' : extends 'Inheritance_Test12' (function (this) end)
		
		local Obj = new 'Inheritance_Test13' ()
		
		CheckEquals(Obj.TestVar, 5)
	end);

}

RunTest "Class"
RunTest "Inheritance"