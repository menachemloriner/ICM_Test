[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)] [string]$TaskPath,
    [Parameter(Mandatory = $true)] [string[]]$Source,
    [ValidateSet('inputs','work','deliverables')] [string]$Destination = 'inputs',
    [switch]$Force,
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resolvedTask = (Resolve-Path -LiteralPath $TaskPath).Path
$destinationPath = Join-Path $resolvedTask $Destination
New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

foreach ($item in $Source) {
    $resolved = (Resolve-Path -LiteralPath $item).Path
    $leaf = Split-Path -Leaf $resolved
    $target = Join-Path $destinationPath $leaf
    if ((Test-Path -LiteralPath $target) -and -not $Force) { throw "Target exists; use -Force to replace it: $target" }
    if ($PSCmdlet.ShouldProcess($target, "Copy $resolved")) {
        Copy-Item -LiteralPath $resolved -Destination $target -Recurse -Force:$Force
        Write-Output $target
    }
}
