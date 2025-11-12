local args = { ... }
local version = args[2] or "unknown"
local hash = args[3] or "unknown"

local fs = require("@lute/fs")
local system = require("@lute/system")

local log = require("../src/util/log")
log.setLevel("debug")

local runProcess = require("../src/util/runProcess")

if not fs.exists("build") then
	fs.mkdir("build")
end

local output_path = "build/rocale-cli"
if string.lower(system.os) == "windows_nt" then
	output_path = output_path .. ".exe"
end

log.info("Version: " .. version)
log.info("Commit Hash: " .. hash)
fs.writestringtofile("src/version.luau", `return \{ version="{version}", hash="{hash}" \}`)

log.info("Building rocale-cli...")
runProcess({ "darklua", "process", "src/cli.luau", "build/cli.luau" }) -- Remove when lute compile supports aliases
runProcess({ "lute", "compile", "build/cli.luau", "--output", output_path, "--show-require-graph" })
log.info("Build complete: " .. output_path)
