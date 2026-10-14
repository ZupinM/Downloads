# Shared step for the firmware repos (called from their publish.ps1 after the build):
# runs <BuildDir>\generator.bat, then copies the generated <Name>.bin + <Name>.ini into <Folder> here and publishes.
#   publish-firmware.ps1 -BuildDir <dir with generator.bat> -Name micro_fw -Folder Micro -Project 'Micro firmware' -SourceRepo <repo>
param(
    [Parameter(Mandatory)][string]$BuildDir,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Folder,
    [Parameter(Mandatory)][string]$Project,
    [Parameter(Mandatory)][string]$SourceRepo
)
$ErrorActionPreference = 'Stop'
$downloads = $PSScriptRoot

Push-Location $BuildDir
try {
    # run generator.bat as is, except the bare "checksum_generator.jar" call gets "java -jar" in front:
    # from a script cmd can't start a .jar by name (and the file association would use javaw without waiting)
    (Get-Content generator.bat) -replace '^checksum_generator\.jar', 'java -jar checksum_generator.jar' | Set-Content generator_publish.bat
    Remove-Item "$Name.bin", "$Name.ini" -ErrorAction SilentlyContinue
    & cmd /c "$BuildDir\generator_publish.bat"
    if ($LASTEXITCODE -or -not (Test-Path "$Name.ini")) { throw "generator.bat failed in $BuildDir" }
} finally { Pop-Location }

$version = [regex]::Match((Get-Content "$BuildDir\$Name.ini" -Raw), 'version=(\d+)').Groups[1].Value
if (-not $version) { throw "version not found in $Name.ini" }

& "$downloads\push-binary.ps1" sync
New-Item -ItemType Directory -Force (Join-Path $downloads $Folder) | Out-Null
Copy-Item "$BuildDir\$Name.bin", "$BuildDir\$Name.ini" (Join-Path $downloads $Folder) -Force
& "$downloads\push-binary.ps1" publish -Project $Project -File "$Folder/$Name.bin" -Version $version -SourceRepo $SourceRepo
