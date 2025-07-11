-- [nfnl] fnl/nfnl/notify.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local core = autoload("conjure.nfnl.core")
local function notify(level, ...)
  return vim.api.nvim_notify(core.str(...), level, {})
end
local function debug(...)
  return notify(vim.log.levels.DEBUG, ...)
end
local function error(...)
  return notify(vim.log.levels.ERROR, ...)
end
local function info(...)
  return notify(vim.log.levels.INFO, ...)
end
local function trace(...)
  return notify(vim.log.levels.TRACE, ...)
end
local function warn(...)
  return notify(vim.log.levels.WARN, ...)
end
return {debug = debug, error = error, info = info, trace = trace, warn = warn}
