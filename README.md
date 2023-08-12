# abuild releaser action

GitHub action to build and release to GitHub pages Alpine Linux aport packages
contained in a repository.

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
```

### Example usage

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

## License

See [LICENSE](LICENSE) © [Ivan Valdes](https://github.com/ivanvc/)
