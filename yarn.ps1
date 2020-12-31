# global variables we use
parameters(
    [string] $branchPrefix = "yarn-updates",
    # get the Id of the project to push the MR into from the GitLab project overview page
    # API doesn't have a great setting for this
    [integer] $gitLabProjectId = 333
)

Write-Host " PowerShell version: $($PsVersionTable.PSVersion)"

Set-Location $PSScriptRoot
# import git functions
. .\git.ps1

function CreateMergeRequest {
    param(
        [string] $gitLabProjectId,
        [string] $branchName,
        [string] $targetBranch = "main",
        [string] $branchPrefix
    )

    $sourceBranch = $branchName
    $sourceBranchPrefix = $branchPrefix

    CreateNewMergeRequestIfNoOpenOnes -projectId $gitLabProjectId `
                                      -sourceBranchPrefix $sourceBranchPrefix `
                                      -sourceBranch $sourceBranch `
                                      -targetBranch "main" `
                                      -title "Bumping yarn packages versions"
}

function ExecuteUpdates {

    # git commands need to run in the calling path
    Set-Location ..\..\
    
    git --version

    # clone a new copy of the repo with gitlabtoken that has write access (for a new branch)
    Set-Location ..\
    mkdir Temp
    Set-Location Temp
    git clone https://xx:$($env:GitLabToken)@digitalgreenhouse.gitlab.host/floriday/sites/plugins/digital-clock-supply.git
    Set-Location digital-clock-supply

    # get updated npmrc file from root
    Copy-Item ..\..\digital-clock-supply\.npmrc .

    git config user.email "CI-Pipeline@rfh.com"
    git config user.name "CI Pipeline"

    # check for updates with yarn:
    yarn
    yarn eslint
    yarn build
    yarn upgrade

    # use git status to check if there are any changed files
    $status = git diff-index HEAD
    $updatesFound = ($status.Length -gt 0)

    # dont add npmrc to the history
    git restore .npmrc

    if ($updatesFound) {
        Write-Host "Creating new branch"
        $branchName = CreateNewBranch
        
        Write-Host "Committing and pushing the branch"
        CommitAndPushBranch -branchName $branchName -commitMessage "yarn dependencies updated"

        # import gitlab functions
        . $PSScriptRoot\GitLab.ps1
        Write-Host "Creating new merge request"
        CreateMergeRequest -branchName $branchName -branchPrefix $branchPrefix -gitLabProjectId $gitLabProjectId
    }
    else {
        Write-Host "Found no updates"
    }
}

ExecuteUpdates -gitLabProjectId $gitLabProjectId