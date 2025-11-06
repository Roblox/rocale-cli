local fs = require("@lute/fs")

local log = require("@src/util/log")
log.setLevel("debug")

local runProcess = require("@src/util/runProcess")

if not fs.exists("build") then
	fs.mkdir("build")
end

log.info("Building rocale-cli...")
runProcess({ "darklua", "process", "src/cli.luau", "build/cli.luau" }) -- Remove when lute compile supports aliases
runProcess({ "lute", "compile", "build/cli.luau", "--output", "build/rocale-cli", "--show-require-graph" })
log.info("Build complete: build/rocale-cli")
