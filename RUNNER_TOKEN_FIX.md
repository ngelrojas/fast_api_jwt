# GitHub Runner Registration Token Fix

## Problem
The GitHub Actions workflow was failing with a 403 error when trying to create a runner registration token:

```
HTTP Status Code: 403
{
  "message": "Resource not accessible by integration",
  "documentation_url": "https://docs.github.com/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository",
  "status": "403"
}
```

## Root Cause
The default `GITHUB_TOKEN` provided by GitHub Actions doesn't have sufficient permissions to create runner registration tokens. This operation requires administrative access to manage self-hosted runners.

## Solution Applied
Changed the authentication from `GITHUB_TOKEN` to `GH_PAT_TOKEN` (Personal Access Token) in the "Create runner registration token" step at line 464 of `.github/workflows/ci-infrastructure.yaml`.

**Changed from:**
```yaml
-H "Authorization: Bearer ${{ secrets.GITHUB_TOKEN }}"
```

**Changed to:**
```yaml
-H "Authorization: token ${{ secrets.GH_PAT_TOKEN }}"
```

## Action Required: Create and Configure Personal Access Token

You need to create a Personal Access Token (PAT) with the appropriate permissions and add it to your repository secrets:

### Step 1: Create a Personal Access Token (PAT)

1. Go to GitHub.com → Settings (your profile settings, not repository)
2. Navigate to **Developer settings** → **Personal access tokens** → **Tokens (classic)**
3. Click **Generate new token** → **Generate new token (classic)**
4. Configure your token:
   - **Note**: `Self-hosted runner management` (or similar descriptive name)
   - **Expiration**: Choose appropriate expiration (90 days, 1 year, or custom)
   - **Select scopes**: Check the following permissions:
     - ✅ **repo** (Full control of private repositories)
       - This includes repo:status, repo_deployment, public_repo, repo:invite, and security_events
     - ✅ **workflow** (Update GitHub Action workflows)
     - ✅ **admin:org** → **manage_runners:org** (if using organization runners)
       - OR for repository-level runners, **repo** scope should be sufficient

5. Click **Generate token**
6. **IMPORTANT**: Copy the token immediately - you won't be able to see it again!

### Step 2: Add Token to Repository Secrets

1. Go to your repository: `https://github.com/ngelrojas/fast_api_jwt`
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Configure the secret:
   - **Name**: `GH_PAT_TOKEN`
   - **Value**: Paste the Personal Access Token you just created
5. Click **Add secret**

### Step 3: Verify Environment Variables
If you're using the `prd` environment, also add the secret to your environment:
1. Go to **Settings** → **Environments** → **prd**
2. Add `GH_PAT_TOKEN` as an environment secret (optional, but recommended for better security)

## Alternative: Use Fine-Grained Personal Access Token (Recommended)

For better security, you can use a Fine-Grained Personal Access Token instead:

1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → **Fine-grained tokens**
2. Click **Generate new token**
3. Configure:
   - **Token name**: `Self-hosted runner management`
   - **Expiration**: Choose appropriate expiration
   - **Resource owner**: Select your account
   - **Repository access**: Select "Only select repositories" → Choose `fast_api_jwt`
   - **Permissions**:
     - Repository permissions:
       - **Administration**: Read and write (required for managing runners)
       - **Actions**: Read and write
4. Generate and copy the token
5. Add it as `GH_PAT_TOKEN` in your repository secrets

## Testing

After adding the token to your repository secrets:

1. Go to **Actions** tab in your repository
2. Select the **"2 - Provisioning Infrastructure"** workflow
3. Click **Run workflow** → **Run workflow**
4. Monitor the execution, particularly the `ec2-self-hosted` job
5. The "Create runner registration token" step should now succeed with HTTP 201 status

## Security Best Practices

1. **Least Privilege**: Use a Fine-Grained PAT with only the required permissions
2. **Token Expiration**: Set an appropriate expiration date (not "no expiration")
3. **Token Rotation**: Rotate tokens periodically
4. **Access Review**: Regularly review and revoke unused tokens
5. **Environment Secrets**: Use environment-specific secrets when possible for additional protection

## Troubleshooting

If you still encounter issues:

1. **Verify token permissions**: Ensure the PAT has `repo` scope or `admin:org` → `manage_runners:org`
2. **Check token format**: The token should start with `ghp_` (classic) or `github_pat_` (fine-grained)
3. **Verify secret name**: Ensure the secret is named exactly `GH_PAT_TOKEN` (case-sensitive)
4. **Check repository access**: If using fine-grained token, verify it has access to the `fast_api_jwt` repository
5. **Token not expired**: Check the token hasn't expired
6. **Re-run workflow**: After adding the secret, re-run the workflow

## Documentation References

- [GitHub REST API - Self-hosted Runners](https://docs.github.com/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository)
- [Creating a Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Using Secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
