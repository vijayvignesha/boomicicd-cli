#!/bin/bash
source bin/common.sh

ARGUMENTS=(source_branch target_branch file)
inputs "$@"
if [ "$?" -gt "0" ]; then
   exit 255
fi
# Encode PAT for use in Authorization header
B64_PAT=$AZURE_DEVOPS_PAT
# Check if the required parameters are provided
if [ -z "$source_branch" ] || [ -z "$target_branch" ] || [ -z "$file" ]; then
    echo "Usage: $0 source_branch=\"source_branch_name\" target_branch=\"target_branch_name\" file=\"path/to/your/file\""
    exit 1
fi

# Retrieve item path for Azure DevOps differs, as it requires repositoryId, project, and scopePath.
FILE_PATH="$file"
ITEM_PATH_URL="$AZURE_DEVOPS_URL/repositories/$REPOSITORY/items?scopePath=$FILE_PATH&versionDescriptor.version=$source_branch&api-version=7.2-preview.1"

# Step 1: Get the file content from the source branch
#echo "B64_PAT $B64_PAT"
#echo "ITEM_PATH_URL: $ITEM_PATH_URL"


FILE_CONTENT=$(curl -s -H "Authorization: Basic $B64_PAT" "$ITEM_PATH_URL")

#echo "FILE_CONTENT: $FILE_CONTENT"
if [ -z "$FILE_CONTENT" ]; then
  echo "Error: File does not exist on the source branch or invalid source branch."
  exit 255
fi
# # Fetch the latest commit SHA of the target branch
# LATEST_COMMIT_SHA=$(curl -s -H "Authorization: Basic $B64_PAT" \
#   "$AZURE_DEVOPS_URL/repositories/$REPOSITORY/refs?filter=refs/heads/$target_branch&api-version=7.2-preview.1" | \
#   jq -r '.value[0].objectId')


# Fetch the latest commit SHA of the target branch
LATEST_COMMIT_SHA=$(curl -s -H "Authorization: Basic $B64_PAT" \
  "$AZURE_DEVOPS_URL/repositories/$REPOSITORY/commits?searchCriteria.itemVersion.version=$target_branch&api-version=7.2-preview.1" | \
  jq -r '.value[0].commitId')

echo "LATEST_COMMIT_SHA: $LATEST_COMMIT_SHA"
if [ -z "$LATEST_COMMIT_SHA" ] || [ "$LATEST_COMMIT_SHA" == "null" ]; then
  echo "Error: Failed to fetch the latest commit SHA of the target branch."
  exit 255
fi
# Azure DevOps API for creating or updating files directly commits to the repository, so steps to create blobs, trees, and commits are not required as in GitHub.

# Step 2: Update or create the file in the target branch
UPDATE_FILE_URL="$AZURE_DEVOPS_URL/repositories/$REPOSITORY/pushes?api-version=7.2-preview.3"
echo "UPDATE_FILE_URL: $UPDATE_FILE_URL"
# Construct JSON payload for updating the file
JSON_PAYLOAD=$(jq -n \
    --arg content "$FILE_CONTENT" \
    --arg path "$file" \
    --arg sourceBranch "$source_branch" \
    --arg targetBranch "$target_branch" \
    --arg latestCommitSHA "$LATEST_COMMIT_SHA" \
    '{
      "refUpdates": [{
        "name": "refs/heads/\($targetBranch)",
      "oldObjectId": $latestCommitSHA
      }],
      "commits": [{
        "comment": "Move file from \($sourceBranch) to \($targetBranch)",
        "changes": [{
          "changeType": "edit",
          "item": {
            "path": "\($path)"
          },
          "newContent": {
            "content": "\($content)",
            "contentType": "rawtext"
          }
        }]
      }]
    }')

# echo "JSON $JSON_PAYLOAD"
# Perform the update/create operation
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Basic $B64_PAT" -d "$JSON_PAYLOAD" "$UPDATE_FILE_URL")
echo "RESPONSE: $RESPONSE"
# Check response for errors
COMMIT_ID=$(echo $RESPONSE | jq -r '.refUpdates[0].newObjectId')

if [ "$COMMIT_ID" == "null" ] || [ -z "$COMMIT_ID" ]; then
  echo "Error: Failed to move the file. Please check the provided details and permissions."
  exit 255
fi
echo "File $file moved successfully from $source_branch to $target_branch commit id $COMMIT_ID."