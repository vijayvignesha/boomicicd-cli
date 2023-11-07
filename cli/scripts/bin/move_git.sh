#!/bin/bash

# Usage:
# ./bin/move_git.sh source_branch="source_branch_name" target_branch="target_branch_name" file="path/to/your/file"
source bin/common.sh 
export authToken="BOOMI_TOKEN.user@email.com:token"
ARGUMENTS=(source_branch target_branch file)
inputs "$@"

if [ "$?" -gt "0" ]
then
   return 255;
fi

export GITHUB_TOKEN=$gitReleaseRepoAPIToken
export GITHUB_API_URL=$gitReleaseRepoAPIURL
# Check if the required parameters are provided
if [ -z "$source_branch" ] || [ -z "$target_branch" ] || [ -z "$file" ]; then
    echo "Usage: ./script.sh source_branch=\"source_branch_name\" target_branch=\"target_branch_name\" file=\"path/to/your/file\""
    exit 1
fi

# Step 1: Get the SHA of the file's blob on the source branch
SHA_BLOB=$(curl -s -v -H "Authorization: Bearer $GITHUB_TOKEN" \
"$GITHUB_API_URL/contents/$file?ref=$source_branch" | jq -r .sha)

if [ "$SHA_BLOB" == "null" ]; then
  echo "Error: File does not exist on the source branch or invalid source branch."
  return 255;
fi

# Step 2: Get the content of the file
FILE_CONTENT=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
"$GITHUB_API_URL/git/blobs/$SHA_BLOB" | jq -r .content | base64 --decode)

# Step 3: Create a new blob in the target branch with the file content
NEW_BLOB_SHA=$(curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"content\": \"$(echo -n "$FILE_CONTENT" | base64)\", \"encoding\": \"base64\"}" \
"$GITHUB_API_URL/git/blobs" | jq -r .sha)

# Step 4: Get the latest commit SHA of the target branch
LATEST_COMMIT_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
"$GITHUB_API_URL/git/refs/heads/$target_branch" | jq -r .object.sha)

# Step 5: Get the tree SHA of the latest commit
TREE_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
"$GITHUB_API_URL/git/commits/$LATEST_COMMIT_SHA" | jq -r .tree.sha)

# Step 6: Create a new tree with the new blob
NEW_TREE_SHA=$(curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"base_tree\": \"$TREE_SHA\", \"tree\": [{\"path\": \"$file\", \"mode\": \"100644\", \"type\": \"blob\", \"sha\": \"$NEW_BLOB_SHA\"}]}" \
"$GITHUB_API_URL/git/trees" | jq -r .sha)

# Step 7: Create a new commit with the new tree object
NEW_COMMIT_SHA=$(curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"parents\": [\"$LATEST_COMMIT_SHA\"], \"tree\": \"$NEW_TREE_SHA\", \"message\": \"Move file $file from $source_branch to $target_branch\"}" \
"$GITHUB_API_URL/git/commits" | jq -r .sha)

# Step 8: Update the target branch to point to the new commit
curl -s -X PATCH -H "Authorization: token $GITHUB_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"sha\": \"$NEW_COMMIT_SHA\"}" \
"$GITHUB_API_URL/git/refs/heads/$target_branch"

echo "File moved successfully from $source_branch to $target_branch."

