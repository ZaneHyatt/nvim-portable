-- =========================
--  init.lua — starter kit (fixed)
-- =========================

-- 0) Leader keys (must come first)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable netrw (nvim-tree recommendation)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1


-- 1) Bootstrap lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Ensure Mason's bin is on PATH so null-ls can find tools
vim.env.PATH = table.concat({
  vim.fn.stdpath("data") .. "/mason/bin",
  vim.env.PATH or ""
}, ":")

-- 2) Sensible, portable defaults
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.updatetime = 250

-- Tabs/indent (set these how you like)
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- 3) Plugins (no duplicates)
require("lazy").setup({

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", tag = "0.1.6", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Formatting/Linting bridge (aka null-ls)
  {
    "nvimtools/none-ls.nvim",
    main = "null-ls",                    -- load when requiring "null-ls"
    cmd = { "NullLsInfo", "NullLsLog" }, -- also load on these commands
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Tool auto-installer for CLI tools
  { "WhoIsSethDaniel/mason-tool-installer.nvim" },

  -- Completion engine + sources + snippets
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
  },

  -- Detect tabstop/shiftwidth automatically
  { "tpope/vim-sleuth" },

  -- Treesitter (syntax/indent)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "query",
        "python",
        "javascript", "typescript", "tsx",
        "json", "yaml", "html", "css", "bash", "markdown"
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- LSP: Mason (installer) + bridge + configs
  { "williamboman/mason.nvim", build = ":MasonUpdate", config = true },
  { "williamboman/mason-lspconfig.nvim", dependencies = { "williamboman/mason.nvim" } },
  { "neovim/nvim-lspconfig" },

  { "nvim-lualine/lualine.nvim" },

  {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional but nice
  },

  {
  "lewis6991/gitsigns.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  },

  { "nyoom-engineering/oxocarbon.nvim", lazy = false, priority = 1000 },
  { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
  { "EdenEast/nightfox.nvim", lazy = false, priority = 1000 },

  { "luukvbaal/statuscol.nvim" },
  { "kevinhwang91/nvim-ufo", dependencies = { "kevinhwang91/promise-async" } }, -- optional but nice

  { "akinsho/toggleterm.nvim", version = "*"},

}, {
  ui = { border = "rounded" },
})

-- =========================
--  Colorschemes
-- =========================

-- Pick your default here:
local default_theme = "oxocarbon"        -- try: "oxocarbon", "kanagawa-dragon", "carbonfox"

-- Configure each theme (only runs if you pick it)
if default_theme == "kanagawa-dragon" then
  require("kanagawa").setup({
    theme = "dragon",
    compile = true,
    dimInactive = true,
    background = { dark = "dragon" },
    colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
  })
elseif default_theme == "carbonfox" then
  require("nightfox").setup({ options = { transparent = false } })
end

-- Apply
vim.opt.background = "dark"
vim.cmd.colorscheme(default_theme)

-- Cycle through installed themes with <leader>ut
local themes = { "oxocarbon", "kanagawa-dragon", "carbonfox" }
local i = vim.fn.index(themes, default_theme) + 1
vim.keymap.set("n", "<leader>ut", function()
  i = (i % #themes) + 1
  vim.cmd.colorscheme(themes[i])
  print("Theme → " .. themes[i])
end, { desc = "Cycle themes" })


vim.cmd([[
  hi Normal guibg=NONE ctermbg=NONE
  hi NormalNC guibg=NONE ctermbg=NONE
]])

vim.cmd([[
  hi DiagnosticError guifg=#ff5555
  hi DiagnosticWarn  guifg=#f1fa8c
  hi DiagnosticInfo  guifg=#8be9fd
  hi DiagnosticHint  guifg=#50fa7b
]])



-- ── Lualine ─────────────────────────────────────────────────────────────────
local ok_l, lualine = pcall(require, "lualine")
if ok_l then
  lualine.setup({
    options = {
      theme = "auto",
      section_separators = "",
      component_separators = "",
      globalstatus = true,
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff" },
      lualine_c = { { "filename", path = 1 } }, -- path=1 shows relative path
      lualine_x = { "diagnostics", "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  })
end


-- 4) Mason & tools
require("mason").setup({})
require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "lua_ls", "ts_ls", "ruff" }, -- ruff (new name), not ruff_lsp
  automatic_installation = true,
})

-- Auto-install CLI tools we actually use (no ESLint here on purpose)
require("mason-tool-installer").setup({
  ensure_installed = {
    "black",     -- Python formatter
    "prettierd", -- JS/TS/JSON/CSS/Markdown formatter (daemon)
    -- (Ruff LSP handles diagnostics; no ruff builtin via null-ls)
  },
  run_on_start = true,
  auto_update = false,
})

-- 5) LSP configuration
local lspconfig = require("lspconfig")
local util = require("lspconfig.util")

-- Capabilities (enhanced for nvim-cmp)
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp_lsp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- Keymaps when an LSP attaches to a buffer
local on_attach = function(client, bufnr)
  -- Prefer null-ls for JS/TS formatting (disable ts_ls formatting)
  if client.name == "ts_ls" then
    client.server_capabilities.documentFormattingProvider = false
  end

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map("n", "gd", vim.lsp.buf.definition,            "Goto Definition")
  map("n", "gr", vim.lsp.buf.references,            "References")
  map("n", "K",  vim.lsp.buf.hover,                 "Hover")
  map("n", "<leader>rn", vim.lsp.buf.rename,        "Rename Symbol")
  map("n", "<leader>ca", vim.lsp.buf.code_action,   "Code Action")
  map("n", "gl",  vim.diagnostic.open_float, "Line Diagnostics")
  map("n", "[d", vim.diagnostic.goto_prev,          "Prev Diagnostic")
  map("n", "]d", vim.diagnostic.goto_next,          "Next Diagnostic")
end

-- Helper to start a server
local function start(server, extra_opts)
  local srv = lspconfig[server]
  if not srv then return end
  local opts = vim.tbl_deep_extend("force", { capabilities = capabilities, on_attach = on_attach }, extra_opts or {})
  if type(srv) == "table" and type(srv.setup) == "function" then srv.setup(opts)
  elseif type(srv) == "function" then srv(opts) end
end

-- Lua (Neovim config editing)
start("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

-- Python (Pyright) with useful defaults
start("pyright", {
  root_dir = function(fname)
    return util.root_pattern(
      "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "pyrightconfig.json", ".git"
    )(fname) or util.path.dirname(fname)
  end,
  settings = {
    python = {
      analysis = {
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
      },
    },
  },
})

-- Ruff (LSP) for Python diagnostics/quickfixes
start("ruff", {
  init_options = { settings = { args = {} } },
})

-- TypeScript / JavaScript
start("ts_ls")

-- 6) Snippets + Completion
local ok_snip, luasnip = pcall(require, "luasnip")
if ok_snip then
  require("luasnip.loaders.from_vscode").lazy_load()
  luasnip.config.set_config({ history = true, updateevents = "TextChanged,TextChangedI", enable_autosnippets = false })
end

local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  cmp.setup({
    snippet = {
      expand = function(args) if ok_snip then luasnip.lsp_expand(args.body) end end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"]     = cmp.mapping.abort(),
      ["<CR>"]      = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_next_item()
        elseif ok_snip and luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
        else fallback() end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_prev_item()
        elseif ok_snip and luasnip.jumpable(-1) then luasnip.jump(-1)
        else fallback() end
      end, { "i", "s" }),
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "luasnip" },
    }, {
      { name = "path" },
      { name = "buffer" },
    }),
    formatting = {
      fields = { "abbr", "menu", "kind" },
      format = function(entry, vim_item)
        local menu = { nvim_lsp = "[LSP]", luasnip = "[Snip]", buffer = "[Buf]", path = "[Path]" }
        vim_item.menu = menu[entry.source.name]
        return vim_item
      end,
    },
    experimental = { ghost_text = true },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
  })
