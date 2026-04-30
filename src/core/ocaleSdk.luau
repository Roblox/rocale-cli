local net = require("@lute/net")
local json = require("@std/json")
local fs = require("@std/fs")
local task = require("@lute/task")

local log = require("../util/log")
local richterm = require("@batteries/richterm")

local boldYellowFormatter = richterm.combine(richterm.yellow, richterm.bold)
local spinnerChars = table.freeze({ "|", "/", "-", "\\" })

local function formatSeconds(s: number): string
	return string.format("%.1fs", s)
end

local OcaleSDK = {}

export type BinaryInputResponse = { path: string, size: number, uploadUri: string }
function OcaleSDK.createBinaryInput(apiKey: string, universeId: number, filePath: string): BinaryInputResponse
	local fileSize = #fs.readfiletostring(filePath)

	local response = net.request(
		`https://apis.roblox.com/cloud/v2/universes/{universeId}/luau-execution-session-task-binary-inputs`,
		{
			method = "POST",
			headers = { ["x-api-key"] = apiKey, ["content-type"] = "application/json" },
			body = json.serialize({ size = fileSize }),
		}
	)
	log.fatalif(not response.ok, `{response.status} - {response.body}`)
	return json.deserialize(response.body) :: BinaryInputResponse
end

function OcaleSDK.uploadBinaryFile(uploadUri: string, filePath: string)
	local response = net.request(uploadUri, {
		method = "PUT",
		headers = { ["content-type"] = "application/octet-stream" },
		body = fs.readfiletostring(filePath),
	})
	log.fatalif(not response.ok, `{response.status} - {response.body}`)
end

export type PlaceInfo = {
	universeId: number,
	placeId: number,
	placeVersion: number?,
}

function OcaleSDK.uploadPlaceFile(filePath: string, placeInfo: PlaceInfo, apiKey: string)
	log.info(`{richterm.blue("→", log.noColor())} Uploading {filePath} to Roblox...`)
	local url =
		`https://apis.roblox.com/universes/v1/{placeInfo.universeId}/places/{placeInfo.placeId}/versions?versionType=Saved`
	log.debug(`Request URL: {url}`)
	local response = net.request(url, {
		method = "POST",
		headers = {
			["x-api-key"] = apiKey,
			["content-type"] = "application/xml",
			["Accept"] = "application/json",
		},
		body = fs.readfiletostring(filePath),
	})
	log.fatalif(not response.ok, `{response.status} - {response.body}`)
	log.debug(`Response body: {log.pretty(response.body)}`)
end

local function getCreateTaskPath(placeInfo: PlaceInfo): string
	local url = `https://apis.roblox.com/cloud/v2/universes/{placeInfo.universeId}/places/{placeInfo.placeId}/`
	if placeInfo.placeVersion then
		url ..= `versions/{placeInfo.placeVersion}/`
	end
	url ..= "luau-execution-session-tasks"

	return url
end

export type TaskResponse = {
	path: string,
	createTime: string,
	updateTime: string,
	user: string,
	state: string,
	script: string,
	timeout: string,
	error: {
		code: string,
		message: string,
	}?,
	output: {
		results: { any },
	},
	enableBinaryOutput: boolean,
	binaryInput: string?,
	binaryOutputUri: string?,
}

function OcaleSDK.createTask(
	apiKey: string,
	placeInfo: PlaceInfo,
	scriptPath: string,
	timeout: number?,
	binaryInputPath: string?,
	enableBinaryOutput: boolean?,
	luaGlobals: { [string]: string }?
): TaskResponse
	log.info(`{richterm.blue("→", log.noColor())} Creating the OCALE task...`)
	local url = getCreateTaskPath(placeInfo)
	local entryScript = fs.readfiletostring(scriptPath)

	-- inject globals at the top of the entry script
	if luaGlobals and next(luaGlobals) then
		local globalAssignments: { string } = {}

		for key, value in luaGlobals do
			table.insert(globalAssignments, `_G["{key}"]="{value}";`)
		end
		entryScript = table.concat(globalAssignments) .. entryScript
	end

	local req: net.Metadata = {
		method = "POST",
		headers = { ["x-api-key"] = apiKey, ["content-type"] = "application/json" },
		body = json.serialize({
			script = entryScript,
			binaryInput = binaryInputPath,
			enableBinaryOutput = enableBinaryOutput,
			timeout = `{timeout}s`,
		}),
	}

	log.debug(`Request URL: {url}`)
	local response = net.request(url, req)
	log.fatalif(not response.ok, `{response.status} - {response.body}`)
	local taskResponse = json.deserialize(response.body) :: TaskResponse
	log.debug(`Task path: {taskResponse.path}`)

	return taskResponse
end

function OcaleSDK.pollTaskCompletion(
	apiKey: string,
	taskPath: string,
	timeout: number?,
	pollInterval: number?
): TaskResponse
	local timeRemaining = timeout or 300
	local interval = pollInterval or 2

	local startTime = os.clock()
	log.info(`Polling for OCALE task completion`)

	if not log.noColor() then
		task.spawn(function()
			local spinnerIndex = 1

			while timeRemaining > 0 do
				local spinner = boldYellowFormatter(spinnerChars[spinnerIndex], log.noColor())
				local elapsed = formatSeconds(os.clock() - startTime)

				log.update(`{spinner} {richterm.dim(`[{elapsed}]`, log.noColor())} Polling for OCALE task completion`)
				spinnerIndex = (spinnerIndex % 4) + 1
				task.wait(0.1)
			end
		end)
	end

	while timeRemaining > 0 do
		timeRemaining = timeRemaining - interval

		local response = net.request(`https://apis.roblox.com/cloud/v2/{taskPath}`, {
			method = "GET",
			headers = { ["x-api-key"] = apiKey },
		})
		if not response.ok then
			timeRemaining = 0
			log.fatal(`{response.status} - {response.body}`)
		end

		local body = json.deserialize(response.body) :: TaskResponse
		if body.state ~= "PROCESSING" then
			timeRemaining = 0
			task.wait(0.1)
			local elapsed = formatSeconds(os.clock() - startTime)
			log.info(
				`{richterm.green("✓", log.noColor())} {richterm.dim(`[{elapsed}]`, log.noColor())} OCALE task completed`
			)
			return body
		end

		task.wait(interval)
	end

	timeRemaining = 0
	local elapsed = formatSeconds(os.clock() - startTime)
	--stylua: ignore
	return log.fatal(
		`{richterm.red("✗", log.noColor())} {richterm.dim(`[{elapsed}]`, log.noColor())} Task timed out`
	)
end

function OcaleSDK.getBinaryOutput(binaryOutputUri: string): string
	log.debug(`Binary output URI: {binaryOutputUri}`)
	local response = net.request(binaryOutputUri, {
		method = "GET",
	})
	log.fatalif(not response.ok, `{response.status} - {response.body}`)
	return response.body
end

function OcaleSDK.getTaskLogs(apiKey: string, taskPath: string): { string }
	local response = net.request(`https://apis.roblox.com/cloud/v2/{taskPath}/logs`, {
		method = "GET",
		headers = { ["x-api-key"] = apiKey },
	})
	log.fatalif(not response.ok, `{response.status} - {response.body}`)

	local body = json.deserialize(response.body) :: any
	local logs = body.luauExecutionSessionTaskLogs[1].messages
	log.fatalif(not logs, "Error downloading task logs")

	return logs
end

return OcaleSDK
