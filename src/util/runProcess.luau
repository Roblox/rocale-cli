local process = require("@lute/process")

local log = require("@src/util/log")

return function(cmd)
	log.debug(`Running command: {table.concat(cmd, " ")}`)

	local ok, result = pcall(function()
		return process.run(cmd, { stdio = "inherit", env = { PATH = `{process.cwd()}:{process.env.PATH}` } })
	end)

	log.fatalif(not ok, result)

	if result.ok then
		return result.stdout
	else
		return log.fatal(`Error while running command: {result.stderr}`)
	end
end
