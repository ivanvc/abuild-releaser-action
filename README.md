# abuild releaser action

GitHub action to build and release to GitHub pages Alpine Linux aport packages
contained in a repository.

## Pre-requisites

First, follow the [Alpine Linux guide on Creating an Alpine
Package][alpine-guide]. Make sure to generate a RSA key by using `abuild-keygen
-a -i`. Save the public and private keys, and set them as the repository
secrets: `RSA_PUBLIC_KEY` and `RSA_PRIVATE_KEY`. This key will be used to sign
the packages, and the build process will place the public key in the `gh-pages`
branch.

**NOTE:** This action will find all of the `APKBUILD` files in the repository
if `packages_dir` is not specified, and will build **all of these packages**.
Therefore, you **should only have APKBUILD files from the packages you want to
publish**, or provide the `packages_dir` option.

## Usage

```yaml
- uses: ivanvc/abuild-releaser-action@main
with:
  # The following fields are required.
  # The author to use for the released apk packages.
  author: ''

  # The RSA public key used to sign the packages, set it as a secret.
  rsa_public_key: ''

  # The RSA private key used to sign the packages, set it as a secret.
  rsa_private_key: ''

  # The rest of the fields are optional.
  # The commit message when updating the gh-pages branch.
  commit_message: ''

  # Generate multiple index pages, one per directory.
  # Default: false
  generate_index_pages: ''

  # Generate a single index page.
  # Default: true
  generate_single_index_page: ''

  # Override the index page template with a file that exists in the gh-pages
  # branch. If the file doesn't exist, or it's not provided, it will use the
  # default index.html.tpl.
  index_page_template: ''

  # Release only the packages from the provided directories, release all of them
  # if this is not provided.
  packages_dir: ''
```

Refer to [`action.yml`](action.yml) for the complete documentation.

### Example usage

Release all packages in the repository:

```yaml
name: Release

on:
  push:
    branches:
      - main

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ivanvc/abuild-releaser-action@v1.0.0
        with:
          author: John Doe <john@example.com>
          rsa_public_key: ${{ secrets.RSA_PUBLIC_KEY }}
          rsa_private_key: ${{ secrets.RSA_PRIVATE_KEY }}
```

Release only the packages inside the `testing` directory, and
`community/docker`:

```yaml
...

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ivanvc/abuild-releaser-action@v1.0.0
        with:
          author: John Doe <john@example.com>
          rsa_public_key: ${{ secrets.RSA_PUBLIC_KEY }}
          rsa_private_key: ${{ secrets.RSA_PRIVATE_KEY }}
          package_dirs: "testing/*,community/docker"
```

## License

See [LICENSE](LICENSE) © [Ivan Valdes](https://github.com/ivanvc/)

[alpine-guide]: https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package
