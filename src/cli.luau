local args = { ... }
local VERSION = "0.1.0"

local function help()
	print([[
rocale-cli
A command-line tool for building, uploading, and running Roblox projects in OCALE

USAGE:
  rocale-cli <command> [options]

COMMANDS:
  run      Build, upload, and run a Roblox project in OCALE.
  help     Show this help message.
  version  Show version.

For more information about a command, run: rocale-cli <command> --help
]])
end

local function version()
	print(VERSION)
end

local availableCommands = {
	run = require("@src/commands/run"),
	help = help,
	version = version
}

local command = availableCommands[args[2]] or availableCommands["help"]

command(...)
