# Security policy

Report formula, packaging, or download-integrity vulnerabilities with [private vulnerability reporting](https://github.com/qubicsdata/homebrew-tap/security/advisories/new). Include the formula version, operating system, architecture, and a minimal example with synthetic data. Do not post credentials or private project data in public issues.

For product issues, use the [Folio](https://github.com/qubicsdata/folio-releases/security/advisories/new) or [Switchboard](https://github.com/qubicsdata/switchboard-releases/security/advisories/new) private channel. Security fixes are delivered through new product versions and updated pinned hashes. Source repositories remain private. GitHub Actions is disabled; builds and tests run locally.

Current formulas use public HTTPS downloads and Homebrew SHA-256 verification. Verify the tap origin before trusting it. Checksums establish correspondence to the pinned manifest; they are not independent publisher signatures. Protect your GitHub and local administrator credentials. Historical private-download recipes are retained as records and are not required by current formulas.
