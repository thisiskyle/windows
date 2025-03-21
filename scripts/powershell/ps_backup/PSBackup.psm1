
function Log($message)
{
    Write-Host $message -NoNewline
    Add-Content -Path $($script:logFile) -Value $($message)
}

function CopyFile($f, $p, $i)
{
    Log("$($f.FullName) --> $($finalFilePath)`n")

    Copy-Item -Recurse -Force -Path $f.FullName -Destination $finalFilePath
    if(-Not $i)
    {
        $script:updatedCount += 1
    }
}

function DoBackup($job)
{
    Log("`n--- Running Job: $($job.name) ---`n")

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
            Log("WARNING: Source $($s) does not exist`n")
            continue;
        }

        $files = Get-ChildItem $s -File -Recurse -Force

        # add to the total file count
        $script:totalCount += $files.Count

        # for every file in the list
        foreach ($f in $files)
        { 

            $subpath = "$($f.Directory)" -replace [regex]::escape($root), ""

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

                # create new destination structure using that list
                $finalFilePath = "$($finalDestinationDir)\$($f.Name)"

                # create all missing folders
                New-Item -Path $finalDestinationDir -ItemType Directory -Force | Out-Null

                # check if file exists
                if (Test-Path $finalFilePath) 
                {
                    # if the file exists, check the modified date
                    if ($f.LastWriteTime -eq $(Get-Item -Force $finalFilePath).LastWriteTime)
                    {
                    }
                    else
                    {
                        CopyFile($f, $finalFilePath, $i)
                    }
                }
                else 
                {
                    CopyFile($f, $finalFilePath, $i)
                }
            }
        }
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

    $script:logFile = "$($HOME)\psbackup\log\$(Get-Date -Format "yyyyMMdd_HHmm").txt"

    if (-Not (Test-Path $script:logFile))
    {
        New-Item -Path "$($script:logFile)" -ItemType File -Force | Out-Null
    }

    # if the jobfile is empty
    if($jobFileInfo -eq "")
    {
        Log("`nERROR: No job file name provided`n")
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
        Log("`nERROR: File '$($jobFile)' not found`n")
        return
    }

    Log("`n---------------- PSBackup --------------------------------`n")
    Log("Start     $(Get-Date -Format "yyyy/MM/dd HH:mm")`n")
    Log("Job File  $($jobFile)`n")

    Start-Sleep -Milliseconds 1000

    $script:jobs = Get-Content $jobFile | Out-String | ConvertFrom-Json
    $script:totalCount = 0
    $script:updatedCount = 0
    $script:activeJobs = 0
    $script:totalJobs = 0

    foreach ($script:j in $script:jobs)
    {
        if($script:j.active)
        {
            $script:activeJobs += 1
            DoBackup($script:j)
        }
        $script:totalJobs += 1
    }

    Log("`n------------------- Summary ---------------------------`n")
    Log("End             $(Get-Date -Format "yyyy/MM/dd HH:mm")`n")
    Log("Job File        $($jobFile)`n")
    Log("Log File        $($logFile)`n")
    Log("Active Jobs     $($script:activeJobs)/$($script:totalJobs)`n")
    Log("Files Updated   $($script:updatedCount)/$($script:totalCount)`n")
}

Export-ModuleMember -Function Start-PSBackup

