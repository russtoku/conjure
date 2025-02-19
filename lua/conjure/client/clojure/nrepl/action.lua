-- [nfnl] Compiled from fnl/conjure/client/clojure/nrepl/action.fnl by https://github.com/Olical/nfnl, do not edit.
local autoload = require("conjure.nfnl.autoload")
local a = autoload("conjure.aniseed.core")
local auto_repl = autoload("conjure.client.clojure.nrepl.auto-repl")
local config = autoload("conjure.config")
local editor = autoload("conjure.editor")
local extract = autoload("conjure.extract")
local fs = autoload("conjure.fs")
local hook = autoload("conjure.hook")
local ll = autoload("conjure.linked-list")
local log = autoload("conjure.log")
local nrepl = autoload("conjure.remote.nrepl")
local nvim = autoload("conjure.aniseed.nvim")
local parse = autoload("conjure.client.clojure.nrepl.parse")
local server = autoload("conjure.client.clojure.nrepl.server")
local str = autoload("conjure.aniseed.string")
local text = autoload("conjure.text")
local ui = autoload("conjure.client.clojure.nrepl.ui")
local view = autoload("conjure.aniseed.view")
local function require_ns(ns)
  if ns then
    local function _1_()
    end
    return server.eval({code = ("(require '" .. ns .. ")")}, _1_)
  else
    return nil
  end
end
local cfg = config["get-in-fn"]({"client", "clojure", "nrepl"})
local function passive_ns_require()
  if (cfg({"eval", "auto_require"}) and server["connected?"]()) then
    return require_ns(extract.context())
  else
    return nil
  end
end
local function connect_port_file(opts)
  local resolved_path
  do
    local tmp_6_auto = cfg({"connection", "port_files"})
    if (tmp_6_auto ~= nil) then
      resolved_path = fs["resolve-above"](tmp_6_auto)
    else
      resolved_path = nil
    end
  end
  local resolved
  if resolved_path then
    local port = a.slurp(resolved_path)
    if port then
      resolved = {path = resolved_path, port = tonumber(port)}
    else
      resolved = nil
    end
  else
    resolved = nil
  end
  if resolved then
    local _8_
    do
      local t_7_ = resolved
      if (nil ~= t_7_) then
        t_7_ = t_7_.path
      else
      end
      _8_ = t_7_
    end
    local _11_
    do
      local t_10_ = resolved
      if (nil ~= t_10_) then
        t_10_ = t_10_.port
      else
      end
      _11_ = t_10_
    end
    local function _13_()
      do
        local cb = a.get(opts, "cb")
        if cb then
          cb()
        else
        end
      end
      return passive_ns_require()
    end
    return server.connect({host = cfg({"connection", "default_host"}), port_file_path = _8_, port = _11_, cb = _13_, ["connect-opts"] = a.get(opts, "connect-opts")})
  else
    if not a.get(opts, "silent?") then
      log.append({"; No nREPL port file found"}, {["break?"] = true})
      return auto_repl["upsert-auto-repl-proc"]()
    else
      return nil
    end
  end
end
local function _17_(cb)
  return connect_port_file({["silent?"] = true, cb = cb})
end
hook.define("client-clojure-nrepl-passive-connect", _17_)
local function try_ensure_conn(cb)
  if not server["connected?"]() then
    return hook.exec("client-clojure-nrepl-passive-connect", cb)
  else
    if cb then
      return cb()
    else
      return nil
    end
  end
end
local function connect_host_port(opts)
  if (not opts.host and not opts.port) then
    return connect_port_file()
  else
    local parsed_port
    if ("string" == type(opts.port)) then
      parsed_port = tonumber(opts.port)
    else
      parsed_port = nil
    end
    if parsed_port then
      return server.connect({host = (opts.host or cfg({"connection", "default_host"})), port = parsed_port, cb = passive_ns_require})
    else
      return log.append({str.join({"; Could not parse '", (opts.port or "nil"), "' as a port number"})})
    end
  end
end
local function eval_cb_fn(opts)
  local function _23_(resp)
    if (a.get(opts, "on-result") and a.get(resp, "value")) then
      opts["on-result"](resp.value)
    else
    end
    local cb = a.get(opts, "cb")
    if cb then
      return cb(resp)
    else
      if not opts["passive?"] then
        return ui["display-result"](resp, opts)
      else
        return nil
      end
    end
  end
  return _23_
