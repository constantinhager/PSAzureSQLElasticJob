# Changelog for PSAzureSQLElasticJob

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Sampler-based project scaffold with GitVersion, Pester 5 and GitHub Actions.
- `New-SqlElasticJobEnvironment` to provision the logical SQL server, job
  database and Elastic Job agent, creating only the parts that are missing.
- `Test-SqlElasticJobEnvironment` to report which parts of an environment exist
  without changing anything.
- `Get-SqlElasticJobAgent`, `New-SqlElasticJobAgent`, `Set-SqlElasticJobAgent`
  and `Remove-SqlElasticJobAgent` for Elastic Job agent CRUD.
- MIT license file.

### Changed

- For changes in existing functionality.

### Deprecated

- For soon-to-be removed features.

### Removed

- For now removed features.

### Fixed

- For any bug fix.

### Security

- In case of vulnerabilities.

