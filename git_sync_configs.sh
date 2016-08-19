#! /bin/bash

# This script automates committing and pushing
# updates of the centrally maintained
# Continuous Integration config files to the respective
# repos where they are used.

# Verify that the script was called with a
# GitHub username that is not "SeattleTestbed"
# We want contributors to push to their own fork
if [ $# -ne 1 ]
then
  echo "$0 <fork name>"
  exit 1
fi

if [ "$1" == "SeattleTestbed" ]
then
  echo "Don't clone from 'SeattleTestbed', use your fork!"
  exit 2
fi
fork_name="$1"

# List of repos where we want to use continuous integration
# This list can and should change over time, when other Seattle 
# components get unit tests
declare -a repos=("git@github.com:$fork_name/seattlelib_v2.git"
"git@github.com:$fork_name/repy_v2.git"
"git@github.com:$fork_name/utf.git"
"git@github.com:$fork_name/nodemanager.git"
"git@github.com:$fork_name/affix.git"
"git@github.com:$fork_name/seash.git"
"git@github.com:$fork_name/softwareupdater.git"
"git@github.com:$fork_name/experimentmanager.git"
"git@github.com:$fork_name/portability.git")

# I only want to copy the config files (not e.g. README.md)
# Alternativley, we could declare files that we don't want to copy
declare -a files=("appveyor.yml" ".travis.yml")

# The branch name the changes are pushed to
branch_name="sync-ci-configs"

for repo_url in "${repos[@]}"
do
  # Extract repo basename from url
  repo_basename="$(basename -s .git $repo_url)"
  echo "---------------------------------------------------------"
  echo "Cloning '$repo_url' into '$repo_basename' ..."
  git clone -q $repo_url $repo_basename
  if [ $? -ne 0 ]
  then
      echo "Could not clone '$repo_url'. Skipping this repo..."
      continue
  fi

  pushd $repo_basename

  # If branch does not exist (which it should when you regularily sync your forks)
  # create it and check it out.
  echo "Checking out branch '$branch_name' ..."
  git checkout -q -B $branch_name
  if [ $? -ne 0 ]
  then
      echo "Could not checkout '$branch_name'. Skipping this repo..."
      popd
      continue
  fi

  echo "Git pulling updates for '$branch_name'..."
  git pull -q origin $branch_name

  for file in "${files[@]}"
  do
    echo "Copying '$file' ..."
    cp ../$file .
  done

  echo "Git adding the files..."
  git add "${files[@]}"

  echo "Committing ..."
  git commit -q -am "Syncs ci config files"
  if [ $? -ne 0 ]
  then
      echo "Could not commit. Skipping this repo..."
      popd
      continue
  fi

  echo "Pushing '$branch_name' to origin..."
  git push -q origin $branch_name
  if [ $? -ne 0 ]
  then
      echo "Could not push. Skipping this repo..."
      popd
      continue
  fi
  popd
  # XXX Remove the repo here?
  # rm $repo_basename
done
echo "---------------------------------------------------------"
echo "---------------------------------------------------------"
echo "Please go to GitHub and submit Pull Requests for your pushes!!"