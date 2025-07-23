# 💤 LazyVim Starter for Omarchy

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim) tailored for [Omarchy](https://omarchy.org). This setup adds an automatic reload feature for themes, enhancing the user experience by allowing theme changes without restarting Neovim.

## How does the automatic reload feature work?:

In order to enable the automatic reload feature, each theme in Omarchy must have a neovim.lua file that defines the themes like this:

```lua
-- .config/omarchy/themes/gruvbox/neovim.lua
return {
    { "morhetz/gruvbox", lazy = false },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "gruvbox",
        },
    },
}
```

Additionally, we must make sure that LazyVim is configured to load every theme on startup. This is done by setting the `spec` and `install` options in the LazyVim configuration.

```lua
-- .config/nvim/lua/config/lazy.lua
spec = {
        -- add LazyVim and import its plugins
        { "LazyVim/LazyVim",           import = "lazyvim.plugins" },
        -- import/override with your plugins
        { import = "plugins" },
        -- import themes on load
        { "ellisonleao/gruvbox.nvim" },
        { "catppuccin/nvim",           name = "catppuccin" },
        { "folke/tokyonight.nvim" },
        { "neanias/everforest-nvim" },
        { "rebelot/kanagawa.nvim" },
        { "tahayvr/matteblack.nvim" },
        { "EdenEast/nightfox.nvim" },
        { "rose-pine/neovim",          name = "rose-pine" },
        { "artanikin/vim-synthwave84", name = "synthwave84" }
    },
install = { colorscheme = { "catppuccin-latte", "catppuccin", "tokyonight", "habamax", "gruvbox", "everforest", "kanagawa", "nordfox", "matteblack", "rose-pine-dawn", "synthwave84" } },
```

Then, we need a function to reload the theme based on Omarchy's current theme symlink target. This function will check if the theme has changed and apply the new theme without restarting Neovim.

```lua
-- .config/nvim/lua/init.lua

-- Variable to store the last known theme symlink target
local last_theme_target = nil

-- Function to reload the theme based on Omarchy's current theme
function ReloadTheme()
    local theme_dir = vim.fn.resolve(vim.fn.expand('~/.config/omarchy/current/theme'))
    local theme_config = theme_dir .. '/neovim.lua'

    -- Check if the theme directory has changed
    if theme_dir == last_theme_target then
        return -- No change, skip reload
    end

    if vim.fn.filereadable(theme_config) == 1 then
        local ok, result = pcall(dofile, theme_config)
        if not ok then
            print("Error loading theme: " .. result)
            return
        end
        -- Check if result is a table
        if type(result) == "table" then
            -- Look for LazyVim opts with colorscheme
            for _, entry in ipairs(result) do
                if entry[1] == "LazyVim/LazyVim" and entry.opts and entry.opts.colorscheme then
                    local ok, err = pcall(vim.cmd, 'colorscheme ' .. entry.opts.colorscheme)
                    if not ok then
                        print("Error applying colorscheme: " .. err)
                        return
                    end
                    vim.cmd('redraw!')
                    last_theme_target = theme_dir -- Update last known target
                    return
                end
            end
            print("No valid colorscheme found in " .. theme_config)
        else
            print("Invalid theme config format in " .. theme_config)
        end
    else
        print("Theme config not found: " .. theme_config)
    end
end

-- Load the theme on startup
ReloadTheme()
```

How does Neovim know when to reload the theme?:
We can use a signal handler that listens for the `SIGUSR1` signal. When this signal is received, it will trigger the `ReloadTheme` function.

```lua
-- .config/nvim/lua/init.lua

-- Reload theme on SIGUSR1 signal
vim.api.nvim_create_autocmd('User', {
    pattern = 'OmarchyThemeReload',
    callback = function()
        ReloadTheme()
    end,
})

-- Set up SIGUSR1 handler using vim.loop
local uv = vim.loop
local signal = uv.new_signal()
uv.signal_start(signal, "sigusr1", function()
    vim.schedule(function()
        vim.cmd('doautocmd User OmarchyThemeReload')
    end)
end)
```

and finally, we need to send the `SIGUSR1` signal to Neovim when the theme is changed. This can be done using a shell command or a script that changes the theme symlink and sends the signal to Neovim.

````bash
# omarchy-theme-set.sh

# Send SIGUSR1 signal to Neovim
pkill -SIGUSR1 nvim 2>/dev/null || true
```
````
