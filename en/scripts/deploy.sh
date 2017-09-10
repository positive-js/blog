#!/bin/sh

set -ev

git clone https://$GITHUB_REPO
cd $(basename ${GITHUB_REPO%.git})
git config user.name "Travis CI"
git config user.email ${GH_EMAIL}

rsync -az --delete --exclude '.git*' ../_site/ .
touch .nojekyll

git add --all .
git commit -m "Generated Jekyll site by Travis CI - ${TRAVIS_BUILD_NUMBER}"
git push -f "https://${GH_TOKEN}@${GITHUB_REPO}" HEAD:${REPO_TARGET_BRANCH}