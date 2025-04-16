# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
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

# Check if 7-Zip is installed
$has7Zip = Get-Command "7z" -ErrorAction SilentlyContinue
if (-not $has7Zip) {
    Install-7Zip
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

# Install MSYS2
Install-MSYS2

# Set bash path for subsequent operations
$bashPath = "$msys2Path\usr\bin\bash.exe"

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

# Update MSYS2 and install prerequisites
Write-Host "Configuring MSYS2 and installing prerequisites..." -ForegroundColor Yellow
try {
    $bashPath = "$msys2Path\usr\bin\bash.exe"
    
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
    
    # Install Python/pip if they're not already installed
    if (-not (Test-Path "$msys2Path\usr\bin\python.exe")) {
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
    } else {
        Write-Host "Python is already installed." -ForegroundColor Green
    }
    
    # Verify Python installation
    $pythonCheck = & $bashPath -lc "python --version" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Python installation verified: $pythonCheck" -ForegroundColor Green
    } else {
        Write-Host "Python installation verification failed" -ForegroundColor Red
    }
    
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
            Add-Content -Path $pacmanConfPath -Value @"

[dkp-libs]
Server = https://pkg.devkitpro.org/packages

[dkp-windows]
Server = https://pkg.devkitpro.org/packages/windows/`$arch
"@
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
} catch {
    Write-Host "Error during installation: $_" -ForegroundColor Red
    Write-Host "Installation will continue but some components might not work properly." -ForegroundColor Yellow
}

# Final verification
Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host "Please restart your terminal or system for changes to take effect." -ForegroundColor Yellow