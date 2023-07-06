# Continuous integration

## Introduction

Centreon Plugins continuous integration is carried by the Centreon Build project.
This allow easy delivery of plugins on public repositories and better follow-up of changes.

This chapter presents the workflows to build and deliver packaged plugins on
unstable, testing and stable repositories.

### Basic principles

Packaged plugins are formed by two components:

* [Source code](../src)
* [Configuration files](../packaging) for standalone plugin files build and package dependencies management.

### Workflows

Workflows are available [here](<https://github.com/centreon/centreon-plugins/actions>).

* Each time a commit is made on **develop** branch, a build is triggered and publish updated plugins in unstable repositories
* Each time a commit is made on a branch name which begins by **release**, a build is triggered and publish updated plugins in testing repositories
* Each time a commit is made on **master** branch, a build is triggered and publish updated plugins in stable repositories
* Each time a pull request is opened or updated, a build is triggered and publish updated plugins as artifacts (zip file downloadable directly from workflow)

When plugins are built, The version is the current date and the release is the current time

## How to create a new packaged plugin

### Create configuration files

#### Create new directory

In the *centreon-build/packaging/* directory, create a new directory.

```bash
# cd packaging
# mkdir centreon-plugin-<name>
```

The name of the package is generaly made from the tree of the plugin's source code but with some
specificities, for examples:

* *centreon-plugin-Network-Huawei-Snmp* plugin is for *network/huawei/snmp/* source code,
* *centreon-plugin-Applications-Antivirus-Kaspersky-Snmp* plugin is for *apps/antivirus/kaspersky/snmp/* source code,
* *centreon-plugin-Network-Firewalls-Paloalto-Standard-Snmp* plugin is for *network/paloalto/snmp/* source code.

Ask slack *#software-plugin-packs* channel to confirm name if needed.

#### Create standalone plugin configuration file

In the previously created directory, create a new JSON file named *pkg.json*.

In this file must appear the following mandatory entries:

* *pkg_name*: name of the package, same than the parent directory,
* *pkg_summary*: short string describing the plugin, starting with "Centreon Plugin to monitor",
* *plugin_name*: name of the standalone plugin file, starting with "centreon_" and made of words making this file unique,
* *files*: table listing all files that should be included in the standalone file, like common code and specific plugin code.

For example:

```bash
{
    "pkg_name": "centreon-plugin-Applications-Antivirus-Kaspersky-Snmp",
    "pkg_summary": "Centreon Plugin to monitor Kaspersky Security Center using SNMP",
    "plugin_name": "centreon_kaspersky_snmp.pl",
    "files": [
        "centreon/plugins/script_snmp.pm",
        "centreon/plugins/snmp.pm",
        "apps/antivirus/kaspersky/snmp/"
    ]
}
```

The following files are included by default:

* centreon/plugins/alternative/Getopt.pm,
* centreon/plugins/alternative/FatPackerOptions.pm,
* centreon/plugins/misc.pm,
* centreon/plugins/mode.pm,
* centreon/plugins/multi.pm,
* centreon/plugins/options.pm,
* centreon/plugins/output.pm,
* centreon/plugins/perfdata.pm,
* centreon/plugins/script.pm,
* centreon/plugins/statefile.pm,
* centreon/plugins/templates/counter.pm,
* centreon/plugins/templates/hardware.pm,
* centreon/plugins/values.pm.

#### Create package dependencies management files

In the previously created directory, create two new JSON files named *rpm.json* and *deb.json*.

In this files must appear the following mandatory entry:

* *dependencies*: table listing all the perl dependencies that should be installed (does not include Perl core libraries),

Example of *rpm.json* file:

```bash
{
    "dependencies": [
        "perl(SNMP)",
        "perl(DateTime)"
    ]
}
```

Example of *deb.json* file:

```bash
{
    "dependencies": [
        "libsnmp-perl",
        "libdatetime-perl"
    ]
}
```

Extra entries can be used in *rpm.json* and *deb.json*, for example to make a package obsoleting another one:

```bash
    "conflicts": "centreon-plugin-Old-Plugin",
    "replaces": "centreon-plugin-Old-Plugin",
    "provides": "centreon-plugin-Old-Plugin",
```

### Commit and push changes

In the project directory, create a new branch:

```bash
# git checkout -B add-my-new-plugin
```

Add the new directory and files to be commited:

```bash
# git add packaging/centreon-plugin-My-Plugin
```

Commit the changes, respecting project format:

```bash
# git commit -m "feat(plugin): add new my-plugin json files"
```

Push the commit to your own fork:

```bash
# git push https://github.com/<username>/centreon-plugins add-my-new-plugin
```

Create a new pull request on the project

Check packaged plugins in workflow artifacts

## How to edit a packaged plugin

### Edit configuration files

In the plugin configuration files directory, edit either *pkg.json*, *rpm.json* or *deb.json* files.

```bash
# cd packaging/centreon-plugin-My-Plugin
# vi pkg.json
```

### Commit and push changes

In the project directory, create a new branch:

```bash
# git checkout -B fix-my-plugin
```

Add the modified files to be commited:

```bash
# git add packaging/centreon-plugin-My-Plugin/pkg.json
```

Commit the changes, respecting project format:

```bash
# git commit -m "fix(plugin): fix my-plugin pkg.json file, adding common code"
```

Push the commit to your own fork:

```bash
# git push https://github.com/<username>/centreon-plugins fix-my-plugin
```

Create a new pull request on the project

Check packaged plugins in workflow artifacts
