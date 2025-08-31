# Git Repository Configuration with AWS Amplify

This guide explains how to configure Git repository connections with AWS Amplify, including what can be automated via Terraform/OpenTofu and what requires manual configuration.

## 🔗 **Repository Configuration Overview**

### ✅ **What Terraform/OpenTofu CAN Configure:**
- Amplify app settings and build specifications
- Branch configuration and auto-build settings
- Environment variables and framework settings
- IAM roles and permissions
- Webhook infrastructure (URL generation)

### ❌ **What Terraform/OpenTofu CANNOT Configure:**
- Direct Git repository connections (GitHub, GitLab, Bitbucket)
- OAuth token management and authorization
- Repository access permissions
- Webhook endpoint configuration in Git providers

## 🛠️ **Terraform Configuration**

### **Enhanced Amplify Configuration**

The updated `amplify.tf` includes:

```hcl
# Repository-friendly app configuration
resource "aws_amplify_app" "main" {
  name = "${local.project_name}-${local.environment}"
  
  # Enable repository connection features
  enable_branch_auto_build = true
  enable_branch_auto_deletion = false
  
  # Build specification for React app
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT
}

# Enhanced branch configuration
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = "main"
  
  enable_auto_build = true
  enable_pull_request_preview = true
  framework = "React"
}

# Webhook for repository integration
resource "aws_amplify_webhook" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Webhook for main branch deployments"
}
```

### **Deploy the Enhanced Configuration**

```powershell
# Apply the updated configuration
.\deploy.ps1

# Or manually
tofu plan
tofu apply
```

## 🔧 **Manual Repository Connection Steps**

After deploying the Terraform configuration, follow these steps to connect your Git repository:

### **Step 1: Access Amplify Console**

1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Select your app: `react-auth-demo-dev`
3. Go to "Hosting environments" → "main" branch

### **Step 2: Connect Repository**

1. **Click "Connect branch"** in the main branch section
2. **Choose your Git provider**:
   - GitHub (recommended)
   - GitLab
   - Bitbucket
   - AWS CodeCommit

3. **Authorize access** to your Git provider
4. **Select your repository** and branch
5. **Review build settings** and click "Save and deploy"

### **Step 3: Configure Webhook (Optional)**

The Terraform configuration creates a webhook, but you may need to configure it in your Git provider:

1. **Copy the webhook URL** from the Amplify console
2. **Add webhook in your Git provider**:
   - **GitHub**: Repository → Settings → Webhooks → Add webhook
   - **GitLab**: Repository → Settings → Webhooks → Add webhook
   - **Bitbucket**: Repository → Settings → Webhooks → Add webhook

3. **Configure webhook settings**:
   - **URL**: Paste the Amplify webhook URL
   - **Events**: Select "Push" and "Pull Request" events
   - **Content type**: `application/json`

## 🚀 **Automated Deployment Workflow**

Once configured, your deployment workflow becomes:

### **Development Workflow**

1. **Make changes** to your React app
2. **Commit and push** to your connected branch
3. **Automatic build and deploy** via Amplify
4. **Preview changes** at your Amplify app URL

### **Pull Request Workflow**

1. **Create feature branch** from main
2. **Make changes** and create pull request
3. **Automatic preview deployment** (if enabled)
4. **Merge to main** triggers production deployment

## 📋 **Repository Configuration Checklist**

### **Pre-Deployment (Terraform)**
- [ ] Amplify app with repository-friendly settings
- [ ] Branch configuration with auto-build enabled
- [ ] Webhook resource created
- [ ] IAM roles with proper permissions
- [ ] Environment variables configured

### **Post-Deployment (Manual)**
- [ ] Git repository connected via Amplify console
- [ ] OAuth authorization completed
- [ ] Build settings verified
- [ ] Webhook configured in Git provider
- [ ] Initial deployment successful

## 🔍 **Troubleshooting Repository Connections**

### **Common Issues**

#### **Repository Not Found**
- Verify OAuth authorization
- Check repository visibility (public/private)
- Ensure repository exists and is accessible

#### **Build Failures**
- Check build logs in Amplify console
- Verify build specification in `amplify.tf`
- Ensure all environment variables are set

#### **Webhook Not Working**
- Verify webhook URL is correct
- Check webhook configuration in Git provider
- Review webhook delivery logs

#### **Auto-Deploy Not Triggering**
- Verify branch is connected
- Check webhook events are configured
- Ensure auto-build is enabled

### **Debugging Steps**

1. **Check Amplify Console**:
   - Go to your app → Builds
   - Review build logs for errors
   - Verify branch connection status

2. **Check Git Provider**:
   - Review webhook delivery logs
   - Verify webhook configuration
   - Check repository permissions

3. **Check Terraform State**:
   ```bash
   tofu show
   tofu output
   ```

## 📚 **Best Practices**

### **Repository Structure**
```
your-repo/
├── src/                 # React source code
├── public/              # Static assets
├── amplify.tf           # Infrastructure configuration
├── package.json         # Dependencies
└── README.md            # Documentation
```

### **Branch Strategy**
- **main**: Production branch (auto-deploy)
- **develop**: Development branch (optional)
- **feature/***: Feature branches (preview deployments)

### **Security Considerations**
- Use OAuth tokens instead of personal access tokens
- Limit repository access to necessary permissions
- Regularly rotate OAuth tokens
- Monitor webhook deliveries for security

## 🎯 **Next Steps**

After configuring your repository:

1. **Test the deployment pipeline**:
   - Make a small change to your app
   - Commit and push to main
   - Verify automatic deployment

2. **Set up monitoring**:
   - Configure build notifications
   - Set up deployment alerts
   - Monitor build performance

3. **Optimize the pipeline**:
   - Add build caching
   - Optimize build times
   - Configure preview deployments

## 🔗 **Useful Links**

- [AWS Amplify Documentation](https://docs.amplify.aws/)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [GitLab Webhooks](https://docs.gitlab.com/ee/user/project/integrations/webhooks.html)
- [Bitbucket Webhooks](https://support.atlassian.com/bitbucket-cloud/docs/manage-webhooks/)

---

**Happy deploying! 🚀**
