
function Install {
    param([string[]]$packages)

    foreach($p in $packages) {
        Write-Output "Install winget package $p"
        winget install -e --id $p --source winget
    }
}

Install @(
    'Nvidia.GeForceExperience',
    'Logitech.GHUB',
    'Microsoft.PowerToys',
    'Git.Git',
    'Unity.UnityHub',
    'DominikReichl.KeePass',
    '7zip.7zip',
    'Discord.Discord',
    'Flameshot.Flameshot',
    'Cockos.LICEcap',
    'GIMP.GIMP',
    'Valve.Steam',
    'Proton.ProtonVPN',
    'BurntSushi.ripgrep.MSVC',
    'VideoLAN.VLC',
    'GOG.Galaxy',
    'EpicGames.EpicGamesLauncher',
    'OpenJS.NodeJS',
    'wez.wezterm',
    'Microsoft.PowerShell',
    'zig.zig',
    'Python.Python',
    'LibreWolf.LibreWolf'
)
