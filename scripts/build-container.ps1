param (
    [string]$container_name
)

# Change docker build context to point towards minikube's internal docker daemon
Write-Host "Switching docker build context..."
minikube docker-env | Invoke-Expression
Write-Host "Minikube internal docker daemon configured`n"

# Build docker container
Write-Host "Building docker $($container_name)...`n"
try {
    docker build -t $container_name .
    Write-Host "`nContainer $($container_name) successfully built`n"
} catch {
    Write-Host "`nFailed to build $($container_name)`n"
}
