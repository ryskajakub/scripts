BRANCH=`git branch --show-current`
TARGET_BRANCH=$1
git push origin HEAD
PULL_REQUEST_ID=`az repos pr create --source-branch $BRANCH --target-branch $TARGET_BRANCH --squash --delete-source-branch true --auto-complete | jq ".pullRequestId"`
az repos pr set-vote --id $PULL_REQUEST_ID --vote approve
git checkout $TARGET_BRANCH
until git log -1 --oneline | grep $BRANCH | wc -l; do
	git pull
done
