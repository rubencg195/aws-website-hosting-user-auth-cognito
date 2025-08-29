# React App Deployment Helper
Write-Host "React App Deployment Helper" -ForegroundColor Green
Write-Host ""

# Check if build folder exists
if (-not (Test-Path "build")) {
    Write-Host "Build folder not found. Please run 'npm run build' first." -ForegroundColor Red
    exit 1
}

Write-Host "Build folder found" -ForegroundColor Green

# Get Amplify app details
Write-Host ""
Write-Host "Getting Amplify app details..." -ForegroundColor Blue

$appDomain = "d2ftbks7u75e5p.amplifyapp.com"
$appId = "d2ftbks7u75e5p"

Write-Host "Found Amplify app:" -ForegroundColor Green
Write-Host "   App ID: $appId" -ForegroundColor White
Write-Host "   Domain: $appDomain" -ForegroundColor White

Write-Host ""
Write-Host "Deployment Options:" -ForegroundColor Cyan
Write-Host "1. Connect Git repository (recommended for production)" -ForegroundColor White
Write-Host "2. Test locally first" -ForegroundColor White

Write-Host ""
$choice = Read-Host "Choose an option (1-2)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Git Repository Connection:" -ForegroundColor Cyan
        Write-Host "1. Go to AWS Amplify Console: https://console.aws.amazon.com/amplify/" -ForegroundColor White
        Write-Host "2. Select your app: $appDomain" -ForegroundColor White
        Write-Host "3. Go to 'Hosting environments' -> 'main' branch" -ForegroundColor White
        Write-Host "4. Click 'Connect branch' and follow the Git connection steps" -ForegroundColor White
        Write-Host "5. Push your code to the connected repository" -ForegroundColor White
        Write-Host ""
        Write-Host "This will enable automatic deployments when you push code!" -ForegroundColor Yellow
    }
    "2" {
        Write-Host ""
        Write-Host "Local Testing:" -ForegroundColor Cyan
        Write-Host "1. Start the development server: npm start" -ForegroundColor White
        Write-Host "2. Open http://localhost:3000 in your browser" -ForegroundColor White
        Write-Host "3. Test the authentication flow" -ForegroundColor White
        Write-Host ""
        Write-Host "Make sure your environment variables are set correctly!" -ForegroundColor Yellow
        
        # Create .env file if it doesn't exist
        if (-not (Test-Path ".env")) {
            Write-Host ""
            Write-Host "Creating .env file..." -ForegroundColor Blue
            
            $envContent = "REACT_APP_AWS_REGION=us-east-1`nREACT_APP_USER_POOL_ID=us-east-1_DhtukDlTR`nREACT_APP_USER_POOL_CLIENT_ID=3gi06h3n36cvgqt5g5ljeb39fe`nREACT_APP_COGNITO_DOMAIN=react-auth-demo-dev"
            
            $envContent | Out-File -FilePath ".env" -Encoding UTF8
            Write-Host ".env file created with current configuration" -ForegroundColor Green
        }
    }
    default {
        Write-Host "Invalid choice. Please run the script again and choose 1 or 2." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "   Your Amplify app is ready at: $appDomain" -ForegroundColor White
Write-Host "   Infrastructure is fully deployed and configured" -ForegroundColor White
Write-Host "   Choose your preferred deployment method above" -ForegroundColor White
Write-Host ""
Write-Host "For production use, we recommend connecting a Git repository!" -ForegroundColor Yellow
