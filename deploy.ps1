# PowerShell Deployment Script for React Authentication Demo
# This script automates the deployment of AWS infrastructure using OpenTofu

Write-Host "🚀 Starting deployment of React Authentication Demo infrastructure..." -ForegroundColor Green
Write-Host ""

# Check if OpenTofu is installed
try {
    $tofuVersion = tofu --version
    Write-Host "✅ OpenTofu found: $tofuVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ OpenTofu not found. Please install OpenTofu first." -ForegroundColor Red
    Write-Host "Visit: https://opentofu.org/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

# Check if AWS CLI is configured
try {
    $awsAccount = aws sts get-caller-identity --query Account --output text 2>$null
    if ($awsAccount) {
        Write-Host "✅ AWS CLI configured for account: $awsAccount" -ForegroundColor Green
    } else {
        Write-Host "❌ AWS CLI not configured. Please run 'aws configure' first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ AWS CLI not found or not configured. Please install and configure AWS CLI first." -ForegroundColor Red
    Write-Host "Visit: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🔧 Initializing OpenTofu..." -ForegroundColor Blue
tofu init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ OpenTofu initialization failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 Planning deployment..." -ForegroundColor Blue
tofu plan

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ OpenTofu plan failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🚀 Applying infrastructure changes..." -ForegroundColor Blue
tofu apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ OpenTofu apply failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Infrastructure Summary:" -ForegroundColor Cyan
Write-Host "  • AWS Cognito User Pool: Created" -ForegroundColor White
Write-Host "  • AWS Cognito User Pool Client: Created" -ForegroundColor White
Write-Host "  • AWS Cognito User Pool Domain: Created" -ForegroundColor White
Write-Host "  • AWS Amplify App: Created" -ForegroundColor White
Write-Host "  • AWS Amplify Branch: Created" -ForegroundColor White
Write-Host "  • AWS IAM Role: Created" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test locally: npm start" -ForegroundColor White
Write-Host "  2. Connect Git repository to AWS Amplify" -ForegroundColor White
Write-Host "  3. Push code to trigger automatic deployment" -ForegroundColor White
Write-Host ""
Write-Host "💡 To destroy infrastructure when done, run: .\destroy.ps1" -ForegroundColor Yellow
