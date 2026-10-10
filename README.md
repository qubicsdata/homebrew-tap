# QubicsData Homebrew tap

Install Folio and Switchboard with their bundled runtimes. The verified bottles target macOS 27 (ARM64 and x64) and glibc Linux (ARM64 and x64). macOS ARM64 and Linux ARM64 were tested natively; macOS x64 uses Rosetta and Linux x64 uses full-system QEMU TCG. Other macOS versions can use the matching standalone release archives, subject to their runtime requirements. This tap and the release repositories are private; your GitHub account needs read access to all three repositories.

## Authentication

Sign in with GitHub CLI and enable its Git credential helper for cloning the private tap:

```sh
gh auth login
gh auth setup-git
brew tap qubicsdata/tap https://github.com/qubicsdata/homebrew-tap.git
```

Homebrew 7 may request `brew trust qubicsdata/tap` before installing.

Release asset downloads use your GitHub CLI credential or `HOMEBREW_GITHUB_API_TOKEN`. A fine-grained token needs read access to repository contents in `qubicsdata/switchboard-distribution` and `qubicsdata/folio-distribution`. Authenticate locally; do not put tokens into repository URLs or configuration files committed to Git.

## Install and open

```sh
brew install qubicsdata/tap/switchboard qubicsdata/tap/folio-workspace
switchboard ui
folio-server
```

Folio serves its local workspace at the address printed by `folio-server`. Switchboard opens its dashboard. Agent CLIs and their vendor sign-ins remain separate; `switchboard doctor` reports what is available. Installation does not start background work or migrate an existing workspace.

## Update and remove

Finish active work and stop the app before upgrading its Homebrew installation:

```sh
brew update
brew upgrade qubicsdata/tap/switchboard qubicsdata/tap/folio-workspace
```

Use `brew uninstall switchboard folio-workspace` to remove the software. User workspaces and project data remain in their existing locations. Use each app’s explicit backup and migration commands when moving existing data. Homebrew owns the installed application; Switchboard’s transactional self-updater is for standalone installations.

## Releases and source

- [Switchboard 2.0.0](https://github.com/qubicsdata/switchboard-distribution/releases/tag/v2.0.0)
- [Folio 1.1.0](https://github.com/qubicsdata/folio-distribution/releases/tag/v1.1.0)

All release packages are built locally. GitHub Actions is disabled. Formulas pin each platform bottle and archive by SHA-256. Bottles preserve the verified runtime files and refuse source fallback that could alter them. The two products can coexist in one Homebrew prefix; embedded formula helpers stay in private metadata directories. Native Apple installers and notarization are outside this Homebrew distribution. First-party source and binaries use Apache-2.0; bundled dependencies retain their own licenses and notices.
