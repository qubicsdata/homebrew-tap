# QubicsData Homebrew tap

Install Folio and Switchboard with their bundled runtimes. The verified bottles target macOS 27 (ARM64 and x64) and glibc Linux (ARM64 and x64). macOS ARM64 and Linux ARM64 were tested natively; macOS x64 uses Rosetta and Linux x64 uses full-system QEMU TCG. Other macOS versions can use the matching standalone release archives, subject to their runtime requirements. This tap and both release repositories are public. Installation does not require GitHub credentials. Application development repositories remain private.

## Add the tap

Add the public tap:

```sh
brew tap qubicsdata/tap https://github.com/qubicsdata/homebrew-tap.git
```

Homebrew 7 may request `brew trust qubicsdata/tap` before installing.

Current formulas download public assets over HTTPS using Homebrew’s standard downloader and verify pinned SHA-256 hashes. No private download strategy or GitHub token is required. Historical recipes retain their original private-distribution strategy for provenance.

## Install and open

```sh
brew install qubicsdata/tap/switchboard qubicsdata/tap/folio-workspace
switchboard ui
folio ui
```

Both commands open their local dashboards. Agent CLIs and their vendor sign-ins remain separate; `switchboard doctor` reports what is available. Installation does not start background work or migrate an existing workspace.

## Update and remove

Finish active work and stop the app before upgrading its Homebrew installation:

```sh
brew update
brew upgrade qubicsdata/tap/switchboard qubicsdata/tap/folio-workspace
```

Use `brew uninstall switchboard folio-workspace` to remove the software. User workspaces and project data remain in their existing locations. Use each app’s explicit backup and migration commands when moving existing data. Homebrew owns the installed application; Switchboard’s transactional self-updater is for standalone installations.

## Installation releases

- [Switchboard 2.0.2](https://github.com/qubicsdata/switchboard-releases/releases/tag/v2.0.2)
- [Folio 1.1.2](https://github.com/qubicsdata/folio-releases/releases/tag/v1.1.2)

All release packages are built locally. GitHub Actions is disabled. Formulas pin each platform bottle and archive by SHA-256. Bottles preserve the verified runtime files and refuse source fallback that could alter them. The two products can coexist in one Homebrew prefix; embedded formula helpers stay in private metadata directories. Native Apple installers and notarization are outside this Homebrew distribution. Both products are originally developed by QubicsData. First-party code uses Apache-2.0 with applicable attribution preserved in NOTICE. Switchboard documentation retains CC-BY-4.0; bundled dependencies retain their own licenses and notices. The release repositories contain installation packages and documentation; development source repositories remain separately private and are not needed to install. Packaged Python and JavaScript can remain readable.

## Security

Report installer or formula vulnerabilities through [private vulnerability reporting](https://github.com/qubicsdata/homebrew-tap/security/advisories/new). For application vulnerabilities, use the corresponding [Folio](https://github.com/qubicsdata/folio-releases/security/advisories/new) or [Switchboard](https://github.com/qubicsdata/switchboard-releases/security/advisories/new) private reporting channel. Never put credentials or private project data in public issues.
