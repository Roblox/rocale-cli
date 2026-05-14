--[[
	Simple logger module.
]]

local richterm = require("@batteries/richterm")
local process = require("@lute/process")

local log = {}

type Level = "trace" | "debug" | "info" | "warn" | "error"

local dimBlueFormatter = richterm.combine(richterm.blue, richterm.dim)
local currentLevel: Level = "info"

local colorsEnabled = true -- set to false to disable colors
if process.env.LOG_NO_COLOR then
	colorsEnabled = false
end

local showCaller = true -- set to false to disable caller information

local levels = table.freeze({
	trace = 1,
	debug = 2,
	info = 3,
	warn = 4,
	error = 5,
}) :: { [Level]: number }

local function stringifyVararg(...: any): string
	return table.concat({ ... }, " ")
end

function log.should(level: Level)
	return levels[level] >= levels[currentLevel]
end

function log.trace(...)
	if log.should("trace") then
		local prefix = dimBlueFormatter("[TRACE] ")
		print(prefix .. richterm.dim(stringifyVararg(...), colorsEnabled))
	end
end

function log.debug(...)
	if log.should("debug") then
		local prefix = richterm.cyan("[DEBUG] ", colorsEnabled)
		print(prefix .. richterm.dim(stringifyVararg(...), colorsEnabled))
	end
end

function log.info(...)
	if log.should("info") then
		local prefix = richterm.green("[INFO]  ", colorsEnabled)
		print(prefix .. stringifyVararg(...))
	end
end

function log.update(...)
	if log.should("info") then
		local prefix = richterm.green("[INFO]  ", colorsEnabled)
		print("\x1b[1A\x1b[2K" .. prefix .. stringifyVararg(...))
	end
end

function log.warn(...)
	if log.should("warn") then
		local prefix = richterm.yellow("[WARN]  ", colorsEnabled)
		print(prefix .. stringifyVararg(...))
	end
end

function log.error(...)
	if log.should("error") then
		local prefix = richterm.red("[ERROR] ", colorsEnabled)
		print(prefix .. stringifyVararg(...))
	end
end

function log.fatal(...): never
	local prefix = richterm.red("[FATAL] ", colorsEnabled)
	local message = prefix .. stringifyVararg(...)

	print(if showCaller then debug.traceback(message, 2) else message)
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
	if type(tbl) ~= "table" then
		return tostring(tbl)
	end

	indent = indent or 0
	local spacing = string.rep("  ", indent)
	local result = { "{" }

	for key, value in tbl do
		local keyStr = if type(key) == "string" then key else `["{key}"]`
		--stylua: ignore
		local valueStr = if type(value) == "table" then
				log.pretty(value, indent + 1)
			elseif type(value) == "string" then
				`"{value}"`
			else
				value

		table.insert(result, `{keyStr}: {valueStr}`)
	end
	table.insert(result, "}")
	return table.concat(result, `\n{spacing}`)
end

return table.freeze(log)
