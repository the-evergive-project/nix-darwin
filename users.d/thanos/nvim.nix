{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      # Claude Code integration
      claudecode-nvim

      # Ripgrep integration (live grep via telescope)
      telescope-nvim
      plenary-nvim                 # required by telescope
      telescope-fzf-native-nvim   # native fzf sorter for telescope

      # FZF integration
      fzf-lua

      # Top 3 most popular plugins
      (nvim-treesitter.withPlugins (p: with p; [
        bash css html javascript json lua markdown nix python toml typescript yaml
      ]))                          # #1 – syntax highlighting & AST-aware editing
      lualine-nvim                 # #2 – statusline
      nvim-cmp                     # #3 – completion engine
      nvim-web-devicons            # icons used by telescope, lualine, etc.

      # Completion LSP source
      cmp-nvim-lsp
    ];

    initLua = ''
      vim.g.mapleader = " "

      -- Numbers and basics
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.signcolumn = "yes"
      vim.opt.termguicolors = true

      -- Claude code
      require("claudecode").setup({
        -- Terminal window settings
        window = {
          split_ratio = 0.3,      -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
          position = "botright",  -- Position of the window: "botright", "topleft", "vertical", "float", etc.
          enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
          hide_numbers = true,    -- Hide line numbers in the terminal window
          hide_signcolumn = true, -- Hide the sign column in the terminal window
          
          -- Floating window configuration (only applies when position = "float")
          float = {
            width = "80%",        -- Width: number of columns or percentage string
            height = "80%",       -- Height: number of rows or percentage string
            row = "center",       -- Row position: number, "center", or percentage string
            col = "center",       -- Column position: number, "center", or percentage string
            relative = "editor",  -- Relative to: "editor" or "cursor"
            border = "rounded",   -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
          },
        },
        -- File refresh settings
        refresh = {
          enable = true,           -- Enable file change detection
          updatetime = 100,        -- updatetime when Claude Code is active (milliseconds)
          timer_interval = 1000,   -- How often to check for file changes (milliseconds)
          show_notifications = true, -- Show notification when files are reloaded
        },
        -- Git project settings
        git = {
          use_git_root = true,     -- Set CWD to git root when opening Claude Code (if in git project)
        },
        -- Shell-specific settings
        shell = {
          separator = '&&',        -- Command separator used in shell commands
          pushd_cmd = 'pushd',     -- Command to push directory onto stack (e.g., 'pushd' for bash/zsh, 'enter' for nushell)
          popd_cmd = 'popd',       -- Command to pop directory from stack (e.g., 'popd' for bash/zsh, 'exit' for nushell)
        },
        -- Command settings
        command = "claude",        -- Command used to launch Claude Code
        -- Command variants
        command_variants = {
          -- Conversation management
          continue = "--continue", -- Resume the most recent conversation
          resume = "--resume",     -- Display an interactive conversation picker

          -- Output options
          verbose = "--verbose",   -- Enable verbose logging with full turn-by-turn output
        },
        -- Keymaps
        keymaps = {
          toggle = {
            normal = "<leader>cl",
            terminal = "<C-x>",      -- Ctrl+x (works in terminal mode)
            variants = {
              continue = "<leader>cC",
              verbose  = "<leader>cV",
            },
          },
          window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
          scrolling = true,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
        }
      })

      -- Telescope (fuzzy finder + ripgrep live grep)
      require("telescope").setup {
        defaults = {
          layout_strategy = "horizontal",
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
          },
        },
      }
      require("telescope").load_extension("fzf")
      local tb = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", tb.find_files,   { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", tb.live_grep,    { desc = "Live grep (ripgrep)" })
      vim.keymap.set("n", "<leader>fb", tb.buffers,      { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", tb.help_tags,    { desc = "Help tags" })

      -- FZF-Lua (standalone fzf UI)
      require("fzf-lua").setup {}
      vim.keymap.set("n", "<leader>zf", "<cmd>FzfLua files<cr>",   { desc = "FZF files" })
      vim.keymap.set("n", "<leader>zg", "<cmd>FzfLua live_grep<cr>", { desc = "FZF grep" })

      -- Treesitter (0.10+ API — highlight/indent are enabled by default)
      require("nvim-treesitter").setup()

      -- Lualine
      require("lualine").setup {
        options = { theme = "auto" },
      }

      -- Biome LSP (neovim 0.11+ built-in API)
      vim.lsp.config('biome', {
        cmd = { 'biome', 'lsp-proxy' },
        filetypes = {
          'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
          'json', 'jsonc', 'css',
        },
        root_markers = { 'biome.json', 'biome.jsonc', 'package.json' },
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>bf", function()
            vim.lsp.buf.format { async = true }
          end, { buffer = bufnr, desc = "Biome format" })
        end,
      })
      vim.lsp.enable('biome')

      -- nvim-cmp (with LSP source added)
      local cmp = require("cmp")
      cmp.setup {
        mapping = cmp.mapping.preset.insert {
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm { select = true },
          ["<C-e>"]     = cmp.mapping.abort(),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      }
    '';
  };
}
