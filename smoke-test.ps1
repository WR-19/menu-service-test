param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [int]$MaxAttempts = 5,
    [int]$DelaySeconds = 10
)

$endpoints = @(
    "$BaseUrl/health",
    "$BaseUrl/menu/LHR-T5-001"
)

foreach ($endpoint in $endpoints) {
    $healthy = $false

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Host "OK: $endpoint returned 200 (attempt $attempt)"
                $healthy = $true
                break
            }
            Write-Host "Attempt ${attempt}: $endpoint returned $($response.StatusCode)"
        }
        catch {
            Write-Host "Attempt ${attempt}: $endpoint failed - $($_.Exception.Message)"
        }

        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    if (-not $healthy) {
        Write-Error "Smoke test failed: $endpoint did not return 200 after $MaxAttempts attempts"
        exit 1
    }
}

Write-Host "Smoke test passed: all endpoints healthy"
exit 0
