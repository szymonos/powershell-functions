# Configure user name and email to start using git
git config --global user.name 'Szymon Osiecki'
git config --global user.email 'szymonos@outlook.com'
# Check configuration and version
git config -l
git --version

# Initialize repository in current directory
git init .

# Refresh git repository
git rm -r --cached .
git add .
git commit -m "fixed untracked files"

# Reinitialize local and remote repository
Set-Location 'C:\Source\Git\SQLAdmin'
Remove-Item .\.git -Recurse -Force
git init
git add .
git commit -m 'Initial commit'

# Add repository to remote
git remote add origin 'https://szymonos@dev.azure.com/szymonos/DevOps/_git/devops-scripts'
git push --force --set-upstream origin master
