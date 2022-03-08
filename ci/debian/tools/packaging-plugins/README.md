# Centreon Plugins continuous integration

## Introduction

Centreon Plugins continuous integration is carried by the Centreon Build project.
This allow easy delivery of plugins on public repositories and better follow-up of changes.

This documentation presents the workflows to build and deliver packaged plugins on
unstable, testing and stable repositories.

### Basic principles

Packaged plugins are formed by two components:

* Source code from [Centreon-Plugins](<https://github.com/centreon/centreon-plugins>) project,
* Configuration files for standalone plugin files build and package dependencies management.

Those configuration files are hosted in this project.

### Continuous integration workflows

As the packaging process is based on two components, the CI can be triggered by both.

![workflow](.images/ci_workflow.png "Continuous integration workflows")

* Each time a commit is made on Centreon Plugins master branch, a build is automatically launched (green arrows),
* Each time a new plugin configuration files are added, or existing files modified, a build as to
  be launched manually (purple arrows).

The Jenkins job in charge of building unstable packages is the
[Centreon EPP/Centreon Plugins/master](<https://jenkins.centreon.com/view/Centreon%20EPP/job/centreon-plugins/job/master/>) job.

For each successful jobs, packages will be available on the unstable repositories:

* 2.8/CentOS 7: <http://yum.centreon.com/standard/3.4/el7/unstable/noarch/plugins/>,
* 18.10/CentOS 7: <http://yum.centreon.com/standard/18.10/el7/unstable/noarch/plugins/>.

Each time stamped subdirectories represents a successful build.

To make a build goes from unstable to testing, the
[centreon-plugins-testing](<https://jenkins.centreon.com/view/Centreon%20EPP/job/centreon-plugins-testing/>) job
should be launched.
This job needs a version and a release number:

* The version is the date of the unstable build considered as the most mature,
* The release number is the time of the unstable build considered as the most mature.

For each successful jobs, packages will be available on the testing repositories:

* 2.8/CentOS 7: <http://yum.centreon.com/standard/3.4/el7/testing/noarch/plugins/>,
* 18.10/CentOS 7: <http://yum.centreon.com/standard/18.10/el7/testing/noarch/plugins/>.

To make a build goes from testing to stable, the
[centreon-plugins-stable](<https://jenkins.centreon.com/view/Centreon%20EPP/job/centreon-plugins-stable/>) job
should be launched.
It takes the same parameters as the testing job.

Packages are now available on standard stable repositories.

## How to create a new packaged plugin

### Clone Centreon Build project

Clone the master branch of the Centreon Build project

```bash
# git clone https://github.com/centreon/centreon-build
```

### Create configuration files

#### Create new directory

In the *centreon-build/packaging/plugins* directory, create a new directory.

```bash
# cd centreon-build/packaging/plugins
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

Extra entries can be used, for example to make a package obsoleting another one:

```bash
    "custom_pkg_data": "Obsoletes:    centreon-plugin-Old-Plugin",
```

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

### Commit and push changes

In the project directory, create a new branch:

```bash
# git checkout -B add-my-new-plugin
```

Add the new directory and files to be commited:

```bash
# git add packaging/plugins/centreon-plugin-My-Plugin
```

Commit the changes, respecting project format:

```bash
# git commit -m "feat(plugin): add new my-plugin json files"
```

Push the commit to your own fork:

```bash
# git push https://github.com/<username>/centreon-build add-my-new-plugin
```

Create a new pull request on the project and wait for the build team to accept it.

### Launch a Jenkins build

From the Jenkins *Centreon EPP* tab, launch the Centreon Plugins/master job
(<https://jenkins.centreon.com/view/Centreon%20EPP/job/centreon-plugins/job/master/>)

If the build succeed, the new plugin will be available on unstable repositories.

## How to edit a packaged plugin

### Clone Centreon Build project

Clone the master branch of the Centreon Build project

```bash
# git clone https://github.com/centreon/centreon-build
```

### Edit configuration files

In the plugin configuration files directory, edit either *pkg.json*, *rpm.json* or *deb.json* files.

```bash
# cd centreon-build/packaging/plugins/centreon-plugin-My-Plugin
# vi pkg.json
```

### Commit and push changes

In the project directory, create a new branch:

```bash
# git checkout -B fix-my-plugin
```

Add the modified files to be commited:

```bash
# git add packaging/plugins/centreon-plugin-My-Plugin/pkg.json
```

Commit the changes, respecting project format:

```bash
# git commit -m "fix(plugin): fix my-plugin pkg.json file, adding common code"
```

Push the commit to your own fork:

```bash
# git push https://github.com/<username>/centreon-build fix-my-plugin
```

Create a new pull request on the project and wait for the build team to accept it.

### Launch a Jenkins build

From the Jenkins *Centreon EPP* tab, launch the Centreon Plugins/master job
(<https://jenkins.centreon.com/view/Centreon%20EPP/job/centreon-plugins/job/master/>)

If the build succeed, the new plugin will be available on unstable repositories.
