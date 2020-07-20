local _0_0 = nil
do
  local name_0_ = "conjure.client"
  local loaded_0_ = package.loaded[name_0_]
  local module_0_ = nil
  if ("table" == type(loaded_0_)) then
    module_0_ = loaded_0_
  else
    module_0_ = {}
  end
  module_0_["aniseed/module"] = name_0_
  module_0_["aniseed/locals"] = (module_0_["aniseed/locals"] or {})
  module_0_["aniseed/local-fns"] = (module_0_["aniseed/local-fns"] or {})
  package.loaded[name_0_] = module_0_
  _0_0 = module_0_
end
local function _1_(...)
  _0_0["aniseed/local-fns"] = {require = {a = "conjure.aniseed.core", config = "conjure.config", dyn = "conjure.dynamic", fennel = "conjure.aniseed.fennel", nvim = "conjure.aniseed.nvim"}}
  return {require("conjure.aniseed.core"), require("conjure.config"), require("conjure.dynamic"), require("conjure.aniseed.fennel"), require("conjure.aniseed.nvim")}
end
local _2_ = _1_(...)
local a = _2_[1]
local config = _2_[2]
local dyn = _2_[3]
local fennel = _2_[4]
local nvim = _2_[5]
do local _ = ({nil, _0_0, {{}, nil}})[2] end
local loaded = nil
do
  local v_0_ = (_0_0["aniseed/locals"].loaded or {})
  _0_0["aniseed/locals"]["loaded"] = v_0_
  loaded = v_0_
end
local client_states = nil
do
  local v_0_ = (_0_0["aniseed/locals"]["client-states"] or {})
  _0_0["aniseed/locals"]["client-states"] = v_0_
  client_states = v_0_
end
local state = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function state0(...)
      return a["get-in"](client_states, {...})
    end
    v_0_0 = state0
    _0_0["state"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["state"] = v_0_
  state = v_0_
end
local state_fn = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function state_fn0(...)
      local prefix = {...}
      local function _3_(...)
        local ks = a.concat(prefix, {...})
        return state(unpack(ks))
      end
      return _3_
    end
    v_0_0 = state_fn0
    _0_0["state-fn"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["state-fn"] = v_0_
  state_fn = v_0_
end
local init_state = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function init_state0(ks, default)
      if not a["get-in"](client_states, ks) then
        return a["assoc-in"](client_states, ks, default)
      end
    end
    v_0_0 = init_state0
    _0_0["init-state"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["init-state"] = v_0_
  init_state = v_0_
end
local load_module = nil
do
  local v_0_ = nil
  local function load_module0(name)
    local ok_3f, result = nil, nil
    local function _3_()
      return require(name)
    end
    ok_3f, result = xpcall(_3_, fennel.traceback)
    if a["nil?"](a.get(loaded, name)) then
      a.assoc(loaded, name, true)
      if result["on-load"] then
        vim.schedule(result["on-load"])
      end
    end
    if ok_3f then
      return result
    else
      return error(result)
    end
  end
  v_0_ = load_module0
  _0_0["aniseed/locals"]["load-module"] = v_0_
  load_module = v_0_
end
local filetype = nil
do
  local v_0_ = nil
  local function _3_()
    return nvim.bo.filetype
  end
  v_0_ = dyn.new(_3_)
  _0_0["aniseed/locals"]["filetype"] = v_0_
  filetype = v_0_
end
local with_filetype = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function with_filetype0(ft, f, ...)
      local function _3_()
        return ft
      end
      return dyn.bind({[filetype] = _3_}, f, ...)
    end
    v_0_0 = with_filetype0
    _0_0["with-filetype"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["with-filetype"] = v_0_
  with_filetype = v_0_
end
local current_client_module_name = nil
do
  local v_0_ = nil
  local function current_client_module_name0()
    return a.get(config["get-in"]({"filetype_client"}), filetype())
  end
  v_0_ = current_client_module_name0
  _0_0["aniseed/locals"]["current-client-module-name"] = v_0_
  current_client_module_name = v_0_
end
local current = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function current0()
      local ft = filetype()
      local mod_name = current_client_module_name()
      if mod_name then
        return load_module(mod_name)
      else
        return error(("No Conjure client for filetype: '" .. ft .. "'"))
      end
    end
    v_0_0 = current0
    _0_0["current"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["current"] = v_0_
  current = v_0_
end
local get = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function get0(...)
      return a["get-in"](current(), {...})
    end
    v_0_0 = get0
    _0_0["get"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["get"] = v_0_
  get = v_0_
end
local call = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function call0(fn_name, ...)
      local f = get(fn_name)
      if f then
        return f(...)
      else
        return error(("Conjure client '" .. current_client_module_name() .. "' doesn't support function: " .. fn_name))
      end
    end
    v_0_0 = call0
    _0_0["call"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["call"] = v_0_
  call = v_0_
end
local optional_call = nil
do
  local v_0_ = nil
  do
    local v_0_0 = nil
    local function optional_call0(fn_name, ...)
      local f = get(fn_name)
      if f then
        return f(...)
      end
    end
    v_0_0 = optional_call0
    _0_0["optional-call"] = v_0_0
    v_0_ = v_0_0
  end
  _0_0["aniseed/locals"]["optional-call"] = v_0_
  optional_call = v_0_
end
return nil