end
local function eval_str(opts)
  local function _27_()
    local function _28_(conn)
      if (opts.context and not a["get-in"](conn, {"seen-ns", opts.context})) then
        local function _29_()
        end
        server.eval({code = ("(ns " .. opts.context .. ")")}, _29_)
        a["assoc-in"](conn, {"seen-ns", opts.context}, true)
      else
      end
      return server.eval(opts, eval_cb_fn(opts))
    end
    return server["with-conn-or-warn"](_28_)
  end
  return try_ensure_conn(_27_)
end
local function with_info(opts, f)
  local function _31_(conn, ops)
    local _32_
    if ops.info then
      _32_ = {op = "info", ns = (opts.context or "user"), symbol = opts.code, session = conn.session}
    elseif ops.lookup then
      _32_ = {op = "lookup", ns = (opts.context or "user"), sym = opts.code, session = conn.session}
    else
      _32_ = nil
    end
    local function _34_(msg)
      local function _35_()
        if not msg.status["no-info"] then
          return (msg.info or msg)
        else
          return nil
        end
      end
      return f(_35_())
    end
    return server.send(_32_, _34_)
  end
  return server["with-conn-and-ops-or-warn"]({"info", "lookup"}, _31_)
end
local function java_info__3elines(_36_)
  local arglists_str = _36_["arglists-str"]
  local class = _36_["class"]
  local member = _36_["member"]
  local javadoc = _36_["javadoc"]
  local function _37_()
    if member then
      return {"/", member}
    else
      return nil
    end
  end
  local _38_
  if not a["empty?"](arglists_str) then
    _38_ = {("; (" .. str.join(" ", text["split-lines"](arglists_str)) .. ")")}
  else
    _38_ = nil
  end
  local function _40_()
    if javadoc then
      return {("; " .. javadoc)}
    else
      return nil
    end
  end
  return a.concat({str.join(a.concat({"; ", class}, _37_()))}, _38_, _40_())
end
local function doc_str(opts)
  local function _41_()
    require_ns("clojure.repl")
    local function _42_(msgs)
      local function _43_(msg)
        return (a.get(msg, "out") or a.get(msg, "err"))
      end
      if a.some(_43_, msgs) then
        local function _44_(_241)
          return ui["display-result"](_241, {["simple-out?"] = true, ["ignore-nil?"] = true})
        end
        return a["run!"](_44_, msgs)
      else
        log.append({"; No results for (doc ...), checking nREPL info ops"})
        local function _45_(info)
          if a["nil?"](info) then
            return log.append({"; No information found, all I can do is wish you good luck and point you to https://duckduckgo.com/"})
          elseif ("string" == type(info.javadoc)) then
            return log.append(java_info__3elines(info))
          elseif ("string" == type(info.doc)) then
            return log.append(a.concat({str.join({"; ", info.ns, "/", info.name}), str.join({"; ", info["arglists-str"]})}, text["prefixed-lines"](info.doc, "; ")))
          else
            return log.append(a.concat({"; Unknown result, it may still be helpful"}, text["prefixed-lines"](view.serialise(info), "; ")))
          end
        end
        return with_info(opts, _45_)
      end
    end
    return server.eval(a.merge({}, opts, {code = ("(clojure.repl/doc " .. opts.code .. ")")}), nrepl["with-all-msgs-fn"](_42_))
  end
  return try_ensure_conn(_41_)
end
local function nrepl__3envim_path(path)
  if text["starts-with"](path, "jar:file:") then
    local function _48_(zip, file)
      if (tonumber(string.sub(nvim.g.loaded_zipPlugin, 2)) > 31) then
        return ("zipfile://" .. zip .. "::" .. file)
      else
        return ("zipfile:" .. zip .. "::" .. file)
      end
    end
    return string.gsub(path, "^jar:file:(.+)!/?(.+)$", _48_)
  elseif text["starts-with"](path, "file:") then
    local function _50_(file)
      return file
    end
    return string.gsub(path, "^file:(.+)$", _50_)
  else
    return path
  end
