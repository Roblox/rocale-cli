local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestProject = require(ReplicatedStorage:FindFirstChild("TestProject"))
assert(TestProject == true, "TestProject did not return true")

local output = {
	BinaryOutput = buffer.fromstring("Hello, World!"),
	ReturnValues = { true }
}
return output