end

-- 7) null-ls (formatting only — NO ESLint, NO Ruff)
local ok_null, null = pcall(require, "null-ls")
if ok_null then
  null.setup({
    sources = {
      -- Python
      null.builtins.formatting.black,

      -- JS/TS/web: Prettier only
      null.builtins.formatting.prettierd.with({
        filetypes = {
          "javascript","javascriptreact","typescript","typescriptreact",
          "json","jsonc","css","scss","html","markdown",
        },
      }),
    },
  })
end

-- 8) Format on save using null-ls (Black/Prettier)
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    vim.lsp.buf.format({
      bufnr = args.buf,
      async = false,
      timeout_ms = 3000,
      filter = function(client)
        return client.name == "none-ls" or client.name == "null-ls"
      end,
    })
  end,
})

-- ── GitSigns ────────────────────────────────────────────────────────────────
local ok_gs, gitsigns = pcall(require, "gitsigns")
if ok_gs then
  gitsigns.setup({
    signs = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "契" },
      topdelete    = { text = "契" },
      changedelete = { text = "▎" },
    },
    current_line_blame = true, -- show git blame for current line
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(gs.next_hunk)
      end, "Next Hunk")

      map("n", "[c", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(gs.prev_hunk)
      end, "Prev Hunk")

      -- Actions
      map("n", "<leader>hs", gs.stage_hunk, "Stage Hunk")
      map("n", "<leader>hr", gs.reset_hunk, "Reset Hunk")
      map("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
      map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
      map("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
      map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
    end,
  })
end

