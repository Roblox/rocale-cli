local process = require("@lute/process")
local fs = require("@std/fs")

local log = require("../src/util/log")
log.setLevel("debug")

local runProcess = require("../src/util/runProcess")

runProcess({
	"build/rocale-cli",
	"run",
	"--script",
	"tests/run-test-project.luau",
	"--placeId",
	process.env.TEST_PLACE_ID,
	"--universeId",
	process.env.TEST_UNIVERSE_ID,
	"--load.project",
	"tests/test.project.json",
	"--lua.globals",
	"HELLO_GLOBAL=hello,WORLD_GLOBAL=world!",
	"--binaryOutput",
	"build/testOutput.txt",
	"--verbose",
})

local testOutput = fs.readfiletostring("build/testOutput.txt")
fs.remove("build/testOutput.txt")
assert(testOutput == "hello world!", `Expected binary output to be "hello world!"`)

log.info("Rerunning tests using load.version and without optional variables")

runProcess({
	"build/rocale-cli",
	"run",
	"--script",
	"tests/run-test-project.luau",
	"--placeId",
	process.env.TEST_PLACE_ID,
	"--universeId",
	process.env.TEST_UNIVERSE_ID,
	"--load.version",
	"0",
	"--verbose",
})
