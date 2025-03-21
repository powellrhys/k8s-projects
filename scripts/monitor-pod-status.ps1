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
