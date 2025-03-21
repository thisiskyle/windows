
local wezterm = require('wezterm')
local padding = '0'

return {
    color_scheme = 'rose-pine',
    default_prog = {'pwsh'},
    enable_scroll_bar = false,
    enable_tab_bar = false,
    font = wezterm.font('Maple Mono NL'),
    font_size = 12.0,
    audible_bell = "Disabled",
    harfbuzz_features = { 'calt = 0' }, -- turn off ligatures
    window_background_opacity = 0.97,
    window_padding = { left = padding, right = padding, top = padding, bottom = padding, },
    keys = {
        { key = 't', mods = 'ALT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
        { key = '1', mods = 'ALT', action = wezterm.action.ActivateTab(0) },
        { key = '2', mods = 'ALT', action = wezterm.action.ActivateTab(1) },
        { key = '3', mods = 'ALT', action = wezterm.action.ActivateTab(2) },
        { key = '4', mods = 'ALT', action = wezterm.action.ActivateTab(3) },
        { key = '[', mods = 'ALT', action = wezterm.action.ActivateTabRelative(-1) },
        { key = ']', mods = 'ALT', action = wezterm.action.ActivateTabRelative(1) },
    },
}
