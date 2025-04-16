param (
    [string[]]$Components = @(),
    [switch]$WithAssembly = $false
)

# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Define available components
$AVAILABLE_COMPONENTS = @("7zip", "msys2", "python", "devkitpro", "assembly")

# Display help information if requested
if ($args -contains "-help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "--help") {
    Write-Host "GBA Development Environment Installation Script" -ForegroundColor Cyan
    Write-Host "Usage: .\install.ps1 [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Components component1,component2,...  Install specific components" -ForegroundColor Yellow
    Write-Host "                                         If not specified, all components except assembly will be installed" -ForegroundColor Yellow
    Write-Host "  -WithAssembly                          Enable Assembly development support" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available components:" -ForegroundColor Yellow
    Write-Host "  7zip      - 7-Zip file archiver" -ForegroundColor Yellow
    Write-Host "  msys2     - MSYS2 environment" -ForegroundColor Yellow
    Write-Host "  python    - Python and pip packages in MSYS2" -ForegroundColor Yellow
    Write-Host "  devkitpro - DevkitPro GBA development tools" -ForegroundColor Yellow
    Write-Host "  assembly  - Assembly support (directories and environment variable)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\install.ps1                                 # Install all basic components (7zip, msys2, python, devkitpro)" -ForegroundColor Cyan
    Write-Host "  .\install.ps1 -WithAssembly                   # Install all components including Assembly support" -ForegroundColor Cyan 
    Write-Host "  .\install.ps1 -Components assembly            # Install only Assembly support" -ForegroundColor Cyan
    Write-Host "  .\install.ps1 -Components devkitpro,assembly  # Install only DevkitPro and Assembly" -ForegroundColor Cyan
    exit 0
}

# Process component selection
$selectedComponents = @()

# Enable assembly if -WithAssembly is set or "assembly" is in Components list
if ($WithAssembly -or ($Components -contains "assembly")) {
    $Components = $Components | Where-Object { $_ -ne "assembly" } # Remove assembly from Components if it exists
    $WithAssembly = $true  # Set WithAssembly to true for compatibility with rest of script
}

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
# Otherwise, use all available components except assembly 
else {
    $selectedComponents = $AVAILABLE_COMPONENTS | Where-Object { $_ -ne "assembly" }
    Write-Host "No specific components specified. Installing all core components." -ForegroundColor Yellow
}

# Function to verify installation
function Test-Installation {
    param (
        [string]$Path,
        [string]$Component
    )
    if (-not (Test-Path $Path)) {
        Write-Host "$Component installation directory not found at $Path" -ForegroundColor Red
        return $false
    }
    return $true
}

# Function to verify environment variable
function Test-EnvironmentVariable {
    param (
        [string]$VariableName,
        [string]$ExpectedValue
    )
    $value = [Environment]::GetEnvironmentVariable($VariableName, [EnvironmentVariableTarget]::Machine)
    if (-not $value -or $value -ne $ExpectedValue) {
        Write-Host "$VariableName environment variable not set correctly" -ForegroundColor Red
        return $false
    }
    return $true
}

# Define paths
$7zipInstallerUrl = "https://www.7-zip.org/a/7z2401-x64.msi"
$7zipInstallerPath = "$env:TEMP\7zip.msi"
$msys2Path = "C:\msys64"
$devkitProPath = "/opt/devkitpro"  # MSYS2 path
$msys2ArchiveUrl = "https://github.com/msys2/msys2-installer/releases/download/2023-07-18/msys2-base-x86_64-20230718.tar.xz"
$tempArchivePath = "$env:TEMP\msys2.tar.xz"
$tempTarPath = "$env:TEMP\msys2.tar"

