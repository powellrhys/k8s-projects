# Define script variables
$container_name = 'k8s-simple-database-app'
$sql_username = 'sa'
$sql_password = 'YourPassword123'
$sql_db = 'mydatabase'
$sql_table = "users"

# Configure minikube to run kubernetes locally
.\..\scripts\configure-minikube.ps1

# Build Container within minikube context
cd frontend
.\..\..\scripts\build-container.ps1 -container_name $container_name
cd ..

# Deploy application
Write-Host "Deploying application..."
kubectl apply -f config/sqlserver-secret.yml
kubectl apply -f config/sqlserver-pvc.yml
kubectl apply -f config/sqlserver-deployment.yml
kubectl apply -f config/streamlit-deployment.yml
Write-Host "Application deployed`n"

# Ensure all pods are up and running before proceeding
.\..\scripts\monitor-pod-status.ps1

# Forward database entrypoint to localhost
Write-Host "Port forwarding SQL Server service..."
Start-Job -ScriptBlock {
    kubectl port-forward svc/sqlserver-service 1433:1433
}
Start-Sleep -Seconds 5

Write-Host "Logging into SQL Server"

# Create database if it doesn't exist
Write-Host "Configuring database..."
$sql_query = @"
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '$sql_db')
    CREATE DATABASE $sql_db
"@
sqlcmd -S localhost,1433 -U $sql_username -P $sql_password -Q $sql_query

# Create table if it doesn't exist
Write-Host "Configure SQL table..."
$table_query = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '$sql_table' AND schema_id = SCHEMA_ID('dbo'))
    CREATE TABLE dbo.$sql_table (
        id INT PRIMARY KEY IDENTITY,
        name NVARCHAR(100),
        email NVARCHAR(100) UNIQUE
    )
"@
sqlcmd -S localhost,1433 -U $sql_username -P $sql_password -d $sql_db -Q $table_query

# Define insert into table if data is currently there
Write-Host "Inserting data into SQL table...`n"
$insert_query = @"
IF NOT EXISTS (SELECT 1 FROM dbo.$sql_table)
    INSERT INTO dbo.$sql_table (name, email) 
    VALUES ('John', 'John@example.com')
"@
sqlcmd -S localhost,1433 -U $sql_username -P $sql_password -d $sql_db -Q $insert_query

# Report pods status
Write-Host "Exposing application..."
minikube service streamlit-service    
