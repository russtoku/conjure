-- [nfnl] fnl/conjure/client/sql/stdio.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local a = autoload("conjure.aniseed.core")
local str = autoload("conjure.aniseed.string")
local client = autoload("conjure.client")
local log = autoload("conjure.log")
local text = autoload("conjure.text")
local stdio = autoload("conjure.remote.stdio-rt")
local config = autoload("conjure.config")
local mapping = autoload("conjure.mapping")
local ts = autoload("conjure.tree-sitter")
config.merge({client = {sql = {stdio = {command = "psql postgres://postgres:postgres@localhost/postgres", meta_prefix_pattern = "^[.\\]%w", prompt_pattern = "=> "}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {sql = {stdio = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "sql", "stdio"})
local state
local function _3_()
  return {repl = nil}
end
state = client["new-state"](_3_)
local buf_suffix = ".sql"
local comment_prefix = "-- "
local function get_form_modifier(node)
  if ("statement" == node:type()) then
    return {modifier = "none"}
  elseif a["string?"](string.match(ts["node->str"](node), cfg({"meta_prefix_pattern"}))) then
    local line = vim.api.nvim_get_current_line()
    local _let_4_ = vim.api.nvim_win_get_cursor(0)
    local row = _let_4_[1]
    local _col = _let_4_[2]
    return {modifier = "raw", ["node-table"] = {node = node, content = line, range = {start = {row, 0}, ["end"] = {row, a.count(line)}}}}
  else
    return {modifier = "parent"}
  end
end
local function comment_node_3f(node)
  return (("comment" == node:type()) or ("marginalia" == node:type()))
end
local function with_repl_or_warn(f, opts)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(comment_prefix .. "No REPL running")})
  end
end
local function format_message(msg)
  return str.split((msg.out or msg.err), "\n")
end
local function remove_blank_lines(msg)
  local function _7_(_241)
    return not ("" == _241)
  end
  return a.filter(_7_, format_message(msg))
end
local function display_result(msg)
  return log.append(remove_blank_lines(msg))
end
local function __3elist(s)
  if a.first(s) then
    return s
  else
    return {s}
  end
end
local function prep_code(opts)
  local node = a.get(opts, "node")
  local suffix
  if (node and ("statement" == node:type())) then
    suffix = ";\n"
  else
    suffix = "\n"
  end
  local code = string.gsub(opts.code, "%s*%-%-[^\n]*$", "")
  return (code .. suffix)
end
local function eval_str(opts)
  local function _10_(repl)
    local function _11_(msgs)
      local msgs0 = __3elist(msgs)
      if opts["on-result"] then
        opts["on-result"](str.join("\n", remove_blank_lines(a.last(msgs0))))
      else
      end
      return a["run!"](display_result, msgs0)
    end
    return repl.send(prep_code(opts), _11_, {["batch?"] = false})
  end
  return with_repl_or_warn(_10_)
end
local function eval_file(opts)
  return eval_str(a.assoc(opts, "code", a.slurp(opts["file-path"])))
end
local function interrupt()
  local function _13_(repl)
    log.append({(comment_prefix .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"]("sigint")
  end
  return with_repl_or_warn(_13_)
end
local function display_repl_status(status)
  local repl = state("repl")
  if repl then
    return log.append({(comment_prefix .. a["pr-str"](a["get-in"](repl, {"opts", "cmd"})) .. " (" .. status .. ")")}, {["break?"] = true})
  else
    return nil
  end
end
local function stop()
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return a.assoc(state(), "repl", nil)
  else
    return nil
  end
end
local function start()
  log.append({(comment_prefix .. "Starting SQL client...")})
  if state("repl") then
    return log.append({(comment_prefix .. "Can't start, REPL is already running."), (comment_prefix .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _16_()
      return display_repl_status("started")
    end
    local function _17_(err)
      return display_repl_status(err)
    end
    local function _18_(code, signal)
      if (("number" == type(code)) and (code > 0)) then
        log.append({(comment_prefix .. "process exited with code " .. code)})
      else
      end
      if (("number" == type(signal)) and (signal > 0)) then
        log.append({(comment_prefix .. "process exited with signal " .. signal)})
      else
      end
      return stop()
    end
    local function _21_(msg)
      return display_result(msg)
    end
    return a.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), cmd = cfg({"command"}), ["on-success"] = _16_, ["on-error"] = _17_, ["on-exit"] = _18_, ["on-stray-output"] = _21_}))
  end
end
local function on_load()
  if config["get-in"]({"client_on_load"}) then
    return start()
  else
    return nil
  end
end
local function on_exit()
  return stop()
end
local function on_filetype()
  mapping.buf("SqlStart", cfg({"mapping", "start"}), start, {desc = "Start the REPL"})
  mapping.buf("SqlStop", cfg({"mapping", "stop"}), stop, {desc = "Stop the REPL"})
  return mapping.buf("SqlInterrupt", cfg({"mapping", "interrupt"}), interrupt, {desc = "Interrupt the current REPL"})
end
return {["buf-suffix"] = buf_suffix, ["comment-prefix"] = comment_prefix, ["get-form-modifier"] = get_form_modifier, ["comment-node?"] = comment_node_3f, ["->list"] = __3elist, ["prep-code"] = prep_code, ["eval-str"] = eval_str, ["eval-file"] = eval_file, interrupt = interrupt, stop = stop, start = start, ["on-load"] = on_load, ["on-exit"] = on_exit, ["on-filetype"] = on_filetype}
