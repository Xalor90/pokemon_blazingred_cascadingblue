# Parse parameters
param (
    [Parameter(Mandatory=$false)]
    [string[]]$Components = @()
)

# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Define component names
$AVAILABLE_COMPONENTS = @("7zip", "python", "devkitpro", "msys2", "assembly")

# Show help if requested
if ($Components -contains "help" -or $Components -contains "?" -or $Components -contains "-h" -or $Components -contains "--help" -or $args -contains "/?" -or $args -contains "-help") {
    Write-Host "GBA Development Framework Uninstall Script" -ForegroundColor Cyan
    Write-Host "------------------------------------------" -ForegroundColor Cyan
    Write-Host "Usage: ./uninstall.ps1 [-Components component1,component2,...]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Components: Specific components to uninstall" -ForegroundColor Yellow
    Write-Host "               If not specified, all components will be uninstalled" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available components:" -ForegroundColor Yellow
    Write-Host "  7zip      - 7-Zip file archiver" -ForegroundColor Yellow
    Write-Host "  python    - Python and pip packages in MSYS2" -ForegroundColor Yellow
    Write-Host "  devkitpro - DevkitPro GBA development tools" -ForegroundColor Yellow
    Write-Host "  msys2     - MSYS2 environment" -ForegroundColor Yellow
    Write-Host "  assembly  - Assembly support (directories and environment variable)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  ./uninstall.ps1" -ForegroundColor Cyan
    Write-Host "    This will uninstall all components" -ForegroundColor Cyan
    Write-Host "  ./uninstall.ps1 -Components assembly" -ForegroundColor Cyan
    Write-Host "    This will only remove Assembly support" -ForegroundColor Cyan
    Write-Host "  ./uninstall.ps1 -Components devkitpro,assembly" -ForegroundColor Cyan
    Write-Host "    This will only uninstall DevkitPro and Assembly support" -ForegroundColor Cyan
    exit 0
}

# Define paths
$msys2Path = "C:\msys64"
$devkitProPath = "/opt/devkitpro"  # MSYS2 path
$devkitProWindowsPath = "C:\devkitPro"  # Windows path
$projectRoot = Get-Location

# Process component selection
$selectedComponents = @()

# If specific components are requested, use those
if ($Components.Count -gt 0) {
    # Validate each component
    foreach ($component in $Components) {
        if ($AVAILABLE_COMPONENTS -contains $component) {
            $selectedComponents += $component
        } else {
            Write-Host "Warning: Unknown component '$component'. Skipping." -ForegroundColor Yellow
        }
    }
    
    # If no valid components after validation, show warning
    if ($selectedComponents.Count -eq 0) {
        Write-Host "No valid components specified. Use one of: $($AVAILABLE_COMPONENTS -join ', ')" -ForegroundColor Yellow
        exit 1
    }
} 
# Otherwise, use all available components
else {
    $selectedComponents = $AVAILABLE_COMPONENTS
    Write-Host "No specific components specified. Uninstalling all components." -ForegroundColor Yellow
}

# Function to log uninstallation steps
function Write-UninstallLog {
    param (
        [string]$Component,
        [string]$Message,
        [string]$Status,
        [switch]$Important
    )
    
    $color = switch ($Status) {
        "Info" { "White" }
        "Start" { "Yellow" }
        "Success" { "Green" }
        "Error" { "Red" }
        "Skip" { "Cyan" }
        default { "White" }
    }
    
    $prefix = if ($Important) { "## " } else { "-- " }
    Write-Host "$prefix[$Component] $Message" -ForegroundColor $color
}

# Function to check if component should be excluded
function Should-Skip {
    param (
        [string]$Component
    )
    
    if ($Exclude -contains $Component) {
        Write-UninstallLog -Component $Component -Message "Skipping as requested" -Status "Skip" -Important
        return $true
    }
    
    return $false
}

# Function to remove environment variables
function Remove-EnvironmentVariable {
    param (
        [string]$VariableName
    )
    try {
        [Environment]::SetEnvironmentVariable($VariableName, $null, [EnvironmentVariableTarget]::Machine)
        Write-UninstallLog -Component "System" -Message "Removed environment variable: $VariableName" -Status "Success"
    } catch {
        Write-UninstallLog -Component "System" -Message "Failed to remove environment variable ${VariableName}: $_" -Status "Error"
    }
}

