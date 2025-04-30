
function Log() {
    param(
        [Parameter(Mandatory=$true)] [string] $message
    )

    Write-Host $message -NoNewline
    Add-Content -Path $($Script:logFile) -Value $message
}

function CopyFiles() {
    param(
        [Parameter(Mandatory=$true)] 
        [System.Collections.Hashtable] $table
    )

    foreach($k in $table.Keys) 
    {
        for (($i = 0); $i -lt $table[$k].Count; $i++)
        {
            $d = $table[$k][$i]

            # create all missing folders
            New-Item -Path $d -ItemType Directory -Force | Out-Null

            $dPath = "$($d)$($k.Name)"

            # check if file exists
            if ((Test-Path $dPath) -and ($k.LastWriteTime -eq $(Get-Item -Force $dPath).LastWriteTime)) 
            {
            }
            else 
            {
                Log -message "$($k.FullName) --> $($dPath)`n"
                Copy-Item -Recurse -Force -Path $k.FullName -Destination $dPath

                # todo: maybe we dont care about this
                if($i -eq 0)
                {
                    $Script:updatedCount += 1
                }
            }
        }
    }
}

function FixDestinations() {
    param(
        [Parameter(Mandatory=$false)] [string] $subpath,
        [Parameter(Mandatory=$true)] [array] $destinations
    )

    $Local:returnMe = (New-Object 'object[]' $destinations.Count)

    for (($i = 0); $i -lt $destinations.Count; $i++)
    {
        # this is for the network drive, for some reason it doesnt add the backslash to the path
        # so we just check and add one if needed
        if(-Not $destinations[$i].EndsWith("\") -And -Not $subpath.StartsWith("\"))
        {
            $finalDestinationDir = "$($destinations[$i])\$($subpath)"
        }
        else
        {
            $finalDestinationDir = "$($destinations[$i])$($subpath)"
        }

        if(-Not $finalDestinationDir.EndsWith("\"))
        {
            $Local:returnMe[$i] = "$($finalDestinationDir)\"
        }
        else
        {
            $Local:returnMe[$i] = "$($finalDestinationDir)"
        }
    }

    return $Local:returnMe
}

function RunJob()
{
    param(
        [Parameter(Mandatory=$true)] [object] $job
    )

    Log -message "`n--- Running Job: $($job.name) ---`n"

    $sources = $job.sources
    $root = $job.sourceRoot
    $destinations = $job.destinations

    # if $sources is empty, we should add one that is just \
    # which will just back up everything in the root directory
    if ($sources.Count -eq 0)
    {
        $sources = @("\")
    }

    foreach ($src in $sources)
    {
        $s = "$($root)\$($src)"

        if (-Not (Test-Path $s)) 
        {
            Log -message "WARNING: Source $($s) does not exist`n"
            continue;
        }

        $files = Get-ChildItem $s -File -Recurse -Force
        $Script:totalCount += $files.Count
        $hash = @{}

        foreach ($f in $files)
        { 
            $subpath = "$($f.Directory)" -replace [regex]::escape($root), ""
            $fixed = FixDestinations -subpath $subpath -destinations $destinations
            $hash[$f] = @($fixed)
        }

        CopyFiles -table $hash
    }
}

function Start-PSBackup()
{
    param(
        [Parameter(Mandatory=$true)] [string] $jobFileInfo,
        [Parameter(Mandatory=$false)] [switch] $FullPath
    )

    # create the home psbackup directory if it doesnt exist
    if (-Not (Test-Path "$($HOME)\psbackup\"))
    {
        New-Item -Path "$($HOME)\psbackup" -ItemType Directory -Force | Out-Null
    }

    # create the log directory if it doesnt exist
    if (-Not (Test-Path "$($HOME)\psbackup\log"))
    {
        New-Item -Path "$($HOME)\psbackup\log" -ItemType Directory -Force | Out-Null
    }

    $Script:logFile = "$($HOME)\psbackup\log\$(Get-Date -Format "yyyyMMdd_HHmm").txt"

    if (-Not (Test-Path $Script:logFile))
    {
        New-Item -Path "$($Script:logFile)" -ItemType File -Force | Out-Null
    }

    # if the jobfile is empty
    if($jobFileInfo -eq "")
    {
        Log -message "`nERROR: No job file name provided`n"
        return
    }

    # If the FullPath switch is present then the path provide is
    # the full path to the job file, use it as is.
    # If not, then we assume the job file is in the $HOME\psbackup directory
    if($FullPath.IsPresent)
    {
        $jobFile = "$($jobFileInfo)"
    }
    else
    {
        $jobFile = "$($HOME)\psbackup\$($jobFileInfo).json"
    }


    if (-Not (Test-Path $jobFile))
    {
        Log -message "`nERROR: File '$($jobFile)' not found`n"
        return
    }

    Log -message "`n---------------- PSBackup --------------------------------`n"
    Log -message "Start     $(Get-Date -Format "yyyy/MM/dd HH:mm")`n"
    Log -message "Job File  $($jobFile)`n"

    Start-Sleep -Milliseconds 1000

    $jobs = Get-Content $jobFile | Out-String | ConvertFrom-Json
    $Script:totalCount = 0
    $Script:updatedCount = 0
    $Script:activeJobs = 0
    $Script:totalJobs = 0

    foreach ($j in $jobs)
    {
        if($j.active)
        {
            $Script:activeJobs += 1
            RunJob -job $j
        }
        $Script:totalJobs += 1
    }

    Log -message "`n------------------- Summary ---------------------------`n"
    Log -message "End             $(Get-Date -Format "yyyy/MM/dd HH:mm")`n"
    Log -message "Job File        $($jobFile)`n"
    Log -message "Log File        $($logFile)`n"
    Log -message "Active Jobs     $($Script:activeJobs)/$($Script:totalJobs)`n"
    Log -message "Files Updated   $($Script:updatedCount)/$($Script:totalCount)`n"
}

Export-ModuleMember -Function Start-PSBackup

