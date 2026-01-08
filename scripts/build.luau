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

local versionFile = fs.open("src/version.luau", "w+")
fs.write(versionFile, `return \{ version="{version}", hash="{hash}" \}`)
fs.close(versionFile)

log.info("Building rocale-cli...")
runProcess({ "lute", "compile", "src/cli.luau", "--output", output_path, "--show-require-graph", "--bundle-stats" })
log.info("Build complete: " .. output_path)
