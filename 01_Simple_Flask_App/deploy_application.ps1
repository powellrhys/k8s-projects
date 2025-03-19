# Define script variables
$container_name = 'k8s-simple_flask_app'

$minikubeStatus = minikube status 2>$null

if ($minikubeStatus -match "Host: Running") {
    Write-Output "Minikube is already running."
} elseif ($minikubeStatus -match "Profile .* not found") {
    Write-Output "No Minikube profile found. Starting a new Minikube cluster..."
    minikube start
} else {
    Write-Output "Minikube is NOT running. Starting now..."
    minikube start
}
Write-Host "Minikube has been successfully configured`n"

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

# Deploy application
Write-Host "Deploying application..."
kubectl apply -f config/deployment.yml
Write-Host "Application deployed`n"

Write-Output "Waiting for all pods to be in 'Running' state..."

do {
    # Get the status of all pods in the default namespace
    $podStatus = kubectl get pods --no-headers | ForEach-Object { ($_ -split "\s+")[2] }

    # Check if all pods are running
    $allRunning = $podStatus -match "^Running$"

    # Wait for a few seconds before checking again
    if (-not $allRunning) {
        Start-Sleep -Seconds 5
        Write-Output "Still waiting for pods to be ready..."
    }

} while (-not $allRunning)

Write-Output "All pods are running!`n"

# Report pods status
Write-Host "Exposing application..."
minikube service flask-service    
