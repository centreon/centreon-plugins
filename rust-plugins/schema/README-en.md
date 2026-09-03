# Rust SNMP collection schema

The `rs-collection.schema.json` file describes the format of the JSON files consumed by the
`centreon-plugin-rust-snmp` binary, following the [2020-12](https://json-schema.org/draft/2020-12/schema) draft.
This is the format the collections found in [`../rs-collections/`](../rs-collections/) must comply with.
The CI validates every collection against this reference file.

## Generating the static site

This file format was not meant to be read by a human being, the easiest way to browse it is to
generate its HTML/JS/CSS rendering.

To do so, first install `json-schema-for-humans` (`pip install json-schema-for-humans`), then run:

```bash
.github/scripts/build-schema-doc.sh rust-plugins/schema/rs-collection.schema.json site
```

The script writes a self-contained site into `site/`. Opening `site/rs-collections/snmp/index.html`
in a browser is enough to read it.

An optional third argument adds a banner at the top of every page, which the CI uses to mark
pull request renderings.

## Validating a collection

Validating a JSON collection requires `check-jsonschema` to be installed
(`pip install check-jsonschema`).

To validate every collection supported by Centreon:

```bash
check-jsonschema --schemafile rust-plugins/schema/rs-collection.schema.json rust-plugins/rs-collections/*/*.json
```

To check the validity of the schema itself rather than a collection:

```bash
check-jsonschema --check-metaschema rust-plugins/schema/rs-collection.schema.json
```

Both commands are run from the root of the repository. This check, along with the one covering
every collection, is run by the repository `pre-commit` hook and then by the CI.

## Reading the generated page

The project CI regenerates and publishes the site on GitHub Pages:

<https://centreon.github.io/centreon-plugins/rs-collections/snmp/>

**While a pull request is open** there is no URL. To read the rendering anyway:

1. add the `upload-artifacts` label to the pull request
2. rerun the `rs-collection-schema` workflow
3. download the `schema-reference-preview` artifact at the bottom of the run page, unzip it and
   open `index.html` in your browser
