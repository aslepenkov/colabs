#!/bin/bash

# run eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519 if needed
# Set the remote repository URL
REMOTE_REPO_URL="git@github.com:aslepenkov/somerepo.git"

# Define the parent directory for branches
BRANCHES_DIR="../branches"

# Check if the repository URL is valid
if [ -z "$REMOTE_REPO_URL" ]; then
  echo "Error: Remote repository URL is not set. Exiting."
  exit 1
fi

# Create the branches directory if it doesn't exist
mkdir -p "$BRANCHES_DIR"

# Perform a temporary bare clone to fetch branch information
echo "Cloning the repository in bare mode to retrieve all branches..."
TEMP_CLONE=$(mktemp -d)
git clone --bare "$REMOTE_REPO_URL" "$TEMP_CLONE" || { echo "Error: Failed to execute bare clone. Verify repository URL and access rights."; exit 1; }

cd "$TEMP_CLONE" || { echo "Error: Failed to access temporary bare clone directory."; exit 1; }

# Get a list of all branches (in a bare repository, we use git branch -a)
BRANCHES=$(git branch -a | sed 's/^[* ] //' | grep -v '^HEAD')

# Check if there are branches available
if [ -z "$BRANCHES" ]; then
  echo "Error: No branches found in the repository. Exiting."
  rm -rf "$TEMP_CLONE"
  exit 1
fi

echo "Found the following branches:"
echo "$BRANCHES"

# Loop through each branch
for branch in $BRANCHES; do
  echo "Processing branch: $branch"

  # Create a directory for the branch under ../branches
  BRANCH_DIR="${BRANCHES_DIR}/${branch}"
  mkdir -p "$BRANCH_DIR"

  echo "Cloning branch '$branch' into directory: $BRANCH_DIR"

  # Clone the repository into the branch directory
  git clone "$REMOTE_REPO_URL" "$BRANCH_DIR" || { echo "Error: Failed to clone branch: $branch. Skipping."; continue; }

  cd "$BRANCH_DIR" || continue

  # Check out the specific branch
  git checkout "$branch" || { echo "Error: Failed to checkout branch: $branch."; cd "$TEMP_CLONE"; continue; }

  echo "Branch '$branch' has been cloned to: $BRANCH_DIR"

  # Return to the temp clone directory
  cd "$TEMP_CLONE" || exit 1
done

# Clean up the temporary bare clone
rm -rf "$TEMP_CLONE"

echo "All branches have been cloned into separate directories under: $BRANCHES_DIR"
