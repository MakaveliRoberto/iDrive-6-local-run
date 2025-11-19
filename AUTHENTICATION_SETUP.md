# GitHub Authentication Setup

## Current Issue
Git push is failing because authentication is not set up.

## Solutions

### Option 1: Set Up SSH Key (Recommended)

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   # Press Enter to accept default location
   # Optionally set a passphrase
   ```

2. **Add SSH key to ssh-agent**:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. **Copy public key**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Copy the output
   ```

4. **Add to GitHub**:
   - Go to: https://github.com/settings/keys
   - Click "New SSH key"
   - Paste your public key
   - Save

5. **Test connection**:
   ```bash
   ssh -T git@github.com
   # Should say: "Hi MakaveliRoberto! You've successfully authenticated..."
   ```

6. **Push**:
   ```bash
   git push -u origin main
   ```

### Option 2: Use Personal Access Token (PAT)

1. **Create PAT**:
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scopes: `repo` (full control)
   - Generate and copy the token

2. **Switch to HTTPS**:
   ```bash
   git remote set-url origin https://github.com/MakaveliRoberto/iDrive-6-local-run.git
   ```

3. **Push** (use token as password):
   ```bash
   git push -u origin main
   # Username: MakaveliRoberto
   # Password: [paste your PAT token]
   ```

### Option 3: Use GitHub CLI

1. **Install GitHub CLI**:
   ```bash
   brew install gh
   ```

2. **Authenticate**:
   ```bash
   gh auth login
   # Follow prompts
   ```

3. **Push**:
   ```bash
   git push -u origin main
   ```

## Verify Repository Exists

Make sure the repository exists on GitHub:
- Visit: https://github.com/MakaveliRoberto/iDrive-6-local-run
- If it doesn't exist, create it on GitHub first

## Quick Setup Script

Run this to set up SSH quickly:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519 -N ""

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Display public key (add this to GitHub)
cat ~/.ssh/id_ed25519.pub

# Test connection
ssh -T git@github.com
```

