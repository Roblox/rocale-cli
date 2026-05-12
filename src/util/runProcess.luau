local process = require("@std/process")
local system = require("@std/system")

local log = require("../util/log")

local isWin32 = string.lower(system.os) == "windows_nt"

local function runProcess(...: string): string
	local cmd = { ... }

	if isWin32 then
		cmd[1] ..= ".exe"
	end
	local cmdStr = table.concat(cmd, " ")
	log.debug(`Running command: {cmdStr}`)

	local result = process.run(cmd, {
		stdio = "inherit",
		env = {
			PATH = `{process.cwd()}{if isWin32 then ";" else ":"}{process.env.PATH}`,
		},
	})

	if result.ok then
		return result.stdout
	else
		return log.fatal(`Error while running command: {cmdStr}\n{result.stderr}`)
	end
end

return runProcess
