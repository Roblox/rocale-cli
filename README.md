# rocale-cli

A command-line tool for building, uploading, and running Roblox projects in OCALE.

## Building

First, run `foreman install` to install dependencies.

To build, run `lute scripts/build`. The build artifacts will be created in the `build` directory.

To test, [create a new place](https://create.roblox.com/dashboard/creations) and generate an [Open Cloud API Key](https://create.roblox.com/docs/cloud). Set the `TEST_UNIVERSE_ID`, `TEST_PLACE_ID` and `ROBLOX_API_KEY` environment variables. Then, run `lute scripts/test`.

## Usage
The tool can be installed as a dependency to your project using foreman. Simply add this line to your `foreman.toml`.
```
rocale-cli = { source = "Roblox/rocale-cli", version = "0.1.0" }
```

You can also manually grab a release from the [releases](https://github.com/Roblox/rocale-cli/releases) page.

See reference below on using the CLI.

## Reference

```
USAGE:
  rocale-cli <command> [options]

COMMANDS:
  run      Build, upload, and run a Roblox project in OCALE.
  help     Show this help message.
  version  Show version.
```

### `run`

```
USAGE:
  rocale-cli run [options]

REQUIRED:
  -u, --universeId <id>    Target universe ID to spawn an OCALE instance of
  -p, --placeId <id>       Target place ID to spawn an OCALE instance of
  --apiKey <key>           Roblox API key (or set ROBLOX_API_KEY env var)

LOAD OPTIONS:
  --load.project <file>    Rojo project.json/rbxp to build and load (requires rojo or robloxdev-cli)
  --load.place <file>      Load an rbxl
  --load.version <num>     Load existing place version without building/uploading
                           (set to 0 to rerun last uploaded version)

BUILD OPTIONS:
  --output <file>          Output file path for the built place file
                           (default: output.rbxl)
  --script <file>          Luau script to load and set as entrypoint

EXECUTION OPTIONS:
  --timeout <seconds>      Timeout for polling task completion (default: 300)
  --pollInterval <seconds> Interval between polling attempts (default: 2)

FLAGS:
  -v, --verbose            Enable verbose logging
  --help                   Show this help message
```

## Publishing
To publish a new version, first update the `VERSION` string in [`src/cli.luau`](src/cli.luau). Then, [draft a new release](https://github.com/Roblox/rocale-cli/releases/new) and create a new tag with a version string format `vx.x.x`.
