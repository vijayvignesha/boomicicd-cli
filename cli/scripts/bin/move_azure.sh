#!/bin/bash
source bin/common.sh
export AZURE_DEVOPS_URL="https://dev.azure.com/$ORGANIZATION/$PROJECT/_apis/git"
echo "Starting script..."
ARGUMENTS=(source_branch target_branch file)
inputs "$@"
if [ "$?" -gt "0" ]; then
   echo "Error: Missing required arguments."
   exit 255
fi
# Encode PAT for use in Authorization header
B64_PAT="$AZURE_DEVOPS_PAT"
# Check if the required parameters are provided
if [ -z "$source_branch" ] || [ -z "$target_branch" ] || [ -z "$file" ]; then
    echo "Usage: $0 source_branch=\"source_branch_name\" target_branch=\"target_branch_name\" file=\"path/to/your/file\""
    exit 1
fi

echo "Source branch: $source_branch"
echo "Target branch: $target_branch"
echo "File: $file"

# Retrieve item path for Azure DevOps
FILE_PATH="$file"
ITEM_PATH_URL="$AZURE_DEVOPS_URL/repositories/$REPOSITORY/items?scopePath=$FILE_PATH&versionDescriptor.version=$source_branch&api-version=7.2-preview.1"
echo "Item path URL: $ITEM_PATH_URL"

# Step 1: Get the file content from the source branch
FILE_CONTENT=$(curl -s -H "Authorization: Basic $B64_PAT" "$ITEM_PATH_URL")
if [ -z "$FILE_CONTENT" ]; then
  echo "Error: File does not exist on the source branch or invalid source branch."
  exit 255
fi

# Fetch the latest commit SHA of the target branch
LATEST_COMMIT_SHA=$(curl -s -H "Authorization: Basic $B64_PAT" \
  "$AZURE_DEVOPS_URL/repositories/$REPOSITORY/commits?searchCriteria.itemVersion.version=$target_branch&api-version=7.2-preview.1" | \
  jq -r '.value[0].commitId')

echo "Latest commit SHA of target branch: $LATEST_COMMIT_SHA"

if [ -z "$LATEST_COMMIT_SHA" ] || [ "$LATEST_COMMIT_SHA" == "null" ]; then
  echo "Error: Failed to fetch the latest commit SHA of the target branch."
  exit 255
fi

# Step 2: Update or create the file in the target branch
UPDATE_FILE_URL="$AZURE_DEVOPS_URL/repositories/$REPOSITORY/pushes?api-version=7.2-preview.3"
echo "Update file URL: $UPDATE_FILE_URL"

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

echo "JSON payload for update: $JSON_PAYLOAD"

# Perform the update/create operation
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Basic $B64_PAT" -d "$JSON_PAYLOAD" "$UPDATE_FILE_URL")
echo "Response from update operation: $RESPONSE"

# Check response for errors
COMMIT_ID=$(echo $RESPONSE | jq -r '.refUpdates[0].newObjectId')

if [ "$COMMIT_ID" == "null" ] || [ -z "$COMMIT_ID" ]; then
  echo "Error: Failed to move the file. Please check the provided details and permissions."
  exit 255
fi

echo "File $file moved successfully from $source_branch to $target_branch commit id $COMMIT_ID."
