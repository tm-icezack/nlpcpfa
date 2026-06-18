# ================================================
# Deploy artefact from /Dev to /Test via REST API
# ================================================

$BaseUrl    = "https://your-bi-server/api/v2.0"
$Token      = "Bearer YOUR_ACCESS_TOKEN"
$Headers    = @{ Authorization = $Token; "Content-Type" = "application/json" }

# ------------------------------------------------
# STEP 1: Copy artefact from /Dev → /Test
# ------------------------------------------------

$Body = @{
    catalogItemPaths = @("/Dev/Reports/SalesReport")
    targetPath       = "/Test/Reports"
    overwrite        = $true
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri     "$BaseUrl/CatalogItems/Model.CopyItems" `
    -Method  POST `
    -Headers $Headers `
    -Body    $Body

Write-Host "Artefact copied to /Test"

# ------------------------------------------------
# STEP 2: Trigger a dataset refresh in /Test
# ------------------------------------------------

$DatasetId = "your-dataset-guid-here"

Invoke-RestMethod `
    -Uri     "$BaseUrl/datasets/$DatasetId/refreshes" `
    -Method  POST `
    -Headers $Headers

Write-Host "Refresh triggered for /Test dataset"