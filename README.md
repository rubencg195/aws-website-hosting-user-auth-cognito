# React Authentication Demo with AWS Cognito and Amplify

This project demonstrates a complete React.js application with authentication handled by AWS Cognito, hosted on AWS Amplify, and deployed using OpenTofu (formerly Terraform).

## 🏗️ Architecture

- **Frontend**: React.js with AWS Amplify UI components
- **Authentication**: AWS Cognito User Pool
- **Hosting**: **Dual hosting options**:
  - AWS Amplify (with Git integration)
  - AWS S3 + CloudFront (Static Website Hosting)
- **Infrastructure as Code**: OpenTofu
- **Cloud Provider**: AWS
- **Build Automation**: Local npm build + S3 sync via Terraform

## 🚀 Features

- User registration and authentication
- Protected routes and components
- Responsive UI with Amplify UI components
- **Dual hosting options**:
  - AWS Amplify with Git integration and auto-deploy
  - S3 + CloudFront with local build automation
- **Automated build and deployment** via OpenTofu local-exec
- **S3 static website hosting** with CloudFront CDN
- **Enhanced file handling** with proper MIME types and content validation
- Infrastructure as Code with OpenTofu
- **Local development and testing** with proper debugging

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Node.js](https://nodejs.org/) (v16 or higher)
- [OpenTofu](https://opentofu.org/docs/intro/install/) (v1.0 or higher)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with permissions for Cognito, Amplify, and IAM

## 🚀 Quick Deployment

**Deploy everything with one command:**
```bash
# Initialize (first time only)
tofu init

# Deploy everything
tofu apply -auto-approve
```

This will:
- ✅ Deploy all AWS infrastructure (Cognito, S3, CloudFront, Amplify)
- ✅ Build your React app locally
- ✅ Upload to S3 automatically
- ✅ Configure CloudFront distribution
- ✅ Provide all URLs and endpoints

**Clean up when done:**
```bash
tofu destroy -auto-approve
```

---

## 🛠️ Installation & Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd aws-website-hosting-user-auth-cognito
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Configure AWS Credentials

```bash
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, default region, and output format.

### 4. Deploy Everything (Infrastructure + App)

#### Deploy with OpenTofu:
```bash
# Initialize OpenTofu (first time only)
tofu init

# Plan the deployment
tofu plan

# Apply the configuration
tofu apply -auto-approve
```

**This will deploy everything:**
- AWS infrastructure (Cognito, S3, CloudFront, Amplify)
- Build the React application locally
- Upload built files to S3 automatically
- Configure CloudFront distribution
- Provide all URLs and endpoints

### 5. Your React App is Automatically Deployed!

**No additional steps needed!** OpenTofu automatically:
- Builds your React app locally
- Uploads it to S3
- Configures CloudFront distribution
- Sets up all environment variables

**Environment variables are automatically configured** in the deployed application.

### 6. Update Cognito URLs (Important!)

After the initial deployment, you need to update the Cognito callback and logout URLs to include your actual CloudFront and Amplify URLs:

1. **Get your URLs from the deployment output:**
   ```bash
   tofu output
   ```

2. **Update the URLs in `locals.tf`:**
   ```hcl
   cognito_urls = {
     localhost_https = "https://localhost:3000"
     localhost_http  = "http://localhost:3000"
     cloudfront      = "https://YOUR_ACTUAL_CLOUDFRONT_URL"  # Update this
     amplify         = "https://main.YOUR_AMPLIFY_APP_ID.amplifyapp.com"  # Update this
   }
   ```

3. **Apply the URL updates:**
   ```bash
   tofu apply -auto-approve
   ```

**Why this step is needed:** Cognito needs to know which URLs are allowed for authentication callbacks. The initial deployment uses localhost placeholders to avoid circular dependencies.

**Current Status:** Your Cognito User Pool Client is configured with localhost URLs only. Authentication will work locally but will fail from CloudFront and Amplify until you update these URLs.

### 7. Destroy Infrastructure (Optional)

When you're done with the demo, you can destroy the infrastructure to avoid ongoing AWS charges:

```bash
# Destroy all AWS resources
tofu destroy -auto-approve
```

**Warning**: This will permanently delete all AWS resources created by this project.

## 🔄 Complete Deployment Workflow

### Step-by-Step Deployment Process

1. **🚀 Deploy Everything**
   ```bash
   tofu apply -auto-approve
   ```
   - Creates AWS Cognito User Pool
   - Sets up AWS Amplify App (with Git integration)
   - Sets up S3 bucket and CloudFront distribution
   - Runs `npm ci` and `npm run build` locally
   - Uploads built files to S3 automatically
   - Outputs both Amplify and CloudFront URLs

2. **✅ Choose Your Hosting Option**

   **Option A: Amplify Hosting (Git-based)**
   - Connect your Git repository via Amplify Console
   - Every push triggers automatic deployment
   - Perfect for team development

   **Option B: S3 + CloudFront (Local build)**
   - Visit your CloudFront URL (HTTPS)
   - Run `.\deploy.ps1` again for updates
   - Perfect for solo development

3. **🧪 Test Your App**
   - Test authentication flow
   - Verify Cognito integration

### Manual Rebuild and Deploy

**For future updates, you can:**
```powershell
# Option 1: Full redeploy (infrastructure + build + upload)
.\deploy.ps1

# Option 2: Manual build and upload only
.\build-and-deploy.ps1

# Option 3: Git-based deployment (if using Amplify)
git add . && git commit -m "update" && git push
```

### Environment Variables Created

The deployment scripts automatically create a `.env` file with:
```bash
REACT_APP_AWS_REGION=us-east-1
REACT_APP_USER_POOL_ID=us-east-1_DhtukDlTR
REACT_APP_USER_POOL_CLIENT_ID=3gi06h3n36cvgqt5g5ljeb39fe
REACT_APP_COGNITO_DOMAIN=react-auth-demo-dev
```

### Quick Commands Reference

```bash
# Full deployment workflow
tofu apply -auto-approve        # Deploy everything (infrastructure + app)

# Git-based deployment (if using Amplify)
git add . && git commit -m "update" && git push  # Triggers Amplify auto-deploy

# Cleanup when done
tofu destroy -auto-approve      # Remove all AWS resources
```

## 🧪 Local Development and Testing

### Starting Local Development Server

```bash
npm start
```

The application will open at `http://localhost:3000`

### Environment Variables for Local Testing

**Important**: The `.env` file must be in the root directory of your project (same level as `package.json`).

#### Automatic Creation (Recommended):
The `.env` file is automatically created during deployment. If you need to recreate it, copy the values from the deployment output.

#### Manual Creation:
Create a `.env` file in your project root with:
```bash
REACT_APP_AWS_REGION=us-east-1
REACT_APP_USER_POOL_ID=us-east-1_DhtukDlTR
REACT_APP_USER_POOL_CLIENT_ID=3gi06h3n36cvgqt5g5ljeb39fe
REACT_APP_COGNITO_DOMAIN=react-auth-demo-dev
```

**Note**: Replace the values above with your actual Cognito configuration from the infrastructure deployment.

### Local Testing Workflow

1. **Ensure infrastructure is deployed**:
   ```bash
   tofu apply -auto-approve
   ```

2. **Environment variables are created automatically during deployment**

3. **Start local development**:
   ```bash
   npm start
   ```

4. **Test authentication flow**:
   - Open `http://localhost:3000`
   - You should see the Amplify authentication form
   - Test sign-up and sign-in functionality

### Debugging Local Development

#### Console Logging
The app includes debug logging to help troubleshoot configuration issues. Check the browser console (F12) for:
```javascript
Environment variables: {
  region: "us-east-1",
  userPoolId: "us-east-1_DhtukDlTR",
  userPoolClientId: "3gi06h3n36cvgqt5g5ljeb39fe",
  cognitoDomain: "react-auth-demo-dev"
}
```

#### Common Local Development Issues

##### Port 3000 Already in Use
```bash
# Check what's using port 3000
netstat -an | findstr :3000

# Kill all Node processes (Windows)
taskkill /f /im node.exe

# Restart the app
npm start
```

##### Environment Variables Not Loading
- Ensure `.env` file is in the project root
- Restart the development server after creating `.env`
- Check that variable names start with `REACT_APP_`

##### Build Failures
```bash
# Clean and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

## 🏗️ Infrastructure Components

### AWS Cognito
- **User Pool**: Manages user accounts and authentication
- **User Pool Client**: Web application client for authentication
- **User Pool Domain**: Custom domain for the hosted UI

### AWS Amplify
- **App**: Main application configuration with build specifications
- **Branch**: Main branch with auto-build and pull request previews
- **Webhook**: Repository integration for Git-based deployments
- **IAM Role**: Permissions for Amplify operations

### AWS S3 + CloudFront (Alternative Hosting)
- **S3 Bucket**: Static website hosting with public read access
- **CloudFront Distribution**: Global CDN with HTTPS and SPA routing support
- **Website Configuration**: Index and error document handling for React Router
- **Local Build Automation**: npm build + S3 sync via Terraform

### Configuration
The following values are configured in the `locals` block:
- Project name: `react-auth-demo`
- Environment: `dev`
- AWS region: `us-east-1`

### Environment Variables
The following environment variables are automatically configured in Amplify:
- `REACT_APP_AWS_REGION`: AWS region
- `REACT_APP_USER_POOL_ID`: Cognito User Pool ID
- `REACT_APP_USER_POOL_CLIENT_ID`: Cognito User Pool Client ID
- `REACT_APP_COGNITO_DOMAIN`: Cognito User Pool Domain

## 🔐 Authentication Flow

1. User visits the application
2. Amplify UI presents login/signup form
3. User authenticates through Cognito
4. JWT tokens are stored locally
5. Protected content is displayed
6. User can sign out to clear session

## 📁 Project Structure

```
├── provider.tf          # AWS provider configuration
├── cognito.tf          # Cognito User Pool and Client
├── amplify.tf          # Amplify App and Branch configuration
├── s3.tf               # S3 bucket and website hosting
├── cloudfront.tf       # CloudFront distribution
├── locals.tf           # Local variables and configuration
├── outputs.tf          # Infrastructure outputs
├── package.json        # Node.js dependencies
├── public/             # Static assets
│   ├── index.html     # Main HTML file
│   └── manifest.json  # PWA manifest
├── src/                # React source code
│   ├── App.js         # Main application component
│   ├── index.js       # Application entry point
│   └── index.css      # Global styles
└── README.md           # This file
```

## 🚀 Deployment

### Prerequisites
Before deploying, ensure you have:
- ✅ OpenTofu installed and configured
- ✅ AWS CLI configured with appropriate permissions
- ✅ Node.js and npm installed for local builds

### Deployment Options

#### Option 1: AWS Amplify Hosting (Git Integration)
**🔗 Connect your Git repository for automatic deployments:**

1. **Deploy everything**:
   ```bash
   tofu apply -auto-approve
   ```

2. **Connect Git repository**:
   - Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
   - Select your app and connect your Git repository
   - Every push triggers automatic build and deploy

**💡 Pro Tip**: Perfect for team development with automatic deployments on every commit!

#### Option 2: S3 + CloudFront Hosting (Local Build)
**🚀 Terraform automatically builds and deploys your React app!**

1. **Deploy infrastructure and build app**:
   ```bash
   tofu apply -auto-approve
   ```
   This will:
   - Create S3 bucket and CloudFront distribution
   - Run `npm ci` and `npm run build` locally
   - Upload built files to S3 automatically
   - Provide CloudFront and S3 URLs

2. **Automatic rebuilds**: Run `tofu apply -auto-approve` again to rebuild and redeploy everything

#### Option 3: Manual Build and Deploy
**🔧 For manual control over the build process:**

1. **Deploy everything automatically** (recommended):
   ```bash
   tofu apply -auto-approve
   ```

2. **Build and deploy manually** (advanced users):
   ```bash
   npm run build
   aws s3 sync build/ s3://your-bucket-name --delete
   ```

**💡 Pro Tip**: The automated deployment handles everything, but you can still build manually if needed!

#### Option 2: Local Testing
1. **Start development server**: `npm start`
2. **Open**: `http://localhost:3000`
3. **Test authentication flow** with your deployed Cognito setup

#### Option 3: Manual Build and Deploy
1. **Build the application**: `npm run build`
2. **Deploy the build folder** to your hosting service

### Deployment Commands

#### Deploy Everything
```bash
# Deploy everything (infrastructure + app)
tofu apply -auto-approve
```

**What it does**:
- Deploys all AWS infrastructure (Cognito, S3, CloudFront, Amplify)
- Builds the React application locally
- Uploads built files to S3 automatically
- Configures CloudFront distribution
- Provides URLs for both hosting options

#### Cleanup Infrastructure
```bash
# Remove all AWS resources when done
tofu destroy -auto-approve
```

**What it does**:
- Safely destroys all created AWS resources
- Cleans up infrastructure to avoid ongoing charges

## �� Customization

### Changing Project Name
Update the `project_name` in the `locals` block in `cognito.tf`:

```hcl
locals {
  project_name = "my-custom-project"
  environment  = "dev"
  aws_region  = "us-east-1"
}
```

### Adding Social Login
Modify the `App.js` file to include social providers:

```javascript
export default withAuthenticator(App, {
  signUpAttributes: ['email'],
  socialProviders: ['google', 'facebook'],
  variation: 'modal'
});
```

### Custom Styling
Modify `src/index.css` to customize the appearance of your application.

## 🧪 Testing

```bash
npm test
```

## 📚 Additional Resources

- [AWS Amplify Documentation](https://docs.amplify.aws/)
- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [React Documentation](https://reactjs.org/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Troubleshooting

### Common Issues

#### OpenTofu State Lock
If you encounter state lock issues:
```bash
tofu force-unlock <lock-id>
```

#### AWS Permissions
Ensure your AWS user has the following permissions:
- Cognito: Full access
- Amplify: Full access
- IAM: Create and manage roles

#### Build Failures
Check the Amplify console for build logs and ensure all environment variables are properly set.

#### Destroy Issues
If the destroy command doesn't work as expected:
```bash
# Check OpenTofu state manually
tofu show
tofu destroy -auto-approve
```

#### Deployment Issues
If the deployment fails:
```bash
# Check OpenTofu state
tofu plan

# Run deployment manually
tofu apply -auto-approve
```

#### Amplify App Shows "Welcome" Message
If your Amplify app shows the default welcome message:
1. **Check if Git repository is connected**:
   - Go to Amplify Console → Your App → Hosting environments
   - Verify main branch shows "Connected" status

2. **Verify build settings**:
   - Check that build spec matches your React app
   - Ensure `baseDirectory: build` is set correctly

3. **Check build logs**:
   - Go to Amplify Console → Your App → Builds
   - Review build logs for any errors

4. **Manual connection**:
   - Follow Git repository connection steps in AWS Console
   - Connect your repository to trigger automatic deployments

#### React App Build Failures
If `npm run build` fails:
1. **Check dependencies**: `npm install`
2. **Verify environment variables**: Check `.env` file exists
3. **Check for syntax errors**: Review console output
4. **Test locally first**: `npm start` to verify app works

#### Cognito Authentication Issues
If authentication doesn't work:
1. **Verify environment variables** in `.env` file
2. **Check Cognito User Pool** is active in AWS Console
3. **Verify callback URLs** include `http://localhost:3000`
4. **Check environment variables** in the deployed application
5. **Ensure Cognito URLs are updated** with actual CloudFront and Amplify URLs (see step 6 in deployment)

### Local Development Issues

#### Port Conflicts
```bash
# Check what's using port 3000
netstat -an | findstr :3000

# Kill Node processes (Windows)
taskkill /f /im node.exe

# Restart development server
npm start
```

#### Environment Variables Not Loading
- Ensure `.env` file is in project root (same level as `package.json`)
- Restart development server after creating `.env`
- Check variable names start with `REACT_APP_`
- Environment variables are automatically configured during deployment

#### Missing Files
If you see errors about missing files:
- `manifest.json`: Created automatically during deployment
- Environment variables: Configured automatically in the deployed app
- Ensure all files are in the correct locations

#### Amplify Configuration Errors
If you see Amplify configuration errors:
1. **Check console logs** for environment variable values
2. **Verify `.env` file** has correct Cognito values
3. **Restart development server** after configuration changes
4. **Use simplified configuration** as shown in the current `App.js`

### Getting Help

- Check the [Issues](../../issues) page
- Review the [Discussions](../../discussions) page
- Contact the maintainers

---

**Happy coding! 🎉**