-- ── Folding UI & behavior (statuscol + ufo) ─────────────────────────────────
-- Always show a fold column and start with everything unfolded
vim.opt.foldcolumn = "1"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Nice fold glyphs in the gutter (needs a Nerd Font; see note below)
-- If your font doesn't show these, use the ASCII fallback below.
vim.opt.fillchars:append({
  fold = " ",
  foldopen = "",  -- v
  foldclose = "", -- >
  foldsep = " ",
})

-- Optional ASCII fallback if your font lacks the icons:
-- vim.opt.fillchars:append({ foldopen = "v", foldclose = ">" })

-- nvim-ufo: smarter folds (Treesitter first, indent fallback)
local ok_ufo, ufo = pcall(require, "ufo")
if ok_ufo then
  ufo.setup({
    provider_selector = function(_, _, _)
      return { "treesitter", "indent" }
    end,
  })

  -- Open all folds automatically when a file is read
  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
      pcall(ufo.openAllFolds)
    end,
  })

  -- Convenience keys
  vim.keymap.set("n", "zR", function() pcall(ufo.openAllFolds) end,  { desc = "Open all folds" })
  vim.keymap.set("n", "zM", function() pcall(ufo.closeAllFolds) end, { desc = "Close all folds" })
end

-- statuscol: clickable fold column + signs + line numbers
local ok_sc, statuscol = pcall(require, "statuscol")
if ok_sc then
  local builtin = require("statuscol.builtin")
  statuscol.setup({
    relculright = true,
    segments = {
      { text = { builtin.foldfunc }, click = "v:lua.ScFa" },   -- clickable fold icon
      { text = { "%s" } },                                     -- signs (LSP/Git)
      { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" }, -- line numbers
    },
  })
end

-- ── ToggleTerm ──────────────────────────────────────────────────────────────
local ok_tt, toggleterm = pcall(require, "toggleterm")
if ok_tt then
  toggleterm.setup({
    size = 14,
    open_mapping = [[<C-\>]],  -- Ctrl+\ to toggle the primary terminal
    direction = "horizontal",  -- "horizontal" | "vertical" | "float"
    shade_terminals = true,
    persist_size = true,
    start_in_insert = true,
  })

  -- Extra toggles
  vim.keymap.set("n", "<leader>tv", function() require("toggleterm.terminal").Terminal:new({direction="vertical"}):toggle() end, {desc="Toggle vertical terminal"})
  vim.keymap.set("n", "<leader>tf", function() require("toggleterm.terminal").Terminal:new({direction="float"}):toggle() end,    {desc="Toggle floating terminal"})

-- Save & run current file in a floating terminal (auto-detect python)
vim.keymap.set("n", "<leader>rd", function()
  vim.cmd.write()
  local ft = vim.bo.filetype
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))

  local function py()
    -- Prefer project venv at .venv/bin/python
    if vim.fn.executable("./.venv/bin/python") == 1 then
      return "./.venv/bin/python " .. file
    elseif vim.fn.executable("python3") == 1 then
      return "python3 " .. file
    elseif vim.fn.executable("python") == 1 then
      return "python " .. file
    end
  end

  local cmd =
    (ft == "python" and py())
    or (ft == "javascript" and "node " .. file)
    or (ft == "typescript" and "tsx " .. file)
    or nil

  if not cmd then
    print("No runnable for filetype: " .. ft .. " (install python3/node/tsx or set up .venv)")
    return
  end

  local Terminal = require("toggleterm.terminal").Terminal
  Terminal:new({ cmd = cmd, direction = "float", close_on_exit = false }):toggle()
end, { desc = "Run current file (float)" })
end

-- ── Simple bottom terminal workflow ─────────────────────────────────────────
local ok_tt = pcall(require, "toggleterm")
if ok_tt then
  local Terminal = require("toggleterm.terminal").Terminal

  -- 1) A single bottom terminal we reuse (12 lines tall)
  local bottom_term = Terminal:new({
    direction = "horizontal",
    size = 12,
    close_on_exit = false,
    start_in_insert = true,
  })

  -- Toggle the bottom terminal (keeps your code visible)
  vim.keymap.set("n", "<leader>tt", function()
    bottom_term:toggle()
  end, { desc = "Toggle bottom terminal" })

  -- 2) Run current file IN the bottom terminal, keep cursor in code
  vim.keymap.set("n", "<leader>rr", function()
    vim.cmd.write()
    local file = vim.fn.expand("%:p")
    local ft   = vim.bo.filetype

    -- pick a command for the current filetype (extend as you like)
    local cmd
    if ft == "python" then
      if vim.fn.executable("./.venv/bin/python") == 1 then
        cmd = "./.venv/bin/python " .. vim.fn.shellescape(file)
      elseif vim.fn.executable("python3") == 1 then
        cmd = "python3 " .. vim.fn.shellescape(file)
      elseif vim.fn.executable("python") == 1 then
        cmd = "python " .. vim.fn.shellescape(file)
      else
        vim.notify("No python/python3 found in PATH", vim.log.levels.ERROR)
        return
      end
    elseif ft == "javascript" then
      cmd = "node " .. vim.fn.shellescape(file)
    elseif ft == "typescript" then
      cmd = "tsx " .. vim.fn.shellescape(file)  -- install tsx if needed
    else
      vim.notify("No runner configured for filetype: " .. ft, vim.log.levels.WARN)
      return
    end

    -- open the bottom terminal (if hidden), send the command, and stay in code window
    bottom_term:open()
    bottom_term:send("clear && " .. cmd .. "\r", true)  -- `true` = go back to previous window
  end, { desc = "Run current file in bottom terminal" })

  -- 3) Handy resize keys for the bottom pane
  vim.keymap.set("n", "<C-Down>", function() vim.cmd("resize -2") end, { desc = "Terminal shorter" })
  vim.keymap.set("n", "<C-Up>",   function() vim.cmd("resize +2") end, { desc = "Terminal taller" })
