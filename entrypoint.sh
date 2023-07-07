#!/bin/sh

set -e

# Set RSA keys
echo "$RSA_PRIVATE_KEY" > ~/.abuild/"$GITHUB_REPOSITORY_OWNER".rsa
echo "$RSA_PUBLIC_KEY" > ~/.abuild/"$GITHUB_REPOSITORY_OWNER".rsa.pub
echo PACKAGER_PRIVKEY=\""$HOME"/.abuild/"$GITHUB_REPOSITORY_OWNER".rsa\" >> ~/.abuild/abuild.conf

# Build any directory that contains an APKBUILD file
cd "$GITHUB_WORKDIR"
# shellcheck disable=SC2016
find . -type f -name APKBUILD -exec /bin/sh -c 'cd $(dirname {}); abuild -r' \;

# Clean the repository and checkout the gh-pages branch
git checkout -- . && git clean -fd
if ! git checkout gh-pages; then
  echo "The branch gh-pages doesn't exist."
  exit 1
fi

# Copy released files
cp ~/.abuild/"$GITHUB_REPOSITORY_OWNER".rsa.pub .
mv -f ~/packages/* .

# Add files and push the branch
git add . && git commit -m "Update packages"
git push https://x-access-token:"$GITHUB_TOKEN"@"$(git remote get-url --push origin | cut -d@ -f 2 | tr : /)" HEAD:refs/heads/gh-pages
