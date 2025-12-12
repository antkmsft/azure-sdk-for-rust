<#
.SYNOPSIS
    Builds a specific Azure SDK package using cargo.

.DESCRIPTION
    This script validates the package path, installs workspace dependencies, and builds 
    the specified Azure SDK package using the cargo build system.

.PARAMETER PackagePath
    The absolute path to the SDK package directory. Must contain a valid Cargo.toml file.

.EXAMPLE
    .\automation_build_sdk.ps1 -PackagePath "C:\repo\azure-sdk-for-rust\sdk\storage\azure_storage_blob"

    Builds the azure_storage_blob package with dependency installation.

.NOTES
    Requires cargo to be installed and available in PATH.

.PARAMETER PackagePath
    The absolute path to the SDK package directory. Must contain a valid Cargo.toml file.

.EXAMPLE
    .\automation_build_sdk.ps1 -PackagePath "C:\repo\azure-sdk-for-rust\sdk\storage\azure_storage_blob"

    Builds the azure_storage_blob package with dependency installation.

.NOTES
    Requires cargo to be installed and available in PATH.
    Should be run from the Azure SDK for Rust repository root or with absolute paths.
#>

# Build a specific Azure SDK package using cargo
# This script validates the package path, installs dependencies, and builds the package

[CmdletBinding(SupportsShouldProcess = $true)]
param (
  [Parameter(Mandatory = $true, HelpMessage = "Absolute path to the SDK package directory")]
  [string]$PackagePath
)


# Validates package path and extracts package information
function Get-PackageInfo {
  param (
    [Parameter(Mandatory = $true)]
    [string]$PackagePath
  )
  
  try {
    # Install the PSToml module
    Install-Module -Name PSToml -Scope CurrentUser

    $resolvedPath = Resolve-Path $PackagePath -ErrorAction Stop
    $cargoTomlPath = Join-Path $resolvedPath "Cargo.toml"

    if (-not (Test-Path $cargoTomlPath)) {
      throw "Cargo.toml not found at: $cargoTomlPath"
    }

    Write-Host "Reading Cargo.toml from: $cargoTomlPath"

    $cargoToml = Get-Content $cargoTomlPath -Raw | ConvertFrom-Toml -ErrorAction Stop

    if (-not $cargoToml.package.name) {
      throw "'package.name' field not found in Cargo.toml"
    }
    
    return [PSCustomObject]@{
      Name    = $cargoToml.package.name
      Path    = $resolvedPath
      Version = $cargoToml.package.version ?? "unknown"
    }
  }
  catch {
    Write-Host "Error processing package: $($_.Exception.Message)"
    throw
  }
}

# Main execution
try {
  # Extract package information
  $packageInfo = Get-PackageInfo -PackagePath $PackagePath

  Write-Host "Building package: $($packageInfo.Name) (v$($packageInfo.Version))"
  Write-Host "Package path: $($packageInfo.Path)"
    
  try {
    # Install dependencies
    Write-Host "Installing dependencies..."
    cargo install
    if ($LASTEXITCODE -ne 0) {
      throw "cargo install failed with exit code $LASTEXITCODE"
    }
    Write-Host "Dependencies installed successfully"
    
    # Build the package
    Write-Host "Building package with cargo..."
    cargo build --package $packageInfo.Name
    if ($LASTEXITCODE -ne 0) {
      throw "cargo build failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Build completed successfully!"
  }
  finally {
    Pop-Location
  }
}
catch {
  Write-Host "Build failed: $($_.Exception.Message)"
  exit 1
}
