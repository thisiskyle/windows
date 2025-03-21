# define the wallpaper handler
$setwallpapersrc = @"
    using System.Runtime.InteropServices;

    public static class WallpaperHandler
    {
        public const int SetDesktopWallpaper = 20;
        public const int UpdateIniFile = 0x01;
        public const int SendWinIniChange = 0x02;

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);

        public static void SetWallpaper ( string path )
        {
            SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
        }
    }
"@

Add-Type -TypeDefinition $setwallpapersrc


$wallpaperpath = "S:\dev\arch_utils\wallpaper"

$sunrise = "$($wallpaperpath)\outset_sunrise.png"
$day = "$($wallpaperpath)\outset_day.png"
$sunset = "$($wallpaperpath)\outset_sunset.png"
$night = "$($wallpaperpath)\outset_night.png"

$sunriseStart = Get-Date '07:00' 
$dayStart = Get-Date '10:00' 
$sunsetStart = Get-Date '17:00' 
$nightStart = Get-Date '22:00' 


while(1)
{
    $now = Get-Date

    # sunrise
    if($now.TimeOfDay -ge $sunriseStart.TimeOfDay -and $now.TimeOfDay -lt $dayStart.TimeOfDay)
    {
        [WallpaperHandler]::SetWallpaper($sunrise)
    }
    # day
    elseif($now.TimeOfDay -ge $dayStart.TimeofDay -and $now.TimeOfDay -lt $sunsetStart.TimeOfDay)
    {
        [WallpaperHandler]::SetWallpaper($day)
    }
    # sunset
    elseif($now.TimeOfDay -ge $sunsetStart.TimeofDay -and $now.TimeOfDay -lt $nightStart.TimeOfDay)
    {
        [WallpaperHandler]::SetWallpaper($sunset)
    }
    # night
    else
    {
        [WallpaperHandler]::SetWallpaper($night)
    }

    Start-Sleep -Seconds (10*60)
}
