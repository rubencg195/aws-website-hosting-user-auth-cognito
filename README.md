# React Authentication Demo with AWS Cognito and Amplify

This project demonstrates a complete React.js application with authentication handled by AWS Cognito, hosted on AWS Amplify, and deployed using OpenTofu (formerly Terraform).

## 🏗️ Architecture

- **Frontend**: React.js with AWS Amplify UI components
- **Authentication**: AWS Cognito User Pool
- **Hosting**: AWS Amplify
- **Infrastructure as Code**: OpenTofu
- **Cloud Provider**: AWS

## 🚀 Features

- User registration and authentication
- Protected routes and components
- Responsive UI with Amplify UI components
- Automatic deployment pipeline
- Infrastructure as Code with OpenTofu
- **Automated deployment script** (`deploy.ps1`) for Windows users

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Node.js](https://nodejs.org/) (v16 or higher)
- [OpenTofu](https://opentofu.org/docs/intro/install/) (v1.0 or higher)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with permissions for Cognito, Amplify, and IAM

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

### 4. Deploy Infrastructure

#### On Windows (Recommended):
```powershell
# Run PowerShell with execution policy bypass
powershell -ExecutionPolicy Bypass -File deploy.ps1

# Or run directly if execution policy allows
.\deploy.ps1
```

**Note**: The `deploy.ps1` script will:
- Check if OpenTofu and AWS CLI are installed and configured
- Initialize OpenTofu automatically
- Plan and apply the infrastructure changes
- Provide a summary of created resources
- Show next steps for your application

**Execution Policy**: If you encounter execution policy issues, the script will guide you to run it with `-ExecutionPolicy Bypass`.

#### On Linux/macOS:
```bash
chmod +x deploy.sh
./deploy.sh
```

#### Manual Deployment:
```bash
# Initialize OpenTofu
tofu init

# Plan the deployment
tofu plan

# Apply the configuration
tofu apply
```

### 5. Destroy Infrastructure (Optional)

When you're done with the demo, you can destroy the infrastructure to avoid ongoing AWS charges:

#### On Windows:
```powershell
# Run PowerShell with execution policy bypass
powershell -ExecutionPolicy Bypass -File destroy.ps1

# Or run directly if execution policy allows
.\destroy.ps1
```

#### On Linux/macOS:
```bash
# Manual destruction
tofu destroy -auto-approve
```

**Warning**: This will permanently delete all AWS resources created by this project.

### 6. Local Development

```bash
npm start
```

The application will open at `http://localhost:3000`

## 🏗️ Infrastructure Components

### AWS Cognito
- **User Pool**: Manages user accounts and authentication
- **User Pool Client**: Web application client for authentication
- **User Pool Domain**: Custom domain for the hosted UI

### AWS Amplify
- **App**: Main application configuration
- **Branch**: Main branch with auto-build enabled
- **IAM Role**: Permissions for Amplify operations

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
├── cognito.tf          # Cognito User Pool and Client (with locals)
├── amplify.tf          # Amplify app and branch (with locals)
├── package.json        # Node.js dependencies
├── public/             # Static assets
├── src/                # React source code
│   ├── App.js         # Main application component
│   ├── index.js       # Application entry point
│   └── index.css      # Global styles
├── deploy.ps1          # Windows PowerShell deployment script (recommended)
├── deploy.sh           # Linux/macOS deployment script
├── destroy.ps1         # Windows PowerShell destruction script
└── README.md           # This file
```

## 🚀 Deployment

### Automatic Deployment
1. Connect your Git repository to AWS Amplify
2. Push code to the main branch
3. Amplify automatically builds and deploys

### Manual Deployment
1. Build the application: `npm run build`
2. Deploy the build folder to your hosting service

## 🔧 Customization

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

#### Destroy Script Issues
If the destroy script doesn't show output or fails silently:
```powershell
# Use execution policy bypass
powershell -ExecutionPolicy Bypass -File destroy.ps1

# Or check OpenTofu state manually
tofu show
tofu destroy -auto-approve
```

#### Deployment Script Issues
If the deployment script fails:
```powershell
# Check execution policy
Get-ExecutionPolicy

# Run with execution policy bypass
powershell -ExecutionPolicy Bypass -File deploy.ps1

# Or run manually following the manual deployment steps above
```

### Getting Help

- Check the [Issues](../../issues) page
- Review the [Discussions](../../discussions) page
- Contact the maintainers

---

**Happy coding! 🎉**