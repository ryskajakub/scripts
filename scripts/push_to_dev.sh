BRANCH=`git branch --show-current`
git push origin HEAD
PULL_REQUEST_ID=`az repos pr create --source-branch $BRANCH --target-branch dev --delete-source-branch true --auto-complete | jq ".pullRequestId"`
az repos pr set-vote --id $PULL_REQUEST_ID --vote approve