end
local function def_str(opts)
  local function _52_()
    local function _53_(info)
      if a["nil?"](info) then
        return log.append({"; No definition information found"})
      elseif info.candidates then
        local function _54_(_241)
          return (_241 .. "/" .. opts.code)
        end
        return log.append(a.concat({"; Multiple candidates found"}, a.map(_54_, a.keys(info.candidates))))
      elseif (info.file and info.line) then
        local column = (info.column or 1)
        local path = nrepl__3envim_path(info.file)
        editor["go-to"](path, info.line, column)
        return log.append({("; " .. path .. " [" .. info.line .. " " .. column .. "]")}, {["suppress-hud?"] = true})
      elseif info.javadoc then
        return log.append({"; Can't open source, it's Java", ("; " .. info.javadoc)})
      elseif info["special-form"] then
        local function _55_()
          if info.url then
            return ("; " .. info.url)
          else
            return nil
          end
        end
        return log.append({"; Can't open source, it's a special form", _55_()})
      else
        return log.append({"; Unsupported target", ("; " .. a["pr-str"](info))})
      end
    end
    return with_info(opts, _53_)
  end
  return try_ensure_conn(_52_)
end
local function escape_backslashes(s)
  return s:gsub("\\", "\\\\")
end
local function eval_file(opts)
  local function _57_()
    local function _58_(conn)
      return server["load-file"](a.assoc(opts, "code", a.slurp(opts["file-path"])), eval_cb_fn(opts))
    end
    return server["with-conn-or-warn"](_58_)
  end
  return try_ensure_conn(_57_)
end
local function interrupt()
  local function _59_()
    local function _60_(conn)
      local msgs
      local function _61_(msg)
        return ("eval" == msg.msg.op)
      end
      msgs = a.filter(_61_, a.vals(conn.msgs))
      local order_66
      local function _63_(_62_)
        local id = _62_["id"]
        local session = _62_["session"]
        local code = _62_["code"]
        server.send({op = "interrupt", ["interrupt-id"] = id, session = session})
        local function _64_(sess)
          local _65_
          if code then
            _65_ = text["left-sample"](code, editor["percent-width"](cfg({"interrupt", "sample_limit"})))
          else
            _65_ = ("session: " .. sess.str() .. "")
          end
          return log.append({("; Interrupted: " .. _65_)}, {["break?"] = true})
        end
        return server["enrich-session-id"](session, _64_)
      end
      order_66 = _63_
      if a["empty?"](msgs) then
        return order_66({session = conn.session})
      else
        local function _67_(a0, b)
          return (a0["sent-at"] < b["sent-at"])
        end
        table.sort(msgs, _67_)
        return order_66(a.get(a.first(msgs), "msg"))
      end
    end
    return server["with-conn-or-warn"](_60_)
  end
  return try_ensure_conn(_59_)
end
local function eval_str_fn(code)
  local function _69_()
    return nvim.ex.ConjureEval(code)
  end
  return _69_
end
local last_exception = eval_str_fn("*e")
local result_1 = eval_str_fn("*1")
local result_2 = eval_str_fn("*2")
local result_3 = eval_str_fn("*3")
local view_tap = eval_str_fn("(conjure.internal/dump-tap-queue!)")
local function view_source()
  local function _70_()
    local word = a.get(extract.word(), "content")
    if not a["empty?"](word) then
      log.append({("; source (word): " .. word)}, {["break?"] = true})
      require_ns("clojure.repl")
      local function _71_(_241)
        return ui["display-result"](_241, {["raw-out?"] = true, ["ignore-nil?"] = true})
      end
      return eval_str({code = ("(clojure.repl/source " .. word .. ")"), context = extract.context(), cb = _71_})
    else
      return nil
    end
  end
  return try_ensure_conn(_70_)
end
local function eval_macro_expand(expander)
  local function _73_()
    local form = a.get(extract.form({}), "content")
    if not a["empty?"](form) then
      log.append({("; " .. expander .. " (form): " .. form)}, {["break?"] = true})
      local _74_
      if ("clojure.walk/macroexpand-all" == expander) then
        _74_ = "(require 'clojure.walk) "
      else
        _74_ = ""
      end
      local function _76_(_241)
        return ui["display-result"](_241, {["raw-out?"] = true, ["ignore-nil?"] = true})
      end
      return eval_str({code = (_74_ .. "(" .. expander .. " '" .. form .. ")"), context = extract.context(), cb = _76_})
    else
      return nil
    end
  end
  return try_ensure_conn(_73_)
