#!/bin/sh

set -e

# Set abuild configuration
mkdir -p "$GITHUB_WORKDIR"/.abuild
cat <<EOF > "$GITHUB_WORKDIR"/.abuild/abuild.conf
PACKAGER="$INPUT_AUTHOR"
REPODEST="$HOME/packages"
PACKAGER_PRIVKEY="$GITHUB_WORKDIR/.abuild/$GITHUB_REPOSITORY_OWNER.rsa"
EOF

# Load RSA keys
echo "$RSA_PRIVATE_KEY" > "$GITHUB_WORKDIR/.abuild/$GITHUB_REPOSITORY_OWNER.rsa"
echo "$RSA_PUBLIC_KEY" > "$GITHUB_WORKDIR/.abuild/"$GITHUB_REPOSITORY_OWNER".rsa.pub"

# Build any directory that contains an APKBUILD file
# shellcheck disable=SC2016
find . -type f -name APKBUILD -exec /bin/sh -c 'cd $(dirname {}); abuild -r' \;

# Clean the repository and checkout the gh-pages branch
git checkout -- . && git clean -fd -e packages
if ! git checkout gh-pages; then
  echo "The branch gh-pages doesn't exist."
  exit 1
fi

# Copy released files
cp "$GITHUB_WORKDIR/.abuild/$GITHUB_REPOSITORY_OWNER.rsa.pub" .
mv -f packages/* .

# Add files and push the branch
git add . && git commit -m "Update packages"
git push https://x-access-token:"$GITHUB_TOKEN"@"$(git remote get-url --push origin | cut -d@ -f 2 | tr : /)" HEAD:refs/heads/gh-pages
