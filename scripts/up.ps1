$ErrorActionPreference = "Stop"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw "Terraform is required. Install Terraform >= 1.6.0 and retry."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is required to create the Kind cluster."
}

if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    throw "Kind is required. Install Kind and retry."
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl is required. Install kubectl and retry."
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker is not running. Start Docker or Rancher Desktop and retry."
}

$terraformDirectory = Join-Path $PSScriptRoot "..\terraform"
Push-Location $terraformDirectory
try {
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "terraform init failed."
    }

    terraform apply "-target=kind_cluster.tech_challenge" -auto-approve
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create the Kind cluster."
    }

    kind export kubeconfig --name tech-challenge
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to configure the Kind kubeconfig."
    }

    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install local persistent volume support."
    }

    kubectl patch storageclass local-path --type=merge -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set the local storage class as the cluster default."
    }

    kubectl wait --for=condition=Available deployment/local-path-provisioner -n local-path-storage --timeout=2m
    if ($LASTEXITCODE -ne 0) {
        throw "Local persistent volume provisioner did not become ready."
    }

    terraform apply -auto-approve
    if ($LASTEXITCODE -ne 0) {
        throw "terraform apply failed."
    }

    terraform output
}
finally {
    Pop-Location
}
