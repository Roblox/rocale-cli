local process = require("@lute/process")

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
	"--verbose",
})
