# Define script variables
$container_name = 'k8s-simple-database-app'

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
    cd frontend
    docker build -t $container_name .
    cd ..
    Write-Host "`nContainer $($container_name) successfully built`n"
} catch {
    Write-Host "`nFailed to build $($container_name)`n"
}

# Deploy application
Write-Host "Deploying application..."
kubectl apply -f config/sqlserver-secret.yml
kubectl apply -f config/sqlserver-pvc.yml
kubectl apply -f config/sqlserver-deployment.yml
kubectl apply -f config/streamlit-deployment.yml
Write-Host "Application deployed`n"

Write-Output "Waiting for all pods to be in 'Running' state..."

do {
    # Get the status of all pods in the default namespace
    $podStatus = kubectl get pods --no-headers | ForEach-Object { ($_ -split "\s+")[2] }

    # Assume all pods are running unless we find one that isn't
    $allRunning = $true

    foreach ($status in $podStatus) {
        if ($status -ne "Running") {
            $allRunning = $false
            break
        }
    }

    # Wait and retry if not all pods are running
    if (-not $allRunning) {
        Start-Sleep -Seconds 5
        Write-Output "Still waiting for pods to be ready..."
        kubectl get pods
    }

} while (-not $allRunning)

Write-Output "All pods are running!`n"


Write-Host "Port forwarding SQL Server service..."
Start-Job -ScriptBlock {
    kubectl port-forward svc/sqlserver-service 1433:1433
}

Start-Sleep -Seconds 5  # Wait for the port forward to establish

Write-Host "Logging into SQL Server"

# Connect using localhost now that port-forward is running
sqlcmd -S localhost,1433 -U sa -P 'YourPassword123' -Q "SELECT name FROM sys.databases"

# Create database if it doesn't exist
sqlcmd -S localhost,1433 -U sa -P 'YourPassword123' -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'mydatabase') CREATE DATABASE mydatabase"

# Create table
sqlcmd -S localhost,1433 -U sa -P 'YourPassword123' -d mydatabase -Q "CREATE TABLE users (id INT PRIMARY KEY IDENTITY, name NVARCHAR(100), email NVARCHAR(100) UNIQUE)"

# Insert data
sqlcmd -S localhost,1433 -U sa -P 'YourPassword123' -d mydatabase -Q "INSERT INTO users (name, email) VALUES ('Rhys', 'rhys@example.com');"

# Verify table exists
sqlcmd -S localhost,1433 -U sa -P 'YourPassword123' -d mydatabase -Q "SELECT name FROM sys.tables WHERE name = 'users'"

# Retrieve data
sqlcmd -S localhost,1433 -U sa -P 'YourPassword123' -d mydatabase -Q "SELECT * FROM users"

# Report pods status
Write-Host "Exposing application..."
minikube service streamlit-service    
