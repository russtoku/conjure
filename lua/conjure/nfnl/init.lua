-- [nfnl] fnl/nfnl/init.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local callback = autoload("conjure.nfnl.callback")
local minimum_neovim_version = "0.9.0"
if vim then
  if (0 == vim.fn.has(("nvim-" .. minimum_neovim_version))) then
    error(("nfnl requires Neovim > v" .. minimum_neovim_version))
  else
  end
  vim.api.nvim_create_autocmd({"Filetype"}, {group = vim.api.nvim_create_augroup("nfnl-setup", {}), pattern = "fennel", callback = callback["fennel-filetype-callback"]})
  if ("fennel" == vim.o.filetype) then
    callback["fennel-filetype-callback"]({file = vim.fn.expand("%"), buf = vim.api.nvim_get_current_buf()})
  else
  end
else
end
local function setup(opts)
  if opts then
    vim.g["nfnl#compile_on_write"] = opts.compile_on_write
    return nil
  else
    return nil
  end
end
return {setup = setup}
