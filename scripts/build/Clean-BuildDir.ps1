## This script would need to manually called after msbuild publish beause there is not "PostPublish" task in msbuild
param(
    [string]
    $solutionDir = [System.IO.Path]::Combine($PSScriptRoot, "..", ".."),

    [string]
    $manifestDir = [System.IO.Path]::Combine($solutionDir, ".build")
)

function Move-SymbolsFiles {
    $symbolsDir = Join-Path $manifestDir symbols
    if (!(Test-Path $symbolsDir)) {
        mkdir $symbolsDir | Out-Null
    }
    Get-ChildItem -Path "*.pdb" -Recurse -File | ForEach-Object { Move-Item  $_.FullName $symbolsDir -Force }
}

function Remove-DuplicateDlls {
    $prefix = '.\plugins\'
    foreach ($pluginDll in (Get-ChildItem -Path "plugins" -Recurse -File | Resolve-Path -Relative)) {
        if (!$pluginDll.StartsWith($prefix)) {
            throw "Unexpected prefix path detected for path: ${pluginDll}"
        }
        $appDll = $pluginDll.Substring($prefix.Length)
        if (Test-Path $appDll) {
            Remove-Item $pluginDll -Force
        }
    }
}

function Remove-PluginDependenciesFiles {
    Remove-Item -Path '.\plugins\*.deps.json'
}

function Copy-3rdPartyNotice {
    Copy-Item (Join-Path $solutionDir ThirdPartyNotices.txt) $manifestDir
}

Push-Location (Join-Path $manifestDir "Microsoft.IIS.Administration")
try {
    Move-SymbolsFiles
    Remove-DuplicateDlls
    Remove-PluginDependenciesFiles
    Copy-3rdPartyNotice
} finally {
    Pop-Location
}