end





-- 9) Telescope setup + keymaps
local ok_t, telescope = pcall(require, "telescope")
if ok_t then
  telescope.setup({
    defaults = {
      prompt_prefix = "  ",
      selection_caret = "➜ ",
      sorting_strategy = "ascending",
      layout_config = { prompt_position = "top" },
    },
  })
  local tb = require("telescope.builtin")
  vim.keymap.set("n", "<leader>ff", tb.find_files, { desc = "Find files" })
  vim.keymap.set("n", "<leader>/",  tb.current_buffer_fuzzy_find, { desc = "Search current file (fuzzy)" })
  vim.keymap.set("n", "<leader>fg", tb.live_grep,  { desc = "Live grep (ripgrep)" })
  vim.keymap.set("n", "<leader>fb", tb.buffers,    { desc = "Buffers" })
  vim.keymap.set("n", "<leader>fh", tb.help_tags,  { desc = "Help tags" })
  vim.keymap.set("n", "<leader>fr", tb.resume,     { desc = "Resume last picker" })
end

-- ── nvim-tree ───────────────────────────────────────────────────────────────
local ok_tree, nvim_tree = pcall(require, "nvim-tree")
if ok_tree then
  nvim_tree.setup({
    -- auto-reload when files change on disk
    auto_reload_on_write = true,
    -- keep the tree synced with your current buffer
    update_focused_file = { enable = true, update_root = false },
    -- filters (hide junk, but keep helpful files visible)
    filters = {
      dotfiles = false,
      custom = { "^\\.git$", "^node_modules$", "^dist$" },
    },
    -- view options
    view = {
      width = 32,
      side = "left",
      signcolumn = "yes",
      preserve_window_proportions = true,
    },
    -- renderer: icons & git/status
    renderer = {
      group_empty = true,
      highlight_git = true,
      indent_markers = { enable = true },
      icons = {
        git_placement = "after",
        show = { file = true, folder = true, folder_arrow = true, git = true },
      },
    },
    -- git integration (shows M/A/D/U next to files)
    git = { enable = true, ignore = false, timeout = 400 },
    -- actions & behavior
    actions = {
      open_file = {
        quit_on_open = false, -- keep the tree open after opening a file
        resize_window = true,
      },
    },
    -- diagnostics in the tree (from LSP/none-ls)
    diagnostics = {
      enable = true,
      show_on_dirs = true,
      debounce_delay = 100,
      icons = { hint = "", info = "", warning = "", error = "" },
    },
  })

  -- Keymaps
  local map = vim.keymap.set
  map("n", "<leader>e",  "<cmd>NvimTreeToggle<CR>",      { desc = "Explorer: toggle" })
  map("n", "<leader>ef", "<cmd>NvimTreeFindFile<CR>",    { desc = "Explorer: reveal current file" })
  map("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>",    { desc = "Explorer: collapse all" })
  map("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>",     { desc = "Explorer: refresh" })
end

-- ── Auto-open nvim-tree on startup ──────────────────────────────────────────
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function(data)
    -- If no name passed (just `nvim`), don’t open tree
    if data.file == "" and vim.fn.getcwd() == "" then
      return
    end

    -- If the argument is a directory → open nvim-tree
    local directory = vim.fn.isdirectory(data.file) == 1
    if directory then
      vim.cmd.cd(data.file)
      require("nvim-tree.api").tree.open()
      return
    end

    -- If the argument is a file → also open nvim-tree
    require("nvim-tree.api").tree.open()
  end,
})



-- 10) Nicer diagnostics UI
vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  signs = true,
  float = { border = "rounded" },
  severity_sort = true,
})