end
local function macro_expand_1()
  return eval_macro_expand("macroexpand-1")
end
local function macro_expand()
  return eval_macro_expand("macroexpand")
end
local function macro_expand_all()
  return eval_macro_expand("clojure.walk/macroexpand-all")
end
local function clone_current_session()
  local function _78_()
    local function _79_(conn)
      return server["enrich-session-id"](a.get(conn, "session"), server["clone-session"])
    end
    return server["with-conn-or-warn"](_79_)
  end
  return try_ensure_conn(_78_)
end
local function clone_fresh_session()
  local function _80_()
    local function _81_(conn)
      return server["clone-session"]()
    end
    return server["with-conn-or-warn"](_81_)
  end
  return try_ensure_conn(_80_)
end
local function close_current_session()
  local function _82_()
    local function _83_(conn)
      local function _84_(sess)
        a.assoc(conn, "session", nil)
        log.append({("; Closed current session: " .. sess.str())}, {["break?"] = true})
        local function _85_()
          return server["assume-or-create-session"]()
        end
        return server["close-session"](sess, _85_)
      end
      return server["enrich-session-id"](a.get(conn, "session"), _84_)
    end
    return server["with-conn-or-warn"](_83_)
  end
  return try_ensure_conn(_82_)
end
local function display_sessions(cb)
  local function _86_()
    local function _87_(sessions)
      return ui["display-sessions"](sessions, cb)
    end
    return server["with-sessions"](_87_)
  end
  return try_ensure_conn(_86_)
end
local function close_all_sessions()
  local function _88_()
    local function _89_(sessions)
      a["run!"](server["close-session"], sessions)
      log.append({("; Closed all sessions (" .. a.count(sessions) .. ")")}, {["break?"] = true})
      return server["clone-session"]()
    end
    return server["with-sessions"](_89_)
  end
  return try_ensure_conn(_88_)
end
local function cycle_session(f)
  local function _90_()
    local function _91_(conn)
      local function _92_(sessions)
        if (1 == a.count(sessions)) then
          return log.append({"; No other sessions"}, {["break?"] = true})
        else
          local session = a.get(conn, "session")
          local function _93_(_241)
            return f(session, _241)
          end
          return server["assume-session"](ll.val(ll["until"](_93_, ll.cycle(ll.create(sessions)))))
        end
      end
      return server["with-sessions"](_92_)
    end
    return server["with-conn-or-warn"](_91_)
  end
  return try_ensure_conn(_90_)
end
local function next_session()
  local function _95_(current, node)
    return (current == a.get(ll.val(ll.prev(node)), "id"))
  end
  return cycle_session(_95_)
end
local function prev_session()
  local function _96_(current, node)
    return (current == a.get(ll.val(ll.next(node)), "id"))
  end
  return cycle_session(_96_)
end
local function select_session_interactive()
  local function _97_()
    local function _98_(sessions)
      if (1 == a.count(sessions)) then
        return log.append({"; No other sessions"}, {["break?"] = true})
      else
        local function _99_()
          nvim.ex.redraw_()
          local n = nvim.fn.str2nr(extract.prompt("Session number: "))
          if ((1 <= n) and (n <= a.count(sessions))) then
            return server["assume-session"](a.get(sessions, n))
          else
            return log.append({"; Invalid session number."})
          end
        end
        return ui["display-sessions"](sessions, _99_)
      end
    end
    return server["with-sessions"](_98_)
  end
  return try_ensure_conn(_97_)
end
local test_runners = {clojure = {namespace = "clojure.test", ["all-fn"] = "run-all-tests", ["ns-fn"] = "run-tests", ["single-fn"] = "test-vars", ["default-call-suffix"] = "", ["name-prefix"] = "[(resolve '", ["name-suffix"] = ")]"}, clojurescript = {namespace = "cljs.test", ["all-fn"] = "run-all-tests", ["ns-fn"] = "run-tests", ["single-fn"] = "test-vars", ["default-call-suffix"] = "", ["name-prefix"] = "[(resolve '", ["name-suffix"] = ")]"}, kaocha = {namespace = "kaocha.repl", ["all-fn"] = "run-all", ["ns-fn"] = "run", ["single-fn"] = "run", ["default-call-suffix"] = "{:kaocha/color? false}", ["name-prefix"] = "#'", ["name-suffix"] = ""}}
local function test_cfg(k)
  local runner = cfg({"test", "runner"})
  return (a["get-in"](test_runners, {runner, k}) or error(str.join({"No test-runners configuration for ", runner, " / ", k})))