# Function to install 7-Zip
function Install-7Zip {
    Write-Host "Installing 7-Zip..." -ForegroundColor Yellow
    try {
        # Download 7-Zip installer
        Invoke-WebRequest -Uri $7zipInstallerUrl -OutFile $7zipInstallerPath
        
        # Install 7-Zip silently
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$7zipInstallerPath`" /qn" -Wait
        
        # Clean up installer
        Remove-Item $7zipInstallerPath
        
        # Add 7-Zip to PATH
        $7zipPath = "C:\Program Files\7-Zip"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";$7zipPath"
        
        Write-Host "7-Zip installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install 7-Zip: $_" -ForegroundColor Red
        exit 1
    }
}

# Function to install MSYS2
function Install-MSYS2 {
    # Check if MSYS2 is already installed
    if (Test-Path "$msys2Path\usr\bin\bash.exe") {
        Write-Host "MSYS2 is already installed at $msys2Path" -ForegroundColor Green
        return
    }
    
    Write-Host "Installing MSYS2..." -ForegroundColor Yellow
    
    # Create MSYS2 directory if it doesn't exist
    if (-not (Test-Path $msys2Path)) {
        New-Item -ItemType Directory -Path $msys2Path -Force | Out-Null
    }
    
    # Download the MSYS2 archive using curl (built into modern Windows)
    Write-Host "Downloading MSYS2 archive..." -ForegroundColor Yellow
    $curlArgs = @(
        "--location",
        "--output", $tempArchivePath,
        "--silent",
        "--show-error",
        $msys2ArchiveUrl
    )
    Start-Process -FilePath "curl" -ArgumentList $curlArgs -NoNewWindow -Wait
    
    # Extract using 7-Zip
    Write-Host "Extracting MSYS2 archive (this may take a while)..." -ForegroundColor Yellow
    
    # Get 7-Zip path
    $7zipPath = "C:\Program Files\7-Zip\7z.exe"
    if (-not (Test-Path $7zipPath)) {
        $7zipPath = (Get-Command "7z.exe" -ErrorAction SilentlyContinue).Source
        if (-not $7zipPath) {
            Write-Host "7-Zip not found. Please ensure 7-Zip is installed." -ForegroundColor Red
            exit 1
        }
    }
    
    # Extract .tar from .tar.xz
    Write-Host "Extracting .tar from .tar.xz..." -ForegroundColor Yellow
    $extractArgs1 = @(
        "x", $tempArchivePath,
        "-o$env:TEMP",
        "-y",
        "-bso0", "-bsp0"  # Silent mode, no progress output
    )
    $process1 = Start-Process -FilePath $7zipPath -ArgumentList $extractArgs1 -NoNewWindow -Wait -PassThru
    if ($process1.ExitCode -ne 0) {
        Write-Host "Failed to extract .tar.xz file. 7-Zip error code: $($process1.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    # Create a temporary directory for extraction
    $tempExtractDir = "$env:TEMP\msys2_extract"
    if (-not (Test-Path $tempExtractDir)) {
        New-Item -ItemType Directory -Path $tempExtractDir -Force | Out-Null
    }
    
    # Then extract the content from the .tar to the temporary directory
    Write-Host "Extracting files from .tar..." -ForegroundColor Yellow
    $extractArgs2 = @(
        "x", $tempTarPath,
        "-o$tempExtractDir",
        "-y",
        "-bso0", "-bsp0"  # Silent mode, no progress output
    )
    $process2 = Start-Process -FilePath $7zipPath -ArgumentList $extractArgs2 -NoNewWindow -Wait -PassThru
    if ($process2.ExitCode -ne 0) {
        Write-Host "Failed to extract .tar file. 7-Zip error code: $($process2.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    # Copy extracted files to destination
    Write-Host "Copying files to final destination..." -ForegroundColor Yellow
    if (Test-Path "$tempExtractDir\msys64") {
        # Clear destination directory first if it exists
        if (Test-Path $msys2Path) {
            Remove-Item -Path "$msys2Path\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Copy all files
        Copy-Item -Path "$tempExtractDir\msys64\*" -Destination $msys2Path -Recurse -Force
    } else {
        Write-Host "Error: Extracted MSYS2 directory not found" -ForegroundColor Red
        exit 1
    }
    
    # Clean up temporary files
    Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item $tempArchivePath -Force -ErrorAction SilentlyContinue
    Remove-Item $tempTarPath -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # Verify installation
    if (Test-Path "$msys2Path\usr\bin\bash.exe") {
        Write-Host "MSYS2 installed successfully at $msys2Path" -ForegroundColor Green
    } else {
        Write-Host "MSYS2 installation failed - bash.exe not found" -ForegroundColor Red
        exit 1
    }
}

# Function to set up assembly support
function Setup-AssemblySupport {
    Write-Host "Setting up Assembly development support..." -ForegroundColor Yellow
    
    # Create assembly directories in the current project
    $projectRoot = Get-Location
    $asmDirs = @(
        "asm",
        "asm/include",
        "asm/src",
        "asm/macros",
        "asm/data",
        "asm/lib"
    )
    
    Write-Host "Creating assembly directories..." -ForegroundColor Yellow
    foreach ($dir in $asmDirs) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Host "  Created: $dir" -ForegroundColor Green
        } else {
            Write-Host "  Already exists: $dir" -ForegroundColor Cyan
        }
    }
    
    # Set environment variable to indicate assembly support
    "GBA_ASM_SUPPORT = 1" | Out-File -FilePath "config.local.mk" -Encoding ASCII
    Write-Host "Set GBA_ASM_SUPPORT=1 environment variable" -ForegroundColor Green
    
    Write-Host "Assembly development support setup complete!" -ForegroundColor Green
    Write-Host "Make sure to run 'make reset' to update your build directories." -ForegroundColor Yellow
}

# Component installation based on selection
Write-Host "Starting installation of selected components: $($selectedComponents -join ', ')" -ForegroundColor Cyan

# 7-Zip Installation (if selected)
if ($selectedComponents -contains "7zip") {
    $has7Zip = Get-Command "7z" -ErrorAction SilentlyContinue
    if (-not $has7Zip) {
        Install-7Zip
    } else {
        Write-Host "7-Zip is already installed." -ForegroundColor Green
    }
} else {
    # Check if 7-Zip is needed for other components (msys2)
    if ($selectedComponents -contains "msys2" -and (-not (Get-Command "7z" -ErrorAction SilentlyContinue))) {
        Write-Host "7-Zip is required for MSYS2 installation. Installing 7-Zip..." -ForegroundColor Yellow
        Install-7Zip
    }
}

# MSYS2 Installation (if selected)
if ($selectedComponents -contains "msys2") {
    Install-MSYS2
    $bashPath = "$msys2Path\usr\bin\bash.exe"
} else {
    # If MSYS2 is required for other selected components, ensure it's installed
    if (($selectedComponents -contains "python" -or $selectedComponents -contains "devkitpro") -and 
        (-not (Test-Path "$msys2Path\usr\bin\bash.exe"))) {
        Write-Host "MSYS2 is required for Python and DevkitPro. Installing MSYS2..." -ForegroundColor Yellow
        Install-MSYS2
    }
    $bashPath = "$msys2Path\usr\bin\bash.exe"
}

# Function to repair MSYS2 package installation
function Repair-MSYS2Packages {
    Write-Host "Repairing MSYS2 package system..." -ForegroundColor Yellow
    
    # Set bash path
    $bashPath = "$msys2Path\usr\bin\bash.exe"
    if (-not (Test-Path $bashPath)) {
        Write-Host "Error: bash.exe not found. MSYS2 may not be installed correctly." -ForegroundColor Red
        exit 1
    }
    
    # Ensure bin directory is in PATH inside MSYS2
    Write-Host "Ensuring correct PATH in MSYS2..." -ForegroundColor Yellow
    & $bashPath -c "echo 'export PATH=/usr/bin:/bin:$PATH' > /etc/profile.d/fix_path.sh"
    & $bashPath -c "chmod +x /etc/profile.d/fix_path.sh"
    
    # Initialize MSYS2 shell environment
    & $bashPath -c "source /etc/profile"
    
    # Ensure proper pacman.conf exists
    $pacmanConfExists = & $bashPath -c "test -f /etc/pacman.conf && echo 'EXISTS' || echo 'MISSING'"
    if ($pacmanConfExists.Trim() -eq "MISSING") {
        Write-Host "Creating default pacman.conf..." -ForegroundColor Yellow
        $pacmanConf = @'
# See the pacman.conf(5) manpage for option and repository directives

[options]
HoldPkg     = pacman
Architecture = auto
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[mingw32]
Include = /etc/pacman.d/mirrorlist.mingw32

[mingw64]
Include = /etc/pacman.d/mirrorlist.mingw64

[msys]
Include = /etc/pacman.d/mirrorlist.msys
'@
        $pacmanConf | Out-File -FilePath "$msys2Path\etc\pacman.conf" -Encoding ASCII
    }
    
    # Ensure mirrorlist files exist
    $mirrorlistFiles = @(
        "mirrorlist.mingw32",
        "mirrorlist.mingw64",
        "mirrorlist.msys"
    )
    
    foreach ($mirrorFile in $mirrorlistFiles) {
        $mirrorPath = "$msys2Path\etc\pacman.d\$mirrorFile"
        if (-not (Test-Path $mirrorPath)) {
            Write-Host "Creating $mirrorFile..." -ForegroundColor Yellow
            $mirrorContent = @'
# MSYS2 Mirror List
Server = https://mirror.msys2.org/
Server = https://repo.msys2.org/
'@
            $mirrorContent | Out-File -FilePath $mirrorPath -Encoding ASCII
        }
    }
    
    # Create necessary directories
    Write-Host "Creating necessary directories..." -ForegroundColor Yellow
    $dirs = @(
        "$msys2Path\var\lib\pacman",
        "$msys2Path\var\cache\pacman\pkg",
        "$msys2Path\etc\pacman.d\gnupg"
    )
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # Run pacman directly with full path
    Write-Host "Updating pacman database..." -ForegroundColor Yellow
    $pacmanPath = "$msys2Path\usr\bin\pacman.exe"
    
    if (Test-Path $pacmanPath) {
        # Use --noconfirm to prevent prompts and execute with proper error handling
        try {
            Write-Host "Initializing pacman keys..." -ForegroundColor Yellow
            $keyInitResult = & $bashPath -lc "/usr/bin/pacman-key --init" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to initialize pacman keys. Error: $keyInitResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            }
            
            Write-Host "Populating pacman keys..." -ForegroundColor Yellow
            $keyPopulateResult = & $bashPath -lc "/usr/bin/pacman-key --populate msys2" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to populate pacman keys. Error: $keyPopulateResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            }
            
            Write-Host "Updating package database..." -ForegroundColor Yellow
            $updateResult = & $bashPath -lc "/usr/bin/pacman -Sy --noconfirm" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to update package database. Error: $updateResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            }
            
            # Install core packages if they don't exist
            $corePackages = @(
                "base",
                "bash",
                "pacman",
                "filesystem",
                "msys2-runtime"
            )
            Write-Host "Installing core packages..." -ForegroundColor Yellow
            $coreResult = & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed $($corePackages -join ' ')" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to install core packages. Error: $coreResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            }
            
            # Install build tools
            Write-Host "Installing build tools (make, gcc, etc.)..." -ForegroundColor Yellow
            $buildToolsResult = & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed make gcc diffutils patch git" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to install build tools. Error: $buildToolsResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            } else {
                Write-Host "Build tools installed successfully." -ForegroundColor Green
            }
            
            # Install python and pip
            Write-Host "Installing Python and pip..." -ForegroundColor Yellow
            $pythonResult = & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed python python-pip" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to install Python and pip. Error: $pythonResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            } else {
                Write-Host "Python and pip installed successfully." -ForegroundColor Green
            }
            
            return $true
        }
        catch {
            Write-Host "Error during MSYS2 setup: $_" -ForegroundColor Red
            Write-Host "Continuing with installation anyway, but some components may not work properly." -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host "Pacman binary not found at $pacmanPath." -ForegroundColor Red
        Write-Host "Attempting to download and install a minimal pacman package..." -ForegroundColor Yellow
        
        # Download a minimal pacman package if it doesn't exist
        $pacmanUrl = "https://repo.msys2.org/msys/x86_64/pacman-6.0.2-1-x86_64.pkg.tar.zst"
        $pacmanPkg = "$env:TEMP\pacman.pkg.tar.zst"
        
        try {
            # Download the package
            Invoke-WebRequest -Uri $pacmanUrl -OutFile $pacmanPkg
            
            # Extract using 7-Zip if available
            $7zipPath = "C:\Program Files\7-Zip\7z.exe"
            if (Test-Path $7zipPath) {
                # Extract to MSYS2 path
                & $7zipPath x $pacmanPkg -o"$msys2Path" -y
                
                # Try again to set up pacman
                if (Test-Path $pacmanPath) {
                    try {
                        & $bashPath -lc "/usr/bin/pacman-key --init" 2>&1
                        & $bashPath -lc "/usr/bin/pacman-key --populate msys2" 2>&1
                        & $bashPath -lc "/usr/bin/pacman -Sy --noconfirm" 2>&1
                        return $true
                    } catch {
                        Write-Host "Error during pacman setup after installation: $_" -ForegroundColor Red
                    }
                }
            }
        } catch {
            Write-Host "Failed to install minimal pacman: $_" -ForegroundColor Red
        }
        
        # If we get here, pacman installation failed
        Write-Host "Critical error: pacman could not be installed or found." -ForegroundColor Red
        Write-Host "Continuing with installation anyway, but some components may not work properly." -ForegroundColor Yellow
        return $false
    }
}

# Continue with MSYS2, Python and DevkitPro installation if selected
if ($selectedComponents -contains "msys2" -or $selectedComponents -contains "python" -or $selectedComponents -contains "devkitpro") {
    # Update MSYS2 and install prerequisites
    Write-Host "Configuring MSYS2 and installing prerequisites..." -ForegroundColor Yellow
    try {
        # First, perform a simple diagnostic check on the MSYS2 installation
        Write-Host "Checking MSYS2 installation status..." -ForegroundColor Yellow
        
        # Check for critical MSYS2 binaries directly in the file system
        $msys2Binaries = @(
            @{Name = "pacman"; Path = "$msys2Path\usr\bin\pacman.exe"},
            @{Name = "mkdir"; Path = "$msys2Path\usr\bin\mkdir.exe"},
            @{Name = "bash"; Path = "$msys2Path\usr\bin\bash.exe"},
            @{Name = "grep"; Path = "$msys2Path\usr\bin\grep.exe"}
        )
        
        Write-Host "Checking for MSYS2 binaries:" -ForegroundColor Yellow
        $pacmanExists = $false
        $bashExists = $false
        
        foreach ($binary in $msys2Binaries) {
            if (Test-Path $binary.Path) {
                Write-Host "  $($binary.Name): Found at $($binary.Path)" -ForegroundColor Green
                if ($binary.Name -eq "pacman") { $pacmanExists = $true }
                if ($binary.Name -eq "bash") { $bashExists = $true }
            } else {
                Write-Host "  $($binary.Name): Not found at $($binary.Path)" -ForegroundColor Red
            }
        }
        
        # Also check MSYS2 itself by using bash to check its own environment
        if ($bashExists) {
            Write-Host "Checking MSYS2 internal environment:" -ForegroundColor Yellow
            # Use bash -c to run commands within MSYS2
            $commands = @("pacman", "mkdir", "grep")
            foreach ($cmd in $commands) {
                # Use 'command -v' which is more reliable than 'which'
                $result = & $bashPath -c "PATH=/usr/bin:/bin command -v $cmd 2>/dev/null || echo MISSING"
                if ($result -eq "MISSING") {
                    Write-Host "  ${cmd}: Not found in MSYS2 environment" -ForegroundColor Red
                } else {
                    Write-Host "  ${cmd}: Found in MSYS2 at $result" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  MSYS2 bash not found, cannot check internal environment" -ForegroundColor Red
        }
        
        # Try to repair/fix MSYS2 if pacman is missing
        if (-not $pacmanExists -or -not $bashExists) {
            Write-Host "CRITICAL: Some core components are missing in MSYS2. Attempting repair..." -ForegroundColor Red
            Repair-MSYS2Packages
        }
        
        # Now that we have the base MSYS2 with working pacman, continue with installing packages
        
        # Install Python/pip if needed and selected
        if ($selectedComponents -contains "python" -and -not (Test-Path "$msys2Path\usr\bin\python.exe")) {
            Write-Host "Installing Python and pip packages..." -ForegroundColor Yellow
            # Use the full path to pacman to avoid PATH issues
            $pythonResult = & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed python python-pip" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Failed to install Python and pip. Error: $pythonResult" -ForegroundColor Red
                Write-Host "Trying to update package database first..." -ForegroundColor Yellow
                & $bashPath -lc "/usr/bin/pacman -Sy --noconfirm" | Out-Null
                
                # Try again after updating
                $pythonRetryResult = & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed python python-pip" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed to install Python and pip after update. Error: $pythonRetryResult" -ForegroundColor Red
                    Write-Host "Continuing with installation, but Python will not be available." -ForegroundColor Yellow
                } else {
                    Write-Host "Python and pip installed successfully after package database update." -ForegroundColor Green
                }
            } else {
                Write-Host "Python and pip installed successfully." -ForegroundColor Green
            }
            
            # Verify Python installation
            $pythonCheck = & $bashPath -lc "python --version" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Python installation verified: $pythonCheck" -ForegroundColor Green
            } else {
                Write-Host "Python installation verification failed" -ForegroundColor Red
            }
        } elseif ($selectedComponents -contains "python") {
            Write-Host "Python is already installed." -ForegroundColor Green
        }
        
        # Install DevkitPro if selected
        if ($selectedComponents -contains "devkitpro") {
            # Set up DevkitPro environment
            Write-Host "Setting up DevkitPro..." -ForegroundColor Yellow
            
            # Install DevkitPro keyring
            Write-Host "Installing DevkitPro keyring..." -ForegroundColor Yellow
            $keyringResult = & $bashPath -lc "/usr/bin/curl -O https://pkg.devkitpro.org/devkitpro-keyring.pkg.tar.zst" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to download DevkitPro keyring. Error: $keyringResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            } else {
                $installKeyringResult = & $bashPath -lc "/usr/bin/pacman -U --noconfirm devkitpro-keyring.pkg.tar.zst" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Warning: Failed to install DevkitPro keyring. Error: $installKeyringResult" -ForegroundColor Yellow
                    Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
                }
            }
            
            # Add DevkitPro repository to pacman.conf
            Write-Host "Adding DevkitPro repository..." -ForegroundColor Yellow
            try {
                $pacmanConfPath = "$msys2Path\etc\pacman.conf"
                $pacmanConf = Get-Content $pacmanConfPath
                
                if (-not ($pacmanConf -match "\[dkp-libs\]")) {
                    # Create the content with proper handling of $arch
                    $dkpContent = @"

[dkp-libs]
Server = https://pkg.devkitpro.org/packages

[dkp-windows]
Server = https://pkg.devkitpro.org/packages/windows/${arch}
"@
                    Add-Content -Path $pacmanConfPath -Value $dkpContent
                    Write-Host "DevkitPro repositories added to pacman.conf" -ForegroundColor Green
                } else {
                    Write-Host "DevkitPro repositories already in pacman.conf" -ForegroundColor Green
                }
            } catch {
                Write-Host "Warning: Failed to add DevkitPro repositories to pacman.conf: $_" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            }
            
            # Update pacman database
            Write-Host "Updating pacman database with DevkitPro repositories..." -ForegroundColor Yellow
            $updateResult = & $bashPath -lc "/usr/bin/pacman -Sy --noconfirm" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to update pacman database with DevkitPro repositories. Error: $updateResult" -ForegroundColor Yellow
                Write-Host "Continuing with installation anyway..." -ForegroundColor Yellow
            }
            
            # Install DevkitARM
            Write-Host "Installing DevkitARM..." -ForegroundColor Yellow
            $devkitARMResult = & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed gba-dev" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Failed to install DevkitARM. Error: $devkitARMResult" -ForegroundColor Red
                Write-Host "The installation will continue, but GBA development capabilities may not work properly." -ForegroundColor Yellow
                
                # Try a more focused package install as a fallback
                Write-Host "Attempting to install just DevkitARM as a fallback..." -ForegroundColor Yellow
                $fallbackResult = & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed devkitARM" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Warning: Failed to install DevkitARM as fallback. Error: $fallbackResult" -ForegroundColor Red
                } else {
                    Write-Host "Fallback DevkitARM installation successful." -ForegroundColor Green
                }
            } else {
                Write-Host "DevkitARM installed successfully." -ForegroundColor Green
            }
            
            # Verify DevkitPro installation
            if (-not (Test-Path "$msys2Path\opt\devkitpro" -PathType Container)) {
                Write-Host "DevkitPro installation failed - directory not found at $msys2Path\opt\devkitpro" -ForegroundColor Red
                exit 1
            }
            
            if (-not (Test-Path "$msys2Path\opt\devkitpro\devkitARM\bin" -PathType Container)) {
                Write-Host "DevkitARM binaries not found - installation may be incomplete" -ForegroundColor Red
                exit 1
            }
            
            # Verify environment variables
            if (-not (Test-EnvironmentVariable -VariableName "DEVKITPRO" -ExpectedValue "/opt/devkitpro")) {
                [Environment]::SetEnvironmentVariable("DEVKITPRO", "/opt/devkitpro", [EnvironmentVariableTarget]::Machine)
                Write-Host "Set DEVKITPRO environment variable to /opt/devkitpro" -ForegroundColor Green
            }
            
            if (-not (Test-EnvironmentVariable -VariableName "DEVKITARM" -ExpectedValue "/opt/devkitpro/devkitARM")) {
                [Environment]::SetEnvironmentVariable("DEVKITARM", "/opt/devkitpro/devkitARM", [EnvironmentVariableTarget]::Machine)
                Write-Host "Set DEVKITARM environment variable to /opt/devkitpro/devkitARM" -ForegroundColor Green
            }
            
            # Add the Windows bin paths to PATH
            $devkitProWindowsPath = "$msys2Path\opt\devkitpro"  # Actual Windows path
            $devkitARMWindowsPath = "$devkitProWindowsPath\devkitARM"  # Actual Windows path
            
            # Update PATH to include DevkitARM Windows paths
            $path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            if (-not ($path -like "*$devkitARMWindowsPath\bin*")) {
                [Environment]::SetEnvironmentVariable("PATH", "$path;$devkitARMWindowsPath\bin;$devkitProWindowsPath\tools\bin", "Machine")
                Write-Host "Added DevkitARM and tools to PATH environment variable" -ForegroundColor Green
            }
            
            # Add DevkitPro and Python to PATH
            Write-Host "Adding DevkitPro and Python to PATH..." -ForegroundColor Yellow
            try {
                $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
                $newPath = "$currentPath;$msys2Path\usr\bin"
                [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)
            } catch {
                Write-Host "Failed to update PATH: $_" -ForegroundColor Red
                exit 1
            }
            
            # Verify essential tools
            Write-Host "Verifying essential GBA development tools..." -ForegroundColor Yellow
            
            # Define the essential tools to check
            $devkitBinDir = "$msys2Path\opt\devkitpro\devkitARM\bin"
            $essentialTools = @(
                @{Name = "make"; Command = "which make"; UseBash = $true},
                @{Name = "arm-none-eabi-gcc"; Command = "test -f `"$devkitBinDir\arm-none-eabi-gcc.exe`""; UseBash = $true},
                @{Name = "arm-none-eabi-objcopy"; Command = "test -f `"$devkitBinDir\arm-none-eabi-objcopy.exe`""; UseBash = $true},
                @{Name = "arm-none-eabi-ld"; Command = "test -f `"$devkitBinDir\arm-none-eabi-ld.exe`""; UseBash = $true}
            )
            
            # Add Assembly-specific tools if Assembly development is enabled
            if ($WithAssembly) {
                Write-Host "Assembly development support enabled. Adding Assembly tools to verification." -ForegroundColor Cyan
                $essentialTools += @(
                    @{Name = "arm-none-eabi-as"; Command = "test -f `"$devkitBinDir\arm-none-eabi-as.exe`""; UseBash = $true},
                    @{Name = "arm-none-eabi-objdump"; Command = "test -f `"$devkitBinDir\arm-none-eabi-objdump.exe`""; UseBash = $true}
                )
            }
            
            # Check each essential tool
            $missingTools = @()
            foreach ($tool in $essentialTools) {
                Write-Host "  Checking for $($tool.Name)..." -NoNewline
                if ($tool.UseBash) {
                    $result = & $bashPath -lc "$($tool.Command)" 
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "FOUND" -ForegroundColor Green
                    } else {
                        Write-Host "MISSING" -ForegroundColor Red
                        $missingTools += $tool.Name
                    }
                } else {
                    if (Get-Command $tool.Name -ErrorAction SilentlyContinue) {
                        Write-Host "FOUND" -ForegroundColor Green
                    } else {
                        Write-Host "MISSING" -ForegroundColor Red
                        $missingTools += $tool.Name
                    }
                }
            }
            
            # Install missing tools if any
            if ($missingTools.Count -gt 0) {
                Write-Host "Some essential tools appear to be missing. Checking installation..." -ForegroundColor Yellow
                
                # Verify DevkitPro installation 
                if (-not (Test-Path "$msys2Path\opt\devkitpro\devkitARM\bin")) {
                    Write-Host "DevkitPro installation directory structure appears incorrect." -ForegroundColor Red
                    Write-Host "Attempting to reinstall DevkitPro tools..." -ForegroundColor Yellow
                    
                    # Reinstall GBA development tools
                    & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed gba-dev" | Out-Null
                }
                
                # Install make if missing
                if ($missingTools -contains "make") {
                    Write-Host "Installing make..." -ForegroundColor Yellow
                    & $bashPath -lc "/usr/bin/pacman -S --noconfirm --needed make" | Out-Null
                }
                
                # Verify again after installation
                $stillMissing = @()
                foreach ($tool in $essentialTools) {
                    if ($tool.UseBash) {
                        $result = & $bashPath -lc "$($tool.Command)" 
                        if ($LASTEXITCODE -ne 0) {
                            $stillMissing += $tool.Name
                        }
                    } else {
                        if (-not (Get-Command $tool.Name -ErrorAction SilentlyContinue)) {
                            $stillMissing += $tool.Name
                        }
                    }
                }
                
                if ($stillMissing.Count -gt 0) {
                    Write-Host "Warning: Some tools still could not be verified:" -ForegroundColor Yellow
                    foreach ($tool in $stillMissing) {
                        Write-Host "  - $tool" -ForegroundColor Yellow
                    }
                    Write-Host "These tools should be available after restarting your terminal." -ForegroundColor Yellow
                } else {
                    Write-Host "All essential tools have been verified or installed!" -ForegroundColor Green
                }
            } else {
                Write-Host "All essential GBA development tools are installed!" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error during installation: $_" -ForegroundColor Red
        Write-Host "Installation will continue but some components might not work properly." -ForegroundColor Yellow
    }
}

# Assembly support installation (if selected or WithAssembly is true)
if ($WithAssembly) {
    Setup-AssemblySupport
}

# Output installation summary
Write-Host "`nInstallation summary:" -ForegroundColor Cyan
foreach ($component in $AVAILABLE_COMPONENTS) {
    $installed = $false
    
    if ($component -eq "assembly") {
        $installed = $WithAssembly
    } else {
        $installed = $selectedComponents -contains $component
    }
    
    if ($installed) {
        Write-Host "  $component - Installed" -ForegroundColor Green
    } else {
        Write-Host "  $component - Not selected for installation" -ForegroundColor Cyan
    }
}

Write-Host "`nIMPORTANT: You MUST restart your terminal or PowerShell window" -ForegroundColor Yellow
Write-Host "           for the installed tools to be accessible from the command line." -ForegroundColor Yellow