<#
.SYNOPSIS
dangitgit source code.
.LINK
https://dangitgit.com/en
#>

# *I did something terribly wrong, please tell me git has a magic time machine!?!
git reflog
# you will see a list of every thing you've
# done in git, across all branches!
# each one has an index HEAD@{index}
# find the one before you broke everything
git reset HEAD@{index}
# magic time machine

# *I committed and immediately realized I need to make one small change!
# make your change
git add . # or add individual files
git commit --amend --no-edit
# now your last commit contains that change!
# WARNING: never amend public commits

# *I need to change the message on my last commit!
git commit --amend
# follow prompts to change the commit message

# *I accidentally committed something to master that should have been on a brand new branch!
# create a new branch from the current state of master
git branch some-new-branch-name
# remove the last commit from the master branch
git reset HEAD~ --hard
git checkout some-new-branch-name
# your commit lives in this branch now :)

# *I accidentally committed to the wrong branch!
# undo the last commit, but leave the changes available
git reset HEAD~ --soft
git stash
# move to the correct branch
git checkout name-of-the-correct-branch
git stash pop
git add . # or add individual files
git commit -m "your message here"
# now your changes are on the correct branch

# or use cherry-pick for this situation too!
git checkout name-of-the-correct-branch
# grab the last commit to master
git cherry-pick master
# delete it from master
git checkout master
git reset HEAD~ --hard

# *I tried to run a diff but nothing happened?!
# you probably add-ed your files to staging and you need to use a special flag.
git diff --staged

# *I need to undo a commit from like 5 commits ago!
# find the commit you need to undo
git log
# use the arrow keys to scroll up and down in history
# once you've found your commit, save the hash
git revert [saved hash]
# git will create a new commit that undoes that commit
# follow prompts to edit the commit message
# or just save and commit

# *I need to undo my changes to a file!
# find a hash for a commit before the file was changed
git log
# use the arrow keys to scroll up and down in history
# once you've found your commit, save the hash
git checkout [saved hash] -- path/to/file
# the old version of the file will be in your index
git commit -m "Wow, you don't have to copy-paste to undo"

# !Forget this noise, I give up.
# get the lastest state of origin
git fetch origin
git checkout master
git reset --hard origin/master
# delete untracked files and directories
git clean -d --force
# repeat checkout/reset/clean for each borked branch