end
local function require_test_runner()
  return require_ns(test_cfg("namespace"))
end
local function test_runner_code(fn_config_name, ...)
  return ("(" .. str.join(" ", {(test_cfg("namespace") .. "/" .. test_cfg((fn_config_name .. "-fn"))), ...}) .. (cfg({"test", "call_suffix"}) or test_cfg("default-call-suffix")) .. ")")
end
local function run_all_tests()
  local function _102_()
    log.append({"; run-all-tests"}, {["break?"] = true})
    require_test_runner()
    local function _103_(_241)
      return ui["display-result"](_241, {["simple-out?"] = true, ["raw-out?"] = cfg({"test", "raw_out"}), ["ignore-nil?"] = true})
    end
    return server.eval({code = test_runner_code("all")}, _103_)
  end
  return try_ensure_conn(_102_)
end
local function run_ns_tests(ns)
  local function _104_()
    if ns then
      log.append({("; run-ns-tests: " .. ns)}, {["break?"] = true})
      require_test_runner()
      local function _105_(_241)
        return ui["display-result"](_241, {["simple-out?"] = true, ["raw-out?"] = cfg({"test", "raw_out"}), ["ignore-nil?"] = true})
      end
      return server.eval({code = test_runner_code("ns", ("'" .. ns))}, _105_)
    else
      return nil
    end
  end
  return try_ensure_conn(_104_)
end
local function run_current_ns_tests()
  return run_ns_tests(extract.context())
end
local function run_alternate_ns_tests()
  local current_ns = extract.context()
  local function _107_()
    if text["ends-with"](current_ns, "-test") then
      return current_ns
    else
      return (current_ns .. "-test")
    end
  end
  return run_ns_tests(_107_())
end
local function extract_test_name_from_form(form)
  local seen_deftest_3f = false
  local function _108_(part)
    local function _109_(config_current_form_name)
      return text["ends-with"](part, config_current_form_name)
    end
    if a.some(_109_, cfg({"test", "current_form_names"})) then
      seen_deftest_3f = true
      return false
    elseif seen_deftest_3f then
      return part
    else
      return nil
    end
  end
  return a.some(_108_, str.split(parse["strip-meta"](form), "%s+"))
end
local function run_current_test()
  local function _111_()
    local form = extract.form({["root?"] = true})
    if form then
      local test_name = extract_test_name_from_form(form.content)
      if test_name then
        log.append({("; run-current-test: " .. test_name)}, {["break?"] = true})
        require_test_runner()
        local function _112_(msgs)
          if ((2 == a.count(msgs)) and ("nil" == a.get(a.first(msgs), "value"))) then
            return log.append({"; Success!"})
          else
            local function _113_(_241)
              return ui["display-result"](_241, {["simple-out?"] = true, ["raw-out?"] = cfg({"test", "raw_out"}), ["ignore-nil?"] = true})
            end
            return a["run!"](_113_, msgs)
          end
        end
        return server.eval({code = test_runner_code("single", (test_cfg("name-prefix") .. test_name .. test_cfg("name-suffix"))), context = extract.context()}, nrepl["with-all-msgs-fn"](_112_))
      else
        return nil
      end
    else
      return nil
    end
  end
  return try_ensure_conn(_111_)
end
local function refresh_impl(op)
  local function _117_(conn)
    local function _118_(msg)
      if msg.reloading then
        return log.append(msg.reloading)
      elseif msg.error then
        return log.append({str.join(" ", {"; Error while reloading", msg["error-ns"]})})
      elseif msg.status.ok then
        return log.append({"; Refresh complete"})
      elseif msg.status.done then
        return nil
      else
        return ui["display-result"](msg)
      end
    end
    return server.send(a.merge({op = op, session = conn.session, after = cfg({"refresh", "after"}), before = cfg({"refresh", "before"}), dirs = cfg({"refresh", "dirs"})}), _118_)
  end
  return server["with-conn-and-ops-or-warn"]({op}, _117_)
