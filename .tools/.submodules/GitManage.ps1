# history of commits
git reflog
git lga
git lol
git lola

# number of commits made by each person
git shortlog -s -n

# undo all commits but keeps file changes
git reset --soft origin/dev
git reset --soft origin/master
# revert to the commit: put hash of the commit before commit you want to revert
git reset --hard origin/dev
git reset --hard 66b6486

# prune obsolete remote branches
git remote update origin --prune

# Clean all untracked files
git checkout -- .

#remove file from branch
git rm --cached RedGateDatabaseInfo.xml
# remove recursively folder from branch
git rm --cached .vs -r

# Refresh git repository
git rm -r --cached .
git add .
git commit -m "fixed untracked files"

#create new branch and switch to it
git branch featureA; git checkout featureA
#shortcut for above command
git checkout -b featureA

# merge master into feauterA branch
git checkout featureA
git rebase master
git merge master

# merge into master branch
git checkout master
git merge featureA

# show remote
git remote -v
# list branches
git branch
# list branches with commit comments
git branch -vv
# list all branches
git branch -a
# list non merged branches
git branch --no-merged
# list merged branch and delete it
git branch --merged
git branch -d featureA
# force deletion of unmerged branch
git branch -D featureB

# rebase branch into master
# copy history of the branch into master branch
git rebase master

# show branch
git show master
git show featureB

# Push local branch to remote (eg. in case origin brach has been deleted)
git push --force --set-upstream origin test

# stash all uncommitted changes
git stash mystash       # stash all changes in branch
git stash push --patch  # confirm adding every changed file to stash
git stash pop           # reapply previously stashed changes
git shash apply         # apply changes from stash and keep stash

# Create branch commit changes and push to origin
$rev=2; $date = (Get-Date).ToString('yyMMdd'); git checkout -b "mybranch_$date-$rev"
git status -sb
git add .
git commit -m "update $date-1"
git push -u origin head
git checkout master
git pull
