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
