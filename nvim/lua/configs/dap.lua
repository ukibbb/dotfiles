local M = {}

function M.setup()
  local dap = require "dap"
  local dapui = require "dapui"

  dapui.setup {
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.4 },
          { id = "stacks", size = 0.25 },
          { id = "breakpoints", size = 0.2 },
          { id = "watches", size = 0.15 },
        },
        position = "right",
        size = 40,
      },
      {
        elements = { "repl", "console" },
        position = "bottom",
        size = 10,
      },
    },
    floating = { border = "rounded" },
  }

  require("nvim-dap-virtual-text").setup {
    commented = true,
  }

  dap.listeners.on_session.dapui_config = function(_, session)
    if session then
      dapui.open()
    else
      dapui.close()
    end
  end

  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

  local signs = {
    DapBreakpoint = { text = "", texthl = "DiagnosticError" },
    DapBreakpointCondition = { text = "", texthl = "DiagnosticWarn" },
    DapBreakpointRejected = { text = "", texthl = "DiagnosticError" },
    DapLogPoint = { text = "󰛿", texthl = "DiagnosticInfo" },
    DapStopped = { text = "", texthl = "DiagnosticOk", linehl = "DapStoppedLine" },
  }

  for name, sign in pairs(signs) do
    vim.fn.sign_define(name, sign)
  end

  require("dap-python").setup "debugpy-adapter"
  require("dap-go").setup()

  local function js_adapter()
    return {
      type = "server",
      host = "127.0.0.1",
      port = "${port}",
      executable = {
        command = "js-debug-adapter",
        args = { "${port}", "127.0.0.1" },
      },
    }
  end

  dap.adapters["pwa-node"] = js_adapter()
  dap.adapters["pwa-chrome"] = js_adapter()

  local js_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }
  local js_configurations = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file with Node",
      program = "${file}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to Node process",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
    },
    {
      type = "pwa-chrome",
      request = "launch",
      name = "Launch Chrome",
      url = function()
        local url = vim.fn.input("URL: ", "http://localhost:3000")
        return url ~= "" and url or dap.ABORT
      end,
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
    },
    {
      type = "pwa-chrome",
      request = "attach",
      name = "Attach to Chrome",
      port = function()
        return tonumber(vim.fn.input("Chrome debug port: ", "9222")) or 9222
      end,
      urlFilter = "*",
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
    },
  }

  local vscode = require "dap.ext.vscode"
  vscode.type_to_filetypes["pwa-node"] = js_filetypes
  vscode.type_to_filetypes["pwa-chrome"] = js_filetypes

  for _, filetype in ipairs(js_filetypes) do
    dap.configurations[filetype] = vim.deepcopy(js_configurations)
  end
end

return M
