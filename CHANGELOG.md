# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.5.0 - 2020-08-18

### Breaking Changes

- Greedy cask update feature is now guarded behind the `--all` flag (e.g. `zero
  update --all` or `zero setup --all`).
  
### Fixed

- Addressed issue applying system updates on latest SDK.
- Addressed issue updating casks that require sudo.

## 0.4.1 - 2020-08-08

### Fixed

- Ensure all casks are upgraded, including those with auto-update enabled.

## 0.4.0 - 2020-08-02

### Added

- Added support for `--verbose` flag.

### Fixed

- Addressed issue where certain commands weren't printed when running `zero update`.
- Changed no update found message to match default given by `softwareupdate`.

## 0.3.1 - 2020-06-13

### Fixed

- Added message when no system updates are found.
- Addressed issue where scripts running sudo weren't prompting for credentials.
- Improved error handling when scripts aren't executable.

## 0.3.0 - 2020-02-07

### Added

- Added support for XDG Base Directory Spec.

## 0.2.0 - 2020-01-20

### Added

- Migrated shell script to dedicated Swift CLI.
- Added support for running steps independently.

## 0.1.1 - 2020-01-08

### Added

- Added check to prompt automatic update to latest stable release.

## 0.1.0 - 2020-01-04

- Initial release.
