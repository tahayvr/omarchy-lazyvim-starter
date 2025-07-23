-- Load LazyVim first to ensure plugins are available
require("config.lazy")

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
