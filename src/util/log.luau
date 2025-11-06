--!strict
--[[
	Simple logger module.
]]

local richterm = require("@batteries/richterm")
local process = require("@lute/process")

local log = {}

type Level = "trace" | "debug" | "info" | "warn" | "error"

local currentLevel: Level = "info"
local colorsEnabled = true -- set to false to disable colors
local showCaller = true -- set to false to disable caller information

local levels = {
	trace = 1,
	debug = 2,
	info = 3,
	warn = 4,
	error = 5,
} :: { [Level]: number }

function log.should(level: Level)
	return levels[level] >= levels[currentLevel]
end

-- Get caller information from debug traceback.
local function getCallerInfo()
	if not showCaller then
		return ""
	end
	local traceback = debug.traceback()
	local lines = string.split(traceback, "\n")

	-- Look for the first line that's not in this logger module.
	for _, line in ipairs(lines) do
		if line:find("util/log") then
			continue
		end

		return line
	end

	return "[unknown]"
end

function log.trace(...)
	if log.should("trace") then
		local l: string = ""
		if colorsEnabled then
			l = richterm.combine(richterm.blue, richterm.dim)("[TRACE] ")
			print(l .. richterm.dim(... or ""))
		else
			l = "[TRACE] "
			print(l .. (... or ""))
		end
	end
end

function log.debug(...)
	if log.should("debug") then
		local l: string = ""
		if colorsEnabled then
			l = richterm.cyan("[DEBUG] ")
			print(l .. richterm.dim(... or ""))
		else
			l = "[DEBUG] "
			print(l .. (... or ""))
		end
	end
end

function log.info(...)
	if log.should("info") then
		local l: string = ""
		if colorsEnabled then
			l = richterm.green("[INFO]  ")
		else
			l = "[INFO]  "
		end
		print(l .. (... or ""))
	end
end

function log.update(...)
	if log.should("info") then
		local l: string = ""
		if colorsEnabled then
			l = richterm.green("[INFO]  ")
			print("\x1b[1A\x1b[2K" .. l .. (... or ""))
		else
			l = "[INFO]  "
			print(l .. (... or ""))
		end
	end
end

function log.warn(...)
	if log.should("warn") then
		local l: string = ""
		if colorsEnabled then
			l = richterm.yellow("[WARN]  ")
		else
			l = "[WARN]  "
		end
		print(l .. (... or ""))
	end
end

function log.error(...)
	if log.should("error") then
		local l: string = ""
		if colorsEnabled then
			l = richterm.red("[ERROR] ")
		else
			l = "[ERROR] "
		end
		print(l .. (... or ""))
	end
end

function log.fatal(...): never
	local caller = getCallerInfo()
	local l: string = ""
	if colorsEnabled then
		l = richterm.red("[FATAL] ")
	else
		l = "[FATAL] "
	end
	print(caller .. " | " .. l .. (... or "") .. "\n")
	process.exit(1)
	return nil :: any
end

function log.fatalif(condition: boolean | number | string | nil, ...)
	if condition then
		log.fatal(...)
	end
end

-- Function to change log level
function log.setLevel(level: Level)
	if levels[level] then
		currentLevel = level
	else
		log.warn("Invalid log level:", level)
	end
end

-- Function to enable/disable colors
function log.enableColors()
	colorsEnabled = true
end

function log.disableColors()
	colorsEnabled = false
end

function log.noColor()
	return not colorsEnabled
end

function log.pretty(tbl: any, indent: number?): string
	local i = indent or 0
	local spacing = string.rep("  ", i)
	if type(tbl) ~= "table" then
		return tostring(tbl)
	end
	local result = "{\n"
	for key, value in pairs(tbl) do
		local keyStr = type(key) == "string" and key or "[" .. tostring(key) .. "]"
		result = result .. spacing .. "  " .. keyStr .. ": "
		if type(value) == "table" then
			result = result .. log.pretty(value, i + 1)
		elseif type(value) == "string" then
			result = result .. '"' .. value .. '"'
		else
			result = result .. tostring(value)
		end
		result = result .. "\n"
	end
	result = result .. spacing .. "}"
	return result
end

return log
