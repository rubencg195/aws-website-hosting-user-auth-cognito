# React Authentication Demo Infrastructure Destruction Script
# This script destroys the deployed infrastructure

Write-Host "Starting destruction of React Auth Demo infrastructure..." -ForegroundColor Red

# Check if OpenTofu is installed
Write-Host "Checking OpenTofu installation..." -ForegroundColor Blue
try {
    $null = Get-Command tofu -ErrorAction Stop
    Write-Host "OpenTofu is installed" -ForegroundColor Green
} catch {
    Write-Host "OpenTofu is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Visit: https://opentofu.org/docs/intro/install/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if AWS CLI is configured
Write-Host "Checking AWS CLI configuration..." -ForegroundColor Blue
try {
    $null = aws sts get-caller-identity 2>$null
    Write-Host "AWS CLI is configured" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI is not configured. Please run 'aws configure' first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Prerequisites check passed" -ForegroundColor Green

# Check if OpenTofu is initialized
if (-not (Test-Path ".terraform")) {
    Write-Host "OpenTofu is not initialized. Run 'tofu init' first or use the deploy script." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Plan the destruction
Write-Host "Planning infrastructure destruction..." -ForegroundColor Blue
tofu plan -destroy
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create destruction plan" -ForegroundColor Red
    exit 1
}
Write-Host "Destruction plan completed successfully" -ForegroundColor Green

# Show warning about what will be destroyed
Write-Host ""
Write-Host "WARNING: This will destroy the following resources:" -ForegroundColor Yellow
Write-Host "   - AWS Cognito User Pool and Client" -ForegroundColor White
Write-Host "   - AWS Amplify App and Branch" -ForegroundColor White
Write-Host "   - IAM Role and Policy" -ForegroundColor White
Write-Host "   - All associated data and configurations" -ForegroundColor White
Write-Host ""

# Auto-approve destruction
Write-Host "Auto-approving destruction..." -ForegroundColor Yellow

# Apply the destruction
Write-Host "Destroying infrastructure..." -ForegroundColor Red
tofu destroy -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to destroy infrastructure" -ForegroundColor Red
    exit 1
}
Write-Host "Infrastructure destruction completed!" -ForegroundColor Green

# Show completion message
Write-Host ""
Write-Host "Destruction Summary:" -ForegroundColor Cyan
Write-Host "   - All AWS resources have been removed" -ForegroundColor White
Write-Host "   - Infrastructure state has been cleared" -ForegroundColor White
Write-Host "   - You can now redeploy from scratch if needed" -ForegroundColor White

Write-Host ""
Write-Host "Infrastructure destruction completed successfully!" -ForegroundColor Green
Write-Host "To redeploy, run: .\deploy.ps1" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
