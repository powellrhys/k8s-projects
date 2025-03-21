# Define script variables
$container_name = 'k8s-simple_flask_app'

# Configure minikube to run kubernetes locally
.\..\scripts\configure-minikube.ps1

# Build Container within minikube context
.\..\scripts\build-container.ps1 -container_name $container_name

# Deploy application
Write-Host "Deploying application..."
kubectl apply -f config/deployment.yml
Write-Host "Application deployed`n"

# Ensure all pods are up and running before proceeding
.\..\scripts\monitor-pod-status.ps1

# Report pods status
Write-Host "Exposing application..."
minikube service flask-service    
