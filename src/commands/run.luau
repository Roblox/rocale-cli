local function help()
	print([[
rocale-cli run
Build, upload, and run a Roblox project in Open Cloud

USAGE:
  rocale-cli run [options]

REQUIRED:
  -u, --universeId <id>    Target universe ID to spawn an Open Cloud instance of
  -p, --placeId <id>       Target place ID to spawn an Open Cloud instance of
  --apiKey <key>           Roblox API key (or set ROBLOX_API_KEY env var)

LOAD OPTIONS:
  --load.project <file>    Rojo project.json/rbxp to build and load (requires rojo or robloxdev-cli)
  --load.place <file>      Load an rbxl
  --load.version <num>     Load existing place version without building/uploading
                           (set to 0 to rerun last uploaded version)

BUILD OPTIONS:
  --output <file>          Output file path for the built place file
                           (default: output.rbxl)
  --script <file>          Luau script to load and set as entrypoint

EXECUTION OPTIONS:
  --timeout <seconds>      Timeout for polling task completion (default: 300)
  --pollInterval <seconds> Interval between polling attempts (default: 2)

FLAGS:
  -v, --verbose            Enable verbose logging
  --help                   Show this help message
]])
end

return function(...)
	local fs = require("@std/fs")
	local process = require("@lute/process")

	local richterm = require("@batteries/richterm")

	local cli = require("@batteries/cli")
	local args = cli.parser()

	local log = require("../util/log")

	local ocaleSdk = require("../core/ocaleSdk")
	local runProcess = require("../util/runProcess")

	args:add("script", "option")
	args:add("load.project", "option")
	args:add("output", "option", { default = "output.rbxl" })
	args:add("universeId", "option", { aliases = { "u" } })
	args:add("placeId", "option", { aliases = { "p" } })
	args:add("load.version", "option")
	args:add("load.place", "option")
	args:add("apiKey", "option")
	args:add("timeout", "option", { default = "300" })
	args:add("pollInterval", "option", { default = "2" })
	args:add("verbose", "flag", { aliases = { "v" } })
	args:add("help", "flag")

	args:parse({ ... })

	if args:has("help") then
		help()
		process.exit(0)
	end

	if args:has("verbose") then
		log.setLevel("debug")
	end

	local apiKey = process.env.ROBLOX_API_KEY
		or args:get("apiKey")
		or log.fatal("Missing API Key: Set ROBLOX_API_KEY environment variable or provide it as an argument")

	local placeInfo: ocaleSdk.PlaceInfo = {
		universeId = tonumber(args:get("universeId")) or log.fatal("Missing a universe ID"),
		placeId = tonumber(args:get("placeId")) or log.fatal("Missing a place ID"),
	}

	if
		(
			(args:get("load.place") and 1 or 0)
			+ (args:get("load.version") and 1 or 0)
			+ (args:get("load.project") and 1 or 0)
		) > 1
	then
		log.fatal("Cannot specify more than one --load option")
	end

	if args:get("load.version") then
		local placeVersion = tonumber(args:get("load.version"))
		assert(placeVersion, "Missing place version number")

		if placeVersion > 0 then
			placeInfo.placeVersion = placeVersion
		end
	elseif args:get("load.project") then
		local projectFile = args:get("load.project")
		local outputPath = args:get("output")

		if not projectFile or not fs.exists(projectFile) then
			log.fatal(`Project file '{projectFile}' does not exist`)
		end
		assert(projectFile, "Missing project file path")
		assert(outputPath, "Missing output file path")

		if projectFile:match("%.project%.json$") then
			runProcess({ "rojo", "build", projectFile, "--output", outputPath })
		elseif projectFile:match("%.rbxp$") then
			runProcess({
				"robloxdev-cli",
				"pack",
				"--input",
				projectFile,
				"--output",
				outputPath,
			})
		else
			log.fatal(`Unsupported project file: '{projectFile}'. Must be a 'project.json' or '.rbxp' file.`)
		end

		ocaleSdk.uploadPlaceFile(outputPath, placeInfo, apiKey)
	elseif args:get("load.place") then
		local placeFile = args:get("load.place")
		if not placeFile or not fs.exists(placeFile) then
			log.fatal(`Place file '{placeFile}' does not exist`)
		end
		assert(placeFile, "Missing place file path")

		ocaleSdk.uploadPlaceFile(placeFile, placeInfo, apiKey)
	end

	local entryScript = args:get("script")
	if not entryScript or not fs.exists(entryScript) then
		log.fatal(`'{entryScript}' is not a valid entry script`)
	end
	assert(entryScript)

	local task = ocaleSdk.createTask(apiKey, placeInfo, entryScript, tonumber(args:get("timeout")))
	local completedTask = ocaleSdk.pollTaskCompletion(
		apiKey,
		task.path,
		tonumber(args:get("timeout")),
		tonumber(args:get("pollInterval"))
	)

	local logs = ocaleSdk.getTaskLogs(apiKey, completedTask.path)
	print(table.concat(logs, "\n"))

	if completedTask.state == "FAILED" then
		local taskError = completedTask.error :: any
		log.fatal(`{richterm.red("✗", log.noColor())} Task failed with error: {taskError.code}\n{taskError.message}`)
	elseif completedTask.state == "CANCELLED" then
		log.fatal(`{richterm.red("✗", log.noColor())} Task was cancelled`)
	end
end
