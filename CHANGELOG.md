# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-02-21

### Added

- Multi AWS provider example for tagging resources across multiple regions in a single configuration

## [0.1.0] - 2026-02-11

### Added

- Initial release of the TagOps Terraform module
- `api_token` variable for secure API authentication (marked as sensitive)
- `default_tags` variable for passing default tags to TagOps tag calculation
- `default_resources` variable for specifying Terraform resource types by name
- `custom_resources` variable for passing resources with explicit name, type, and existing tags
- Automatic AWS account ID and region detection from the AWS provider
- HTTP postcondition validation for API error handling
- `tags` output returning computed tags map from the TagOps API
- Fresh API request on every plan/apply via `plantimestamp()` cache busting (for case then TagOps rules was changed)