# Function to remove from PATH
function Remove-FromPath {
    param (
        [string]$PathToRemove
    )
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
        $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $PathToRemove }) -join ';'
        [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)
        Write-UninstallLog -Component "System" -Message "Removed from PATH: $PathToRemove" -Status "Success"
    } catch {
        Write-UninstallLog -Component "System" -Message "Failed to remove from PATH: $_" -Status "Error"
    }
}

# Function to remove assembly support
function Remove-AssemblySupport {
    Write-Host "Removing Assembly support..." -ForegroundColor Yellow
    
	if (Test-Path "config.local.mk") {
		Remove-Item "config.local.mk" -Force
		Write-Host "config.local.mk has been removed."
	} else {
		Write-Host "config.local.mk does not exist."
	}

    # Define assembly directories
    $asmDirs = @(
        "asm/src",
        "asm/include",
        "asm/macros",
        "asm/data",
        "asm/lib",
        "asm"
    )
    
    # Check if any assembly directories exist
    $anyDirExists = $false
    foreach ($dir in $asmDirs) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $dir
        if (Test-Path $fullPath) {
            $anyDirExists = $true
            break
        }
    }
    
    # Only prompt for removal if directories exist
    $removeDirectories = $false
    if ($anyDirExists) {
        $confirmation = Read-Host "Assembly directories found. Do you want to remove all assembly directories and files? (Y/N)"
        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
            $removeDirectories = $true
        } else {
            Write-Host "Assembly directories will not be removed." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No assembly directories found to remove." -ForegroundColor Cyan
    }
    
    if ($removeDirectories) {
        foreach ($dir in $asmDirs) {
            $fullPath = Join-Path -Path $projectRoot -ChildPath $dir
            if (Test-Path $fullPath) {
                try {
                    Remove-Item -Path $fullPath -Recurse -Force
                    Write-Host "Removed $dir directory" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove $dir directory: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host "Assembly support removal completed." -ForegroundColor Green
}

# Remove 7-Zip
if ($selectedComponents -contains "7zip") {
    Write-UninstallLog -Component "7zip" -Message "Starting uninstallation" -Status "Start" -Important
    try {
        # Get the uninstall string from registry
        $uninstallString = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" -Name "UninstallString" -ErrorAction SilentlyContinue
        if ($uninstallString) {
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {23170F69-40C1-2702-2104-000001000000} /qn" -Wait
            Write-UninstallLog -Component "7zip" -Message "Successfully removed" -Status "Success"
        } else {
            Write-UninstallLog -Component "7zip" -Message "Not found, skipping removal" -Status "Skip"
        }
    } catch {
        Write-UninstallLog -Component "7zip" -Message "Error removing: $_" -Status "Error"
    }
}

# Check if MSYS2 exists before attempting to uninstall components that depend on it
$msys2Exists = Test-Path $msys2Path

# Remove Python and pip packages from MSYS2
if ($selectedComponents -contains "python" -and $msys2Exists) {
    Write-UninstallLog -Component "Python" -Message "Starting uninstallation" -Status "Start" -Important
    try {
        # Check if pacman and python exist first
        $pythonExists = Test-Path "$msys2Path\usr\bin\python.exe"
        $pacmanExists = Test-Path "$msys2Path\usr\bin\pacman.exe"
        
        if ($pythonExists -and $pacmanExists) {
            $removePythonResult = Start-Process -FilePath "$msys2Path\usr\bin\bash.exe" -ArgumentList "-lc 'yes | /usr/bin/pacman -R --noconfirm --noprogressbar python python-pip 2>/dev/null || true'" -Wait -PassThru
            if ($removePythonResult.ExitCode -ne 0) {
                Write-UninstallLog -Component "Python" -Message "Failed to remove packages, they may already be uninstalled" -Status "Info"
            } else {
                Write-UninstallLog -Component "Python" -Message "Successfully removed packages" -Status "Success"
            }
        } else {
            Write-UninstallLog -Component "Python" -Message "Python or pacman not found in MSYS2, skipping" -Status "Skip"
        }
    } catch {
        Write-UninstallLog -Component "Python" -Message "Error removing: $_" -Status "Error"
    }
}

# Remove Assembly Support
if ($selectedComponents -contains "assembly") {
    Write-UninstallLog -Component "Assembly" -Message "Starting uninstallation" -Status "Start" -Important
    Remove-AssemblySupport
}

# Remove DevkitPro
if ($selectedComponents -contains "devkitpro") {
    Write-UninstallLog -Component "DevkitPro" -Message "Starting uninstallation" -Status "Start" -Important
    
    # Remove DevkitPro packages from MSYS2
    if ($msys2Exists) {
        Write-UninstallLog -Component "DevkitPro" -Message "Removing packages from MSYS2" -Status "Info"
        try {
            # Check if pacman exists first
            $pacmanExists = Test-Path "$msys2Path\usr\bin\pacman.exe"
            
            if ($pacmanExists) {
                $removeResult = Start-Process -FilePath "$msys2Path\usr\bin\bash.exe" -ArgumentList "-lc 'yes | /usr/bin/pacman -R --noconfirm --noprogressbar devkitARM devkitpro-keyring 2>/dev/null || true'" -Wait -PassThru
                if ($removeResult.ExitCode -ne 0) {
                    Write-UninstallLog -Component "DevkitPro" -Message "Failed to remove packages, they may already be uninstalled" -Status "Info"
                } else {
                    Write-UninstallLog -Component "DevkitPro" -Message "Successfully removed packages" -Status "Success"
                }
            } else {
                Write-UninstallLog -Component "DevkitPro" -Message "Pacman not found in MSYS2, skipping package removal" -Status "Skip"
            }
        } catch {
            Write-UninstallLog -Component "DevkitPro" -Message "Error removing packages: $_" -Status "Error"
        }
    }
    
    # Remove Windows symlink
    if (Test-Path $devkitProWindowsPath) {
        Write-UninstallLog -Component "DevkitPro" -Message "Removing Windows symlink" -Status "Info"
        try {
            Remove-Item -Path $devkitProWindowsPath -Force -Recurse -ErrorAction Stop
            Write-UninstallLog -Component "DevkitPro" -Message "Successfully removed Windows symlink" -Status "Success"
        } catch {
            Write-UninstallLog -Component "DevkitPro" -Message "Failed to remove Windows symlink: $_" -Status "Error"
        }
    }
    
    # Remove DevkitPro directories from MSYS2
    if ($msys2Exists) {
        Write-UninstallLog -Component "DevkitPro" -Message "Removing DevkitPro directories from MSYS2" -Status "Info"
        try {
            $removeDirResult = Start-Process -FilePath "$msys2Path\usr\bin\bash.exe" -ArgumentList "-lc '/usr/bin/rm -rf $devkitProPath 2>/dev/null || true'" -Wait -PassThru
            if ($removeDirResult.ExitCode -ne 0) {
                Write-UninstallLog -Component "DevkitPro" -Message "Failed to remove DevkitPro directories" -Status "Error"
            } else {
                Write-UninstallLog -Component "DevkitPro" -Message "Successfully removed DevkitPro directories" -Status "Success"
            }
        } catch {
            Write-UninstallLog -Component "DevkitPro" -Message "Error removing directories: $_" -Status "Error"
        }
    }
    
    # Remove environment variables
    Write-UninstallLog -Component "DevkitPro" -Message "Removing environment variables" -Status "Info"
    Remove-EnvironmentVariable -VariableName "DEVKITPRO"
    Remove-EnvironmentVariable -VariableName "DEVKITARM"
    
    # Remove from PATH
    Write-UninstallLog -Component "DevkitPro" -Message "Removing from PATH" -Status "Info"
    Remove-FromPath -PathToRemove "$devkitProWindowsPath\tools\bin"
    
    # Remove DevkitPro repositories from pacman.conf
    if ($msys2Exists) {
        Write-UninstallLog -Component "DevkitPro" -Message "Removing repositories from pacman.conf" -Status "Info"
        try {
            # Check if pacman.conf exists first
            $pacmanConfExists = Test-Path "$msys2Path\etc\pacman.conf"
            
            if ($pacmanConfExists) {
                $sedResult = Start-Process -FilePath "$msys2Path\usr\bin\bash.exe" -ArgumentList "-lc '/usr/bin/sed -i ''/\[dkp-libs\]/,/^$/d'' /etc/pacman.conf 2>/dev/null; /usr/bin/sed -i ''/\[dkp-windows\]/,/^$/d'' /etc/pacman.conf 2>/dev/null || true'" -Wait -PassThru
                if ($sedResult.ExitCode -ne 0) {
                    Write-UninstallLog -Component "DevkitPro" -Message "Failed to remove repositories from pacman.conf" -Status "Error"
                } else {
                    Write-UninstallLog -Component "DevkitPro" -Message "Successfully removed repositories from pacman.conf" -Status "Success"
                }
            } else {
                Write-UninstallLog -Component "DevkitPro" -Message "pacman.conf not found, skipping" -Status "Skip"
            }
        } catch {
            Write-UninstallLog -Component "DevkitPro" -Message "Error modifying pacman.conf: $_" -Status "Error"
        }
    }
}

# Remove MSYS2
if ($selectedComponents -contains "msys2" -and $msys2Exists) {
    Write-UninstallLog -Component "MSYS2" -Message "Starting uninstallation" -Status "Start" -Important
    try {
        # Remove from PATH first
        Write-UninstallLog -Component "MSYS2" -Message "Removing from PATH" -Status "Info"
        Remove-FromPath -PathToRemove "$msys2Path\usr\bin"
        
        # First try to uninstall using the uninstaller
        $uninstallerPath = "$msys2Path\uninstall.exe"
        if (Test-Path $uninstallerPath) {
            Write-UninstallLog -Component "MSYS2" -Message "Using uninstaller" -Status "Info"
            Start-Process -FilePath $uninstallerPath -ArgumentList "/S" -Wait
        }
        
        # If uninstaller fails or doesn't exist, remove the directory
        if (Test-Path $msys2Path) {
            Write-UninstallLog -Component "MSYS2" -Message "Uninstaller failed or not found, manually removing" -Status "Info"
            
            # Kill any running MSYS2 processes first
            Write-UninstallLog -Component "MSYS2" -Message "Stopping running processes" -Status "Info"
            Get-Process | Where-Object { $_.Path -like "$msys2Path\*" } | Stop-Process -Force -ErrorAction SilentlyContinue
            
            # Wait a moment for processes to terminate
            Start-Sleep -Seconds 2
            
            # Remove directory
            Remove-Item -Path $msys2Path -Recurse -Force -ErrorAction Stop
        }
        
        if (Test-Path $msys2Path) {
            Write-UninstallLog -Component "MSYS2" -Message "Failed to remove installation" -Status "Error"
        } else {
            Write-UninstallLog -Component "MSYS2" -Message "Successfully removed installation" -Status "Success"
        }
    } catch {
        Write-UninstallLog -Component "MSYS2" -Message "Error removing: $_" -Status "Error"
    }
}

Write-Host "`nUninstallation summary:" -ForegroundColor Cyan
# Display summary of selected components
foreach ($component in $AVAILABLE_COMPONENTS) {
    if ($selectedComponents -notcontains $component) {
        Write-Host "  $component - Skipped (not selected)" -ForegroundColor Cyan
    } else {
        # Check if component was actually present
        $present = switch ($component) {
            "7zip" { Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" }
            "msys2" { -not (Test-Path $msys2Path) }
            "devkitpro" { -not (Test-Path $devkitProWindowsPath) }
            "python" { -not (Test-Path "$msys2Path\usr\bin\python.exe") }
            "assembly" { -not [Environment]::GetEnvironmentVariable("GBA_ASM_SUPPORT", [EnvironmentVariableTarget]::Machine) }
            default { $false }
        }
        
        if ($present) {
            Write-Host "  $component - Uninstalled successfully" -ForegroundColor Green
        } else {
            Write-Host "  $component - Uninstall attempted (may have had errors)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nUninstallation completed!" -ForegroundColor Green
Write-Host "Please restart your terminal or system for changes to take effect." -ForegroundColor Yellow 