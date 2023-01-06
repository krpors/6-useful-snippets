local Logger = {}

function Logger.info(s, ...)
	print(string.format("\x1b[32;1m[INFO]\x1b[0m  %2.3f -> ", os.clock())  .. string.format(s, ...))
end

function Logger.warn(s, ...)
	print(string.format("\x1b[33;1m[WARN]\x1b[0m  %2.3f -> ", os.clock()) .. string.format(s, ...))
end

function Logger.error(s, ...)
	print(string.format("\x1b[31;1m[ERROR]\x1b[0m %2.3f -> ", os.clock()) .. string.format(s, ...))
end

return Logger
