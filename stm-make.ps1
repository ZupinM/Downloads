# Builds a STM32CubeIDE project's Debug folder with make and the toolchain bundled in CubeIDE
# (no workspace lock, so it works while the IDE is open). Throws when the build fails.
#   stm-make.ps1 -BuildDir C:\STMCubeIDE\Micro\Debug
param([Parameter(Mandatory)][string]$BuildDir)
$ErrorActionPreference = 'Stop'
$plugins = 'C:\ST\STM32CubeIDE_1.16.0\STM32CubeIDE\plugins'
$gcc = Get-ChildItem "$plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.*\tools\bin" | Select-Object -Last 1
$make = Get-ChildItem "$plugins\com.st.stm32cube.ide.mcu.externaltools.make.*\tools\bin" | Select-Object -Last 1
$env:PATH = "$($gcc.FullName);$($make.FullName);$env:PATH"
Push-Location $BuildDir
try { & make -j8 all; if ($LASTEXITCODE) { throw "build failed in $BuildDir" } } finally { Pop-Location }
