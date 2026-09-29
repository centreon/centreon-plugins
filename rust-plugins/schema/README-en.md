# Rust SNMP collection schema

The `v<N>/rs-collection.schema.json` files describe the format of the JSON files consumed by the
`centreon-plugin-rust-snmp` binary, following the [2020-12](https://json-schema.org/draft/2020-12/schema) draft.
This is the format the collections found in [`../rs-collections/`](../rs-collections/) must comply with.
The CI validates every collection against the version it declares.

## One directory per format version

```
schema/
  v0/rs-collection.schema.json   the beta format, in use today
```

Each format version has its own directory. It is created once, and from then on it only receives
editorial fixes: descriptions, examples, a `pattern` that refused a legitimate value. A change
altering the contract must be made in a new version, so that:

- a collection written for format n keeps being validated by the file it was written for;
- format n+1 can be worked on, reviewed and merged while format n stays untouched;
- the published URL of a version is its directory, so the repository layout cannot drift from
  what the site serves. The build refuses a directory whose schema `$id` names another version.

The published site carries every version found here. Nothing has to be renamed, moved or frozen
when a new one appears: adding the directory is enough.

## Format version

A collection declares the format version, which the plugin uses to make sure that collection suits
its own version, with the mandatory `format_version` key:

```json
{
  "format_version": 0,
  "collect": { "...": "..." }
}
```

The plugin explicitly refuses a collection whose version it cannot handle, rather than failing
later on a key that moved or disappeared.

This version is independent of the plugin package version, which follows the Centreon release
calendar and says nothing about compatibility. Only a change breaking existing collections
increments it:

| Change                                                                                                          | Effect on existing collections                                       | Format version |
|-----------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|----------------|
| Removing or renaming a key, making an optional key mandatory, restricting an enum, changing the meaning of a key | they break                                                           | new directory  |
| Adding an optional key, adding an enum value                                                                    | they keep working, but a new collection needs a recent enough plugin | unchanged      |
| Documentation, examples                                                                                         | none                                                                 | unchanged      |

**Version 0 is the beta format and carries no stability guarantee**: it may break until the first
stable release, which will be version 1.

## Pointing an editor at the schema

A collection names the schema it follows with a `$schema` key, which editors such as PyCharm or
VS Code use to provide completion, inline documentation and live validation:

```json
{
  "$schema": "https://centreon.github.io/centreon-plugins/rs-collections/snmp/v0/rs-collection.schema.json",
  "format_version": 0,
  "collect": { "...": "..." }
}
```

The URL carries the format version, and a published one never changes.

The collections of this repository use that URL, not a path relative to `../../schema/`: a
collection is read far more often outside a checkout than inside one — installed by a package on a
poller, where the `schema/` directory does not exist, or copied onto a workstation as the starting
point for a new check. An absolute URL resolves in all three places, a relative path in one.

The CI checks that the two keys agree: the `$schema` of a collection must be the `$id` of the
schema its `format_version` names. Neither the check nor the schema `$id` spell the URL out twice.

The key is a convention understood by editors only: validators ignore it, and `check-jsonschema`
requires the schema to be passed with `--schemafile`.

**While a format version is still being changed** — which, for version 0, means throughout the
beta — an editor validates against the published schema, not against the one in the branch. The CI
always uses the branch's, so nothing escapes; only the live feedback in the editor may lag by a
merge. Whoever works on the schema itself can point their editor at the local file through its own
JSON Schema mapping, by file pattern.

## Validating a collection

Validating a JSON collection requires `jq` and `check-jsonschema`
(`pip install check-jsonschema`).

To validate the collections supported by Centreon, each against the format version it declares:

```bash
.github/scripts/validate-rs-collections.sh
```

Given file paths, it checks only those. Beyond running the schema validation, it reports a
collection declaring no `format_version`, one declaring a version this repository knows nothing
about, and one whose `$schema` key names another version than its `format_version`.


To check the validity of a schema itself rather than a collection:

```bash
check-jsonschema --check-metaschema rust-plugins/schema/v0/rs-collection.schema.json
```

Both commands are run from the root of the repository.

## Generating the static site

As this file format was not meant to be read by a human being, the easiest way to browse it is to
generate its HTML/JS/CSS rendering.

To do so, first install `json-schema-for-humans` (`pip install json-schema-for-humans`) and
`jq`, then run:

```bash
.github/scripts/build-schema-doc.sh rust-plugins/schema site
```

The script renders every version found in the schema directory and writes a self-contained site
into `site/`. Opening `site/index.html` in a browser is enough to read it.

An optional third argument adds a banner at the top of every page, which the CI uses to mark
pull request renderings.

## Reading the generated page

The project CI regenerates and publishes the site on GitHub Pages:

<https://centreon.github.io/centreon-plugins/>

**While the pull request is open**, there is no URL. To read the rendering anyway:

1. add the `upload-artifacts` label to the pull request
2. push a commit, an empty one will do, so that a run starts with the label on
3. download the `schema-reference-preview` artifact at the bottom of the run page, unzip it and
   open `index.html` in your browser
