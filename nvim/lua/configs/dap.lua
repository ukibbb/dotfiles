local M = {}

-- dap-ui floats (<leader>de, <leader>df…) never grow past this share of the screen.
local float_share = { width = 0.9, height = 0.8 }

-- The text indented by jq, or nil when it is not valid JSON.
local function indented_json(text)
  local pretty = vim.fn.system({ "jq", "." }, text)
  if vim.v.shell_error == 0 then
    return vim.trim(pretty)
  end
end

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
        -- The console only shows a program that nvim-dap starts in a terminal, so the REPL gets most of the width.
        elements = {
          { id = "repl", size = 0.7 },
          { id = "console", size = 0.3 },
        },
        position = "bottom",
        size = 10,
      },
    },
    floating = { border = "rounded", max_width = float_share.width, max_height = float_share.height },
  }

  -- Long REPL results fold onto the next line instead of scrolling the window sideways.
  -- wrap belongs to the window, and dap-ui turns it off right after it shows the REPL (pane or float), so set it a tick later.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("DapReplWrap", { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].filetype ~= "dap-repl" then
        return
      end
      vim.schedule(function()
        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
          vim.wo[win].wrap = true
          vim.wo[win].linebreak = true
        end
      end)
    end,
  })

  require("nvim-dap-virtual-text").setup {
    -- Long values (objects, arrays, SQL strings) are cut so they don't push the code off screen.
    display_callback = function(variable)
      local value = variable.value:gsub("%s+", " ")
      -- Count characters, not bytes, so Polish letters are never cut in half.
      if vim.fn.strchars(value) > 40 then
        value = vim.fn.strcharpart(value, 0, 40) .. "…"
      end
      return " = " .. value
    end,
  }

  dap.listeners.on_session.dapui_config = function(_, session)
    if session then
      dapui.open()
    else
      dapui.close()
    end
  end

  -- A JSON string typed in the REPL prints indented, so JSON.stringify(x) reads like JSON.stringify(x, null, 2).
  -- Runs before the REPL prints the response. Anything jq cannot parse prints unchanged.
  dap.listeners.before.evaluate.pretty_json_in_repl = function(_, err, response, request)
    if err or request.context ~= "repl" or response.variablesReference ~= 0 or vim.fn.executable "jq" == 0 then
      return
    end
    -- Adapters wrap a string result in one quote mark (' " or `).
    local quote, text = response.result:match "^(['\"`])([%[{].*)%1$"
    if not quote then
      return
    end
    local pretty = indented_json(text)
      -- Some results come escaped like a source literal (doubled backslashes, \' or \`), so undo that once.
      or indented_json((text:gsub("\\([\\'`])", "%1")))
    if pretty then
      response.result = pretty
      -- debugpy marks strings rawString, and the REPL then draws them as one value with visible \n.
      response.presentationHint = nil
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
    {
      -- Joins a Node server started with --inspect (e.g. `next dev --inspect`), which listens on port 9229.
      type = "pwa-node",
      request = "attach",
      name = "Attach to Next server (port 9229)",
      port = 9229,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
    },
  }

  for _, filetype in ipairs(js_filetypes) do
    dap.configurations[filetype] = vim.deepcopy(js_configurations)
  end
end

-- Opens one dap-ui pane as a large centered float and moves the cursor into it.
function M.open_pane_float(element)
  require("dapui").float_element(element, {
    enter = true,
    position = "center",
    -- dap-ui keeps 2 cells of each maximum for the border.
    width = math.floor(vim.o.columns * float_share.width) - 2,
    height = math.floor(vim.o.lines * float_share.height) - 2,
  })
end

return M