end
local function use_clj_reload_backend_3f()
  return (cfg({"refresh", "backend"}) == "clj-reload")
end
local function refresh_changed()
  local use_clj_reload_3f = use_clj_reload_backend_3f()
  local function _120_()
    local _121_
    if use_clj_reload_3f then
      _121_ = "clj-reload"
    else
      _121_ = "tools.namespace"
    end
    log.append({str.join({"; Refreshing changed namespaces using '", _121_, "'"})}, {["break?"] = true})
    local function _123_()
      if use_clj_reload_3f then
        return "cider.clj-reload/reload"
      else
        return "refresh"
      end
    end
    return refresh_impl(_123_())
  end
  return try_ensure_conn(_120_)
end
local function refresh_all()
  local use_clj_reload_3f = use_clj_reload_backend_3f()
  local function _124_()
    local _125_
    if use_clj_reload_3f then
      _125_ = "clj-reload"
    else
      _125_ = "tools.namespace"
    end
    log.append({str.join({"; Refreshing all namespaces using '", _125_, "'"})}, {["break?"] = true})
    local function _127_()
      if use_clj_reload_3f then
        return "cider.clj-reload/reload-all"
      else
        return "refresh-all"
      end
    end
    return refresh_impl(_127_())
  end
  return try_ensure_conn(_124_)
end
local function refresh_clear()
  local use_clj_reload_3f = use_clj_reload_backend_3f()
  local function _128_()
    local _129_
    if use_clj_reload_3f then
      _129_ = "clj-reload"
    else
      _129_ = "tools.namespace"
    end
    log.append({str.join({"; Clearning reload cache using '", _129_, "'"})}, {["break?"] = true})
    local function _131_(conn)
      local _132_
      if use_clj_reload_3f then
        _132_ = "cider.clj-reload/reload-clear"
      else
        _132_ = "refresh-clear"
      end
      local function _134_(msgs)
        return log.append({"; Clearing complete"})
      end
      return server.send({op = _132_, session = conn.session}, nrepl["with-all-msgs-fn"](_134_))
    end
    return server["with-conn-and-ops-or-warn"]({"refresh-clear"}, _131_)
  end
  return try_ensure_conn(_128_)
end
local function shadow_select(build)
  local function _135_()
    local function _136_(conn)
      log.append({("; shadow-cljs (select): " .. build)}, {["break?"] = true})
      server.eval({code = ("#?(:clj (shadow.cljs.devtools.api/nrepl-select :" .. build .. ") :cljs :already-selected)")}, ui["display-result"])
      return passive_ns_require()
    end
    return server["with-conn-or-warn"](_136_)
  end
  return try_ensure_conn(_135_)
end
local function piggieback(code)
  local function _137_()
    local function _138_(conn)
      log.append({("; piggieback: " .. code)}, {["break?"] = true})
      require_ns("cider.piggieback")
      server.eval({code = ("(cider.piggieback/cljs-repl " .. code .. ")")}, ui["display-result"])
      return passive_ns_require()
    end
    return server["with-conn-or-warn"](_138_)
  end
  return try_ensure_conn(_137_)
end
local function clojure__3evim_completion(_139_)
  local word = _139_["candidate"]
  local kind = _139_["type"]
  local ns = _139_["ns"]
  local info = _139_["doc"]
  local arglists = _139_["arglists"]
  local function _140_()
    if arglists then
      return str.join(" ", arglists)
    else
      return nil
    end
  end
  local _141_
  if ("string" == type(info)) then
    _141_ = info
  else
    _141_ = nil
  end
  local _143_
  if not a["empty?"](kind) then
    _143_ = string.upper(string.sub(kind, 1, 1))
  else
    _143_ = nil
  end
  return {word = word, menu = str.join(" ", {ns, _140_()}), info = _141_, kind = _143_}
