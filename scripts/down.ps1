$ErrorActionPreference = "Stop"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw "Terraform is required. Install Terraform >= 1.6.0 and retry."
}

$terraformDirectory = Join-Path $PSScriptRoot "..\terraform"
Push-Location $terraformDirectory
try {
    terraform destroy -auto-approve
    if ($LASTEXITCODE -ne 0) {
        throw "terraform destroy failed."
    }
}
finally {
    Pop-Location
}
