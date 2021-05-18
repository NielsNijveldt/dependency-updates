function ExecuteUpdates {

    # update path variable so we can find the nukeeper tool
    $env:PATH="$($env:PATH):/root/.dotnet/tools:/dependency-updates/"
    #Write-Host $env:PATH

    Write-Host "Calling nukeeper inspect"
    # get update info from NuKeeper
    #$updates = .$PSScriptRoot\nukeeper inspect --outputformat csv
    $updates = nukeeper inspect --outputformat csv

    Write-Host "Checking for updates"
    # since the update info is in csv, we'll need to search
    $updatesFound = $false
    foreach ($row in $updates) {
        if ($row.IndexOf("possible updates") -gt -1) {
            Write-Host "Found updates row [$row]"; 
            if ($row.IndexOf("Found 0 possible updates") -gt -1) {
                Write-Host "There are no updates"
            }
            else {
                Write-Host "There are updates"
                $updatesFound = $true
            }
            break
        }
    }   

    if ($updatesFound) {
        UpdatePackages
    }

    return $updatesFound
}

function UpdatePackages {
    # call the nukeeper tool to update all projects
    # -a is PackageAge where 0 == immediately
    # -m is the maximum number of Packages to update (defaults to 1!)
    nukeeper update -a 0 -m 10000 

    if ($? -ne $true) {
        # sometimes nukeeper fails the first time, running it again helps (╯°□°）╯︵ ┻━┻
        nukeeper update -a 0 -m 10000 
        if ($? -ne $true) {
          Write-Error "Error running nukeeper update"
          Write-Error "This probably an error with NuKeeper and downgraded packages."
          Write-Error "Please run 'nukeeper update -a 0 -m 10000' from the project/solution root"
          throw
        }
    }
}