end
local function extract_completion_context(prefix)
  local root_form = extract.form({["root?"] = true})
  if root_form then
    local content = root_form["content"]
    local range = root_form["range"]
    local lines = text["split-lines"](content)
    local _let_145_ = nvim.win_get_cursor(0)
    local row = _let_145_[1]
    local col = _let_145_[2]
    local lrow = (row - a["get-in"](range, {"start", 1}))
    local line_index = a.inc(lrow)
    local lcol
    if (lrow == 0) then
      lcol = (col - a["get-in"](range, {"start", 2}))
    else
      lcol = col
    end
    local original = a.get(lines, line_index)
    local spliced = (string.sub(original, 1, lcol) .. "__prefix__" .. string.sub(original, a.inc(lcol)))
    return str.join("\n", a.assoc(lines, line_index, spliced))
  else
    return nil
  end
end
local function enhanced_cljs_completion_3f()
  return cfg({"completion", "cljs", "use_suitable"})
end
local function completions(opts)
  local function _148_(conn, ops)
    local _149_
    if ops.complete then
      local _150_
      if cfg({"completion", "with_context"}) then
        _150_ = extract_completion_context(opts.prefix)
      else
        _150_ = nil
      end
      local _152_
      if enhanced_cljs_completion_3f() then
        _152_ = "t"
      else
        _152_ = nil
      end
      _149_ = {op = "complete", session = conn.session, ns = opts.context, symbol = opts.prefix, context = _150_, ["extra-metadata"] = {"arglists", "doc"}, ["enhanced-cljs-completion?"] = _152_}
    elseif ops.completions then
      _149_ = {op = "completions", session = conn.session, ns = opts.context, prefix = opts.prefix}
    else
      _149_ = nil
    end
    local function _155_(msgs)
      return opts.cb(a.map(clojure__3evim_completion, a.get(a.last(msgs), "completions")))
    end
    return server.send(_149_, nrepl["with-all-msgs-fn"](_155_))
  end
  return server["with-conn-and-ops-or-warn"]({"complete", "completions"}, _148_, {["silent?"] = true, ["else"] = opts.cb})
end
local function out_subscribe()
  try_ensure_conn()
  log.append({"; Subscribing to out"}, {["break?"] = true})
  local function _156_(conn)
    return server.send({op = "out-subscribe"})
  end
  return server["with-conn-and-ops-or-warn"]({"out-subscribe"}, _156_)
end
local function out_unsubscribe()
  try_ensure_conn()
  log.append({"; Unsubscribing from out"}, {["break?"] = true})
  local function _157_(conn)
    return server.send({op = "out-unsubscribe"})
  end
  return server["with-conn-and-ops-or-warn"]({"out-unsubscribe"}, _157_)
end
return {["clone-current-session"] = clone_current_session, ["clone-fresh-session"] = clone_fresh_session, ["close-all-sessions"] = close_all_sessions, ["close-current-session"] = close_current_session, completions = completions, ["connect-host-port"] = connect_host_port, ["connect-port-file"] = connect_port_file, ["def-str"] = def_str, ["display-sessions"] = display_sessions, ["doc-str"] = doc_str, ["escape-backslashes"] = escape_backslashes, ["eval-file"] = eval_file, ["eval-str"] = eval_str, ["extract-test-name-from-form"] = extract_test_name_from_form, interrupt = interrupt, ["last-exception"] = last_exception, ["next-session"] = next_session, ["out-subscribe"] = out_subscribe, ["out-unsubscribe"] = out_unsubscribe, ["passive-ns-require"] = passive_ns_require, piggieback = piggieback, ["prev-session"] = prev_session, ["refresh-all"] = refresh_all, ["refresh-changed"] = refresh_changed, ["refresh-clear"] = refresh_clear, ["result-1"] = result_1, ["result-2"] = result_2, ["result-3"] = result_3, ["run-all-tests"] = run_all_tests, ["run-alternate-ns-tests"] = run_alternate_ns_tests, ["run-current-ns-tests"] = run_current_ns_tests, ["run-current-test"] = run_current_test, ["select-session-interactive"] = select_session_interactive, ["shadow-select"] = shadow_select, ["test-runners"] = test_runners, ["view-source"] = view_source, ["view-tap"] = view_tap, ["macro-expand-1"] = macro_expand_1, ["macro-expand"] = macro_expand, ["macro-expand-all"] = macro_expand_all}
