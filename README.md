# rocale-cli

A command-line tool for building, uploading, and running Roblox projects in OCALE.

## Usage

The tool can be installed as a dependency to your project using foreman. Simply add this line to your `foreman.toml`.
```
rocale-cli = { source = "Roblox/rocale-cli", version = "0.1.0" }
```

You can also manually grab a release from the [releases](https://github.com/Roblox/rocale-cli/releases) page.

Run `rocale-cli help` to see available commands and run `rocale-cli <command> --help` for more information on how to use each command.

## Building

First, run `foreman install` to install dependencies.

To build, run `lute scripts/build`. The build artifacts will be created in the `build` directory.

To build for release, run `lute scripts/build <version> $(git rev-parse HEAD)` to bake the version and commit hash of the build into the binary.

To test, [create a new place](https://create.roblox.com/dashboard/creations) and generate an [Open Cloud API Key](https://create.roblox.com/docs/cloud). Set the `TEST_UNIVERSE_ID`, `TEST_PLACE_ID` and `ROBLOX_API_KEY` environment variables. Then, run `lute scripts/test`.

## Publishing

To publish a new version, [draft a new release](https://github.com/Roblox/rocale-cli/releases/new) and create a new tag with a version string format `vx.x.x`.
