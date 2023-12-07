# Plugins / Connectors global documentation

<div id='table_of_contents'/>

*******
Table of contents
1. [Overview](#overview)
2. [Understand the data](#understand_data)
3. [Directories layout](#architecture_layout)
4. [Set up your environment](#set_up)
5. [Code Style Guidelines](#code-style-guidelines)
6. [plugin.pm](#create_plugin)
7. [mode.pm](#create_mode)
8. [Tutorials](#tutorials)
9. [Commit and Fatpack generation](#fatpack)
10. [Plugin outputs](#outputs)
11. [Plugins options](#options)
12. [Discovery](#discovery)
13. [Performances](#performances)
14. [Security](#security)
15. [Help and documentation](#help_doc)
*******

<div id='overview'/>

## 1. Overview

Centreon plugins are a free and open source way to monitor systems. The project 
can be used with Centreon and all monitoring softwares compatible with Nagios 
plugins. You can monitor many systems:

* **application**: Apache, Asterisk, Elasticsearch, Github, Jenkins, Kafka, 
  Nginx, 
Pfsense, Redis, Tomcat, Varnish,...
* **cloud**: AWS, Azure, Docker, Office365, Nutanix, Prometheus,...
* **database**: Firebird, Informix, MS SQL, MySQL, Oracle, Postgres, Cassandra
* **hardware**: printers (rfc3805), UPS (Powerware, Mge, Standard), Sun 
  Hardware, 
Cisco UCS, SensorIP, HP Proliant, HP Bladechassis, Dell Openmanage, Dell CMC, 
Raritan,...
* **network**: Aruba, Brocade, Bluecoat, Brocade, Checkpoint, Cisco 
  AP/IronPort/ASA/
Standard, Extreme, Fortigate, H3C, Hirschmann, HP Procurve, F5 BIG-IP, Juniper,
PaloAlto, Redback, Riverbed, Ruggedcom, Stonesoft,...
* **os**: Linux (SNMP, NRPE), Freebsd (SNMP), AIX (SNMP), Solaris (SNMP)...
* **storage**: EMC Clariion, Netapp, Nimble, HP MSA p2000, Dell EqualLogic, 
  Qnap, 
Panzura, Synology...

This document introduces the best practices in the development of 
"centreon-plugins".

As all plugins are written in Perl, “there is more than one way to do it”.
But to avoid reinventing the wheel, you should first take a look at the 
“example” directory, you will get an overview of how to build your own plugin 
and associated modes.

The lastest version is available on following git repository: 
https://github.com/centreon/centreon-plugins.git

[Table of contents](#table_of_contents)

<div id='understand_data'/>

## 2.Understand the data

First of any development, understanding the data is very important as it will drive the way you will design
the **mode** internals. This is the **first thing to do**, no matter what protocol you
are using.

There are several important properties for a piece of data:

- Type of the data to process: string, int... There is no limitation in the kind of data you can process
- Dimensions of the data, is it **global** or linked to an **instance**?
- Data layout, in other words anticipate the kind of **data structure** to manipulate.

Coming soon : A mindmap of what type of plugins is adequate

[Table of contents](#table_of_contents)

<div id='architecture_layout'/>

## 3. Directories layout

### 3.1 Plugins directories layout

The project content is made of a main binary (`centreon_plugins.pl`), and a 
logical directory structure allowing to separate plugins and modes files across 
the domain they are referring to.

You can display it using the command `tree -L 1`. 

```shell
.
├── apps
├── blockchain
├── centreon
├── centreon_plugins.pl
├── changelog
├── cloud
├── contrib
├── database
├── doc
├── example
├── hardware
├── Jenkinsfile
├── LICENSE.txt
├── network
├── notification
├── os
├── README.md
├── snmp_standard
├── sonar-project.properties
└── storage
```
Root directories are organized by section:

* Application       : apps
* Database          : database
* Hardware          : hardware
* Network equipment : network
* Operating System  : os
* Storage equipment : storage

### 3.2 Single plugin directory layout

According to the monitored object, it exists an organization which can use:

* Type
* Constructor
* Model
* Monitoring Protocol

Let's take a deeper look at the layout of the directory containing modes to 
monitor Linux systems through the command-line (`tree os/linux/local/ -L 1`). 

```shell
os/linux/local/
├── custom      # Type: Directory. Contains code that can be used by several modes (e.g authentication, token management, ...).
│   └── cli.pm  # Type: File. *Custom mode* defining common methods 
├── mode        # Type: Directory. Contains all **modes**. 
[...]
│   └── cpu.pm  # Type: File. **Mode** containing the code to monitor the CPU
[...]
└── plugin.pm   # Type: File. **Plugin** definition.
```
Note the os/linux/local. The project offers other ways to monitor Linux, SNMP 
for example. To avoid mixing modes using different protocols in the same 
directory and face some naming collisions, we split them across several 
directories making it clear what protocol they rely on.

Now, let's see how these concepts combine to build a command line:
```shell
# <perl interpreter> <main_binary> --plugin=<perl_normalized_path_to_plugin_file> --mode=<mode_name> 
perl centreon_plugins.pl --plugin=os::linux::local::plugin --mode=cpu
```

### 3.3 Shared directories

Some specific directories are not related to a domain (os, cloud...) and are 
used across all plugins.

#### 3.3.1 The centreon directory

The centreon directory is specific, it contains:

* **Project libraries/packages**. This is all the code that will help you to 
develop faster by avoiding coding protocol-related things (SNMP, HTTPx, SSH...) 
or common things like options or cache management from scratch. You can read the 
perl modules if you're an experienced developer but there is very little 
chance that you would have to modify anything in it.
* **Common files shared by multiple plugins**. This is to avoid duplicating 
code across the directory tree and ease the maintenance of the project.

An more detailed description of this libraries is available [here](plugins_advanced.md)

#### 3.3.2 The snmp_standard/mode directory

The snmp_standard/mode exists since the beginning when SNMP monitoring was much 
more used than it is today. All the modes it contains use standard OIDs, which 
means that many plugins are relying on these when the manufacturer supports 
standard MIBs on their devices.

[Table of contents](#table_of_contents)

<div id='set_up'/>

## 4.Set up your environment

[Table of contents](#table_of_contents)

To use the centreon-plugins framework, you'll need the following: 

- A Linux operating system, ideally Debian 11 or RHEL/RHEL-like >= 8
- The [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) command line utility
- A [GitHub](https://github.com/) account.

### Enable our standard repositories

#### Debian

If you have not already install lsb-release, first you need to follow this steps :

If needed go to sudo mode
```shell
sudo -i
```
Install lib-release
```shell
apt install lsb-release
```
Create access to centreon repository (note you may need to change the version in example it's 22.04 but you can select one most up to date)
```shell
echo "deb https://apt.centreon.com/repository/22.04/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/centreon.list
wget -O- https://apt-key.centreon.com | gpg --dearmor | tee /etc/apt/trusted.gpg.d/centreon.gpg > /dev/null 2>&1
```
Install the following dependencies: 
```shell
apt-get install 'libpod-parser-perl' 'libnet-curl-perl' 'liburi-encode-perl' 'libwww-perl' \
    'liblwp-protocol-https-perl' 'libhttp-cookies-perl' 'libio-socket-ssl-perl' 'liburi-perl' \
    'libhttp-proxypac-perl' 'libcryptx-perl' 'libjson-xs-perl' 'libjson-path-perl' \
    'libcrypt-argon2-perl' 'libkeepass-reader-perl' 
```
#### RHEL 8 and alike
Create access to centreon repository (note you may need to change the version in example it's 22.04 but you can select one most up to date)
```shell
dnf install -y https://yum.centreon.com/standard/22.04/el8/stable/noarch/RPMS/centreon-release-22.04-3.el8.noarch.rpm
```
Install the following dependencies: 
```shell
dnf install 'perl(Digest::MD5)' 'perl(Pod::Find)' 'perl-Net-Curl' 'perl(URI::Encode)' \
    'perl(LWP::UserAgent)' 'perl(LWP::Protocol::https)' 'perl(IO::Socket::SSL)' 'perl(URI)' \
    'perl(HTTP::ProxyPAC)' 'perl-CryptX' 'perl(MIME::Base64)' 'perl(JSON::XS)' 'perl-JSON-Path' \
    'perl-KeePass-Reader' 'perl(Storable)' 'perl(POSIX)' 'perl(Encode)'
```

#### Fork and clone the centreon-plugins repository

Within GitHub UI, on the top left, click on the **Fork** button.

Use the git utility to fetch your repository fork:

```shell
git clone https://<githubusername>@github.com/<githubusername>/centreon-plugins
```

Create a branch:

```shell
cd centreon-plugins
git checkout -b 'my-first-plugin'
```

[Table of contents](#table_of_contents)

<div id='code-style-guidelines'/>

## 5. Code Style Guidelines

**Introduction**

Perl code from Pull-request must conform to the following style guidelines. If you find any code which doesn't conform, please fix it.

### 5.1 Indentation

Space should be used to indent all code blocks. Tabs should never be used to indent code blocks. Mixing tabs and spaces results in misaligned code blocks for other developers who prefer different indentation settings.
Please use 4 for indentation space width.

```perl
    if ($1 > 1) {
    ....return 1;
    } else {
        if ($i == -1) {
        ....return 0;
        }
        return -1
    }
```

### 5.2 Comments

There should always be at least 1 space between the # character and the beginning of the comment.  This makes it a little easier to read multi-line comments:

```perl
    # Good comment
    #Wrong comment
```

### 5.3 Subroutine & Variable Names

Whenever possible, use underscore to seperate words and don't use uppercase characters:

```perl
    sub get_logs {}
    my $start_time;
```
Keys of hash table should use alphanumeric and underscore characters only (and no quote!):

```perl
    $dogs->{meapolitan_mastiff} = 10;
```

### 5.4 Curly Brackets, Parenthesis

There should be a space between every control/loop keyword and the opening parenthesis:

```perl
    if ($i == 1) {
        ...
    }
    while ($i == 2) {
        ...
    }
```

### 5.5 If/Else Statements

'else', 'elsif' should be on the same line after the previous closing curly brace:

```perl
    if ($i == 1) {
        ...
    } else {
        ...
    }
```
You can use single line if conditional:

```perl
    next if ($i == 1);
```

[Table of contents](#table_of_contents)

<div id='create_plugin'/>

## 6.plugin.pm

The `plugin.pm` is the first thing to create, it contains:

- A set of instructions to load required libraries and compilation options
- A list of all **mode(s)** and path(s) to their associated files/perl packages
- A description that will display when you list all plugins or display this plugin's help.

In this file you can always find : 
* **license / copyright**

First this file contains the Copyright section. At the end of it, you can add 
your author informations like this :
```
# ...
# Authors : <your name> <<your email>>
```

* **package name**

Path to your package. '::' instead of '/', and no .pm 
at the end.

```perl
package path::to::plugin;
```

* **libraries**

Strict and warnings are mandatory

```perl
use strict;
use warnings;
```

One of the centreon libraries :

```perl
use base qw(**centreon_library**);
```
There are five kinds of centreon libraries access here :
* centreon::plugins::script_simple : Previously the general use case if no custom is needed, more explainations [here](tutorial-api.md) in this section.
* centreon::plugins::script_custom : Need custom directory - More explainations [here](tutorial-api.md) in this section.
* centreon::plugins::script_snmp : If SNMP protocol is needed for this plugin
* centreon::plugins::script_sql : If DB acess is needed for this plugin
* centreon::plugins::script_wsman : Concern Windows specific protocols


* **new constructor**

The plugin need a new constructor to instantiate the object:
```perl
sub new {
      my ($class, %options) = @_;
      my $self = $class->SUPER::new(package => __PACKAGE__, %options);
      bless $self, $class;

      # Plugin version declaration is in the new constructor:
      $self->{version} = '0.1';

      # Several modes can be declared in the new constructor:
      %{$self->{modes}} = (
                      'mode1'    => '<plugin_path>::mode::mode1',
                      'mode2'    => '<plugin_path>::mode::mode2',
                      ...
                      );

      return $self;
}
```

* **documentation section**

A description of the plugin is needed to generate the documentation:

```perl
__END__

=head1 PLUGIN DESCRIPTION

<Add a plugin description here>.

=cut
```
> **TIP** : You can copy-paste an other plugin.pm and adapt some lines (package, arguments...).
 The plugin has ".pm" extension because it's a Perl module. So don't forget to add 1; at the end of the file.

[Table of contents](#table_of_contents)

<div id='create_mode'/>

## 7.mode.pm

Mode.pm as plugin.pm has also :
* license / copyright
* package name
* libraries
* new constructor

But mode.pm also usually contains:
* options in the new constructor
* check_options method
* manage_selection method (called run in old contain)

```perl

  # ...
  # Authors : <your name> <<your email>>
  
  package path::to::plugin::mode::mode1;

  use strict;
  use warnings;
  use base qw(centreon::plugins::mode);

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }
```
Mode version must be declared in the **new** constructor:

```perl

  $self->{version} = '1.0';

```
Several options can be declared in the **new** constructor:

```perl

  $options{options}->add_options(arguments => {
      "option1:s" => { name => 'option1' },
      "option2:s" => { name => 'option2', default => 'value1' },
      "option3"   => { name => 'option3' },
  });

```
Here is the description of arguments used in this example:

* option1 : String value
* option2 : String value with default value "value1"
* option3 : Boolean value

> **TIP 1** : Options are boolean as default and string if set ":s", no other type are allowed in this argument descriptions. 
The actual type of the argument, if it is other than a string, can be checked and interpreted in ```check_option()``` function defined below.

> **TIP 2** : You can have more informations about options format here: http://perldoc.perl.org/Getopt/Long.html

The mode can have a **check_options** method to validate options:

```perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    ...
  }

```
For example, Warning and Critical thresholds can be validated in 
**check_options** method:

```perl

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
  }
  if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
  }

```
In this example, help is printed if thresholds do not have a correct format.

Previously went the *run* method, where were performed measurement, check 
thresholds, display output and format performance datas.

Since this method had been split in at least two methods :
* **set_counters** : describe data structure and their properties
  (like  thresholds and how they will be displayed to the users). This 
  method is split in two functions

```perl

  sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'radios', type => 1, cb_prefix_output => 'prefix_radio_output', message_multiple => 'All raadio interfaces are ok' }
    ];

```

* **manage_selection** : method use as main sub in the mode 
* Various output custom methods.

Examples are available in the Tutorial section.

Then, declare the module:

```perl

  1;

```
A description of the mode and its arguments is needed to generate the documentation:

```perl

  __END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut

```

[Table of contents](#table_of_contents)

<div id='tutorials'/>

## 8. Tutorials

To help users to understand the most popular plugins you can find several tutorials to help you to develop your first plugin.

* [API plugin tutorial](tutorial-api.md)
* [SNMP plugin tutorial](tutorial-snmp.md)
* [Service discovery tutorial](tutorial-service_discovery.md)

[Table of contents](#table_of_contents)

<div id='fatpack'/>

## 9. Commit and Fatpack generation

### 9.1. Commit and push

When you have finished your plugin development, before committing a plugin, you need to create an **enhancement ticket** on the 
centreon-plugins forge : http://forge.centreon.com/projects/centreon-plugins

Once plugin and modes are developed, you can commit (commit messages in english)
and push your work:

```shell
  git add path/to/plugin
  git commit -m "Add new plugin for XXXX refs #<ticked_id>"
  git push
```

### 9.2 FatPack generation

Centreon plugin-pack use plugins through FatPack format.
To convert your plugin into Fatpack format follow this steps :

Install libapp-fatpacker-perl
```shell
sudo apt install libapp-fatpacker-perl
```

Create a shell script ```plugin_generator.sh```

```shell
#!/bin/bash

BuildDir=/home/<user_name>/fatpack_generator #Directory path where build the fatpack
GitPluginBranch=my-first-plugin #Branch you have create in "Set up your environment" section
PluginPath=cloud/docker/local #Path from src to your plugin directory
PluginPathMode=cloud/docker/local/mode #Path from src to your plugin mode directory
ScriptName=centreon_docker_ssh #Set the name of your Fatpack.pl / This name is the one used in plugin-pack

if [ ! -d "$BuildDir" ]; then
    echo 'Create BuildDir'
    mkdir $BuildDir
fi
cd $BuildDir

if [ -d "centreon-plugins" ]; then
    echo 'Update centreon-plugins'
    cd centreon-plugins
    git checkout develop -f
	git fetch
    git checkout $GitPluginBranch -f
	git pull
    cd ..
else
    echo 'Clone centreon-plugins'
    git clone --branch $GitPluginBranch https://github.com/centreon/centreon-plugins.git
fi

if [ -d "plugin" ]; then
    echo 'Remove plugin'
    rm -R plugin
fi
echo 'Create plugin/lib'
mkdir -p plugin/lib
cd $BuildDir/centreon-plugins/src
echo $PWD
echo 'Find pm'
find . -name "*.pm" -exec sed -i ' /__END__/d' {} \;

echo 'Copy common plugins files'
cp -R --parent centreon/plugins/{http,misc,mode,options,output,perfdata,script,statefile,values}.pm centreon/plugins/backend/ centreon/plugins/templates/ centreon/plugins/alternative/ ../../plugin/lib/
echo 'Copy centreon_plugins.pl'
cp centreon_plugins.pl ../../plugin
echo 'Prepare fatpacker'
cp -R --parent $PluginPathMode ../../plugin/lib/
sed -i 's/alternative_fatpacker = 0/alternative_fatpacker = 1/' ../../plugin/lib/centreon/plugins/script.pm

echo 'Copy plugin files'
cp -R --parent centreon/plugins/{script_snmp,snmp}.pm $PluginPath snmp_standard/mode/{cpu,cpudetailed,diskio,diskusage,inodes,interfaces,loadaverage,listdiskspath,listinterfaces,liststorages,memory,processcount,storage,swap,ntp,tcpcon,uptime}.pm snmp_standard/mode/resources/ ../../plugin/lib/

cd ../../plugin
echo 'Generate fatpack'
fatpack file centreon_plugins.pl > $ScriptName.pl
```

Execute plugin_generator.sh
```shell
sudo ./plugin_generator.sh
```

You can find your FatPack plugin in the folder plugin in ```BuildDir/plugin```

[Table of contents](#table_of_contents)

<div id='outputs'/>

## 10. Plugin outputs

### 10.1 Formatting

The output of a monitoring probe must always be:

```bash
STATUS: Information text | metric1=<value>[UOM];<warning_value>;<critical_value>;<minimum>;<maximum> metric2=value[OEM];<warning_value>;<critical_value>;<minimum>;<maximum> \n
Line 1 containing additional details \n
Line 2 containing additional details \n 
Line 3 containing additional details \n
```

Let’s identify and name its three main parts:

* Short output: everything before the pipe (`|`)
* Performance data and Metrics: everything after the pipe (`|`)
* Extended output: Everything after the first carriage return (`\n`), splitting each detail line is the best practice.

### 10.2 Short output

This part is the one users will more likely see in their monitoring tool or obtain as part of a push/alert message. The information should be straightforward and help identify what is going on quickly.

A plugin must always propose at least such output:

```bash
STATUS: Information text 
```

`STATUS`must stick with return codes:

* 0: OK
* 1: WARNING
* 2: CRITICAL
* 3: UNKNOWN

`Information text` should display only relevant information. That implies:

* showing only the bits of information that led to the NOT-OK state when an alarm is active
* keeping it short. When checking a large number of a single component (e.g. all partitions on a filer), try to construct a global message, then switch to the format above when an alarm arises.

#### Centreon Plugin example

The output when checking several storage partitions on a server, when everything is OK:

`OK: All storages are ok |`

The output of the same plugin, when one of the storage partition space usages triggers a WARNING threshold:

`WARNING: Storage '/var/lib' Usage Total: 9.30 GB Used: 956.44 MB (10.04%) Free: 8.37 GB (89.96%) |`

### 10.3 Performance data and metrics

This part is not mandatory. However, if you want to benefit from Centreon or Nagios©-like tools with built-in metrology features, you will need to adopt this format:

`metric1=<value>[UOM];<warning_value>;<critical_value>;<minimum>;<maximum>`

After the equals sign, split each piece of information about the metric using a semi-colon.

* `metric1=`: The metric’s name is everything before the equals (=) sign. The more detailed it is, the easier it will be to understand a graph or to extend the usability of the metric in a third-party analytics/observability platform. De facto, a metric name must not contain an equals sign. Try to make it self-explanatory even without the Host/Service context.
* `<value>`: The measurement result, must be a number (int, float)
* `[UOM]`: Optional Unit Of Measurement. You can also include the unit in the metric’s name as we do in the Centreon metric naming philosophy. It is one of the following:
  * none (no unit specified), when dealing with a number of things (e.g. users, licences, viruses…)
  * 's' when dealing with seconds. ‘us’ and ‘ms’ are also valid for microseconds or milliseconds (e.g. response or connection time)
  * '%' when dealing with percentage (e.g. memory, CPU, storage space…)
  * 'B' (Bytes), when dealing with storage, memory… The Byte must be the default as it ensures compatibility with all Centreon extensions
  * When dealing with a network metric or any throughput, ‘b' (Bits). When computing a rate per second, you can use ‘b/s’
* `<warning_value>`:  Optional. Fill it with the user’s value as a WARNING threshold for the metric.
* `<critical_value>`: Optional. Fill it with the user-supplied value as a CRITICAL threshold for the metric.
* `<minimum>`: Optional. Fill it with the lowest value the metric can take.
* `<maximum>`: Optional. Fill it with the highest value the metric can take.

Frequently, you have to manage the case where you have to display the same metric for several instances of things. The best practice is to choose a character to separate the metric name from its instance with a given character. At Centreon, we use the `#` sign, and we strongly recommend you do the same (it is recognised and processed by Centreon-Broker).

Less frequently, you may want to add even more context; that’s why we created a sub-instance concept following the same principles. Append it to the instance of your metric and use a splitting character to clarify that it is another dimension and not confuse it with the primary instance. We use the `~` sign; once again, we strongly advise you to stick with it whenever it is possible.

#### Centreon Plugin Performance Data / Metrics examples

A **system boot partition**

`'/boot#storage.space.usage.bytes'=255832064B;;0:99579084;0;995790848`

`/boot` is the instance

`storage.space.usage.bytes` is the metric name (note the .bytes at the end specifying the unit)

`B` is the legacy metric’s unit for Bytes.

Pay attention to the critical threshold (0:99579084), always use the same unit.

A **network interface**

`'eth0#interface.traffic.in.bitspersecond'=0.00b/s;;;0;`

`eth0` is the instance

`interface.traffic.in.bitspersecond` is the metric name (note the `.persecond` at the end specifying the unit)

`b/s` is the legacy metric’s unit for bits per second

A **cloud metric**

`'azure-central~/var/lib/mysql#azure.insights.logicaldisk.free.percentage'=94.82%;;;0;100`

`azure-central` is the instance

`/var/lib/mysql` is the sub-instance

`azure.insights.logicaldisk.free.percentage` is the metric name (note the `free` instead of `usage`, and `.percentage` at the end to specify the unit)

`%` is the legacy metric’s unit

### 10.4 Extended output

The extended output's primary purpose is to display each bit of collected information separately on a single line. It will only print if the user adds a `--verbose` flag to its command.

Overall, you should use it to:

* add extra context (numbered instance, serial number) about a checked component
* print items the check excludes because plugin options have filtered them out
* organize how the information is displayed using groups that follow the logic of the check.

#### Centreon Plugin example

Here is an example of a Cisco device environment check:

```bash
<STATUS>: <information_text> | <perfdata>
Environment type: other
Checking fans
  fan 'Switch X - FAN - T1 1, Normal' status is normal [instance: 1014].
  fan 'Switch X - FAN - T1 2, Normal' status is normal [instance: 1015].
  fan 'Switch X <SERIAL-NUMBER> - FAN 1' status is up [instance: 1014]
  fan 'Switch X <SERIAL-NUMBER> - FAN 2' status is up [instance: 1015]
Checking power supplies
  power supply 'Switch X - Power Supply B, Normal' status is normal [instance: 1013] [source: ac]
  Power supply 'Switch X - Power Supply B' status is on [instance: 1013]
Checking temperatures
  temperature 'Switch X - Inlet Temp Sensor, GREEN ' status is normal [instance: 1010] [value: 23 C]
  temperature 'Switch X - Outlet Temp Sensor, GREEN ' status is normal [instance: 1011] [value: 30 C]
  temperature 'Switch X - HotSpot Temp Sensor, GREEN ' status is normal [instance: 1012] [value: 41 C]
Checking voltages
Checking modules
  module 'C9200L-48P-4G' status is ok [instance: 1000]
Checking physicals
Checking sensors
  sensor 'Switch X <SERIAL-NUMBER> - Temp Inlet Sensor 0' status is 'ok' [instance: 1010] [value: 23 celsius]
  sensor 'Switch X <SERIAL-NUMBER> - Temp Outlet Sensor 1' status is 'ok' [instance: 1011] [value: 30 celsius]
  sensor 'Switch X <SERIAL-NUMBER> - Temp Hotspot Sensor 2' status is 'ok' [instance: 1012] [value: 41 celsius]
  sensor 'GigabitEthernet1/1/1 Module Temperature Sensor' status is 'ok' [instance: 1115] [value: 29.2 celsius]
  sensor 'GigabitEthernet1/1/1 Supply Voltage Sensor' status is 'ok' [instance: 1116] [value: 3.3 voltsDC]
  sensor 'GigabitEthernet1/1/1 Bias Current Sensor' status is 'ok' [instance: 1117] [value: 0.0202 amperes]
  sensor 'GigabitEthernet1/1/1 Transmit Power Sensor' status is 'ok' [instance: 1118] [value: -4.5 dBm]
  sensor 'GigabitEthernet1/1/1 Receive Power Sensor' status is 'ok' [instance: 1119] [value: -1.2 dBm]
```

[Table of contents](#table_of_contents)

<div id='options'/>

## 11. Plugins Options

Option management is a central piece of a successful plugin. You should:

* Carefully name your options to make them **self-explanatory**
* For a given option, **only one format** is possible (either a flag or a value, but not both)
* Always **check** for values supplied by the user and print a **clear message** when they do not fit with plugin requirements
* Set default option value when relevant

[Table of contents](#table_of_contents)

<div id='discovery'/>

## 12. Discovery

This section describes how you should format your data to comply with the requirements of Centreon Discovery UI modules.

In a nutshell:

* [host discovery](/docs/monitoring/discovery/hosts-discovery) allows you to return a JSON list the autodiscovery module will understand so the user can choose to automatically or manually add to its monitoring configuration. Optionally, it can use one of the discovered items properties to make some decisions (filter in or out, create or assign a specific host group, etc.)
* [service discovery](/docs/monitoring/discovery/services-discovery) allows you to return XML data to help users configure unitary checks and link them to a given host (e.g. each VPN definition in AWS VPN, each network interface on a router...).

There's no choice here; you should stick with the guidelines described here after if you want your code to be fully compliant with our modules.

### 12.1 Hosts

The discovery plugin can be a specific script or a particular execution mode enabled with an option. In centreon-plugins, we do it through dedicated `discovery*.pm` modes.

This execution mode is limited to a query toward a cloud provider, an application, or whatever contains a list of assets. The expected output must hold some keys:

* `end_time`: the unix timestamp when the execution stops
* `start_time`: the unix timestamp when the execution starts
* `duration`: the duration in seconds (`end_time - start_time`)
* `discovered_items`: the number of discovered items 
* `results`: an array of hashes, each hash being a collection of key/values describing the discovered assets. 

```json title='Sample host discovery output'
{
   "end_time" : 1649431535,
   "start_time" : 1649431534,
   "duration" : 1,
   "discovered_items" : 2,
   "results" : [
         {
         "public_dns_name" : "ec2-name.eu-west-1.compute.amazonaws.com",
         "name" : "prod-ec2",
         "key_name" : "prd-aws-ec2",
         "tags" : [
            {
               "value" : "Licences Management",
               "key" : "Desc"
            },
            {
               "value" : "CI",
               "key" : "Billing"
            }
         ],
         "state" : "running",
         "private_dns_name" : "ip-W-X-Y-Z.eu-west-1.compute.internal",
         "vpc_id" : "vpc-xxxveafea",
         "type" : "ec2",
         "id" : "i-3feafea",
         "private_ip" : "W.X.Y.Z",
         "instance_type" : "t2.medium"
      },
      {
         "public_dns_name" : "other-ec2-name.eu-west-1.compute.amazonaws.com",
         "name" : "prod-other-ec2",
         "key_name" : "prd-aws-ec2",
         "tags" : [
            {
               "value" : "Licences Management",
               "key" : "Desc"
            },
            {
               "value" : "CI",
               "key" : "Billing"
            }
         ],
         "state" : "running",
         "private_dns_name" : "ip-A-B-C-D.eu-west-1.compute.internal",
         "vpc_id" : "vpc-xxxveafea",
         "type" : "ec2",
         "id" : "i-3gfbgfb",
         "private_ip" : "A.B.C.D",
         "instance_type" : "t2.medium"
      }
   ]
}
```

You can use more advanced structures for values in the result sets, it can be: 

* an array of hashes:

```json title='Nmap discovery - Tags'
"services" : [
  {
    "name" : "ssh",
    "port" : "22/tcp"
  },
  {
    "port" : "80/tcp",
    "name" : "http"
  }
]
```

* a flat array: 

```json title='VMWare discovery - IP vMotion'
"ip_vmotion" : [
  "10.10.5.21",
  "10.30.5.21"
],
```

Using these structures is convenient when you need to group object properties behind a single key. 

On the users' side, it allows using these values to filter in or out some of the results or make a better choice 
about the host template for a given discovered host.

### 12.2 Services

Service discovery relies on XML to return information that will be parsed and used by the UI module to 
create new services efficiently.

As for hosts, it can be an option at runtime, or an execution mode. In centreon-plugins, we choose to have dedicated
`list<objectname>.pm` modes. 

All `list<objectname>.pm` modes contain two options that will return properties and results that will be used in the 
discovery rules definitions. 

The first service discovery option is `--disco-format`, it enables the plugin to return the supported keys in the rule: 

```bash title='Linux Network int --disco-format output' 
-bash-4.2$ /usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin=os::linux::snmp::plugin --mode=list-interfaces --hostname=127.0.0.1 --disco-format
<?xml version="1.0" encoding="utf-8"?>
<data>
  <element>name</element>
  <element>total</element>
  <element>status</element>
  <element>interfaceid</element>
  <element>type</element>
</data>
```

The output above shows that the discovery of network interfaces on Linux will return those properties:

- `name`: the name of the interface
- `total`: the maximum bandwidth supported
- `status`: the configuration status of the interface (convenient to exclude administratively down interfaces)
- `interfaceid`: the id
- `type`: interface type (like ethernet, fiber, loopback, etc.)

Executing exactly the same command, substituting `--disco-format` with `--disco-show` will output the discovered interfaces:

```bash title='Linux Network int --disco-show output'
/usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin=os::linux::snmp::plugin --mode=list-interfaces --hostname=127.0.0.1 --disco-show
<?xml version="1.0" encoding="utf-8"?>
<data>
  <label status="up" name="lo" type="softwareLoopback" total="10" interfaceid="1"/>
  <label status="up" name="ens5" type="ethernetCsmacd" total="" interfaceid="2"/>
</data>
```

The result contains one line per interface and each line contains each set of properties as a `key="value"` pair. Note that even if
no data is obtained for a given key, it still has to be displayed (e.g `total=""`).

[Table of contents](#table_of_contents)

<div id='performances'/>

## 13. Performances

A monitoring plugin has to do one thing and do it right - it's important to code your plugin with the idea to make
it as efficient as possible. Keep in mind that your Plugin might run every minute, against a large
number of devices, so a minor optimization can result in important benefits at scale.

Also think about the 'thing' you're monitoring, it's important to always try to reduce the overhead of a check
from the monitored object point of view.

### 13.1 Execution time

The most basic way to bench a plugin performance is its execution time. Use the
`time` command utility to run your check and measure over several runs how it behaves.

### 13.2 Cache

In some cases, it can be interesting to cache some information.

Caching in a local file might save some calls against an API, for example do not authenticate at every check.
When possible, use the token obtained at the first check and stored in the cache file to only call the
authentication endpoint when it's absolutely necessary.

More generally, when an identifier, name or anything that would never change across different executions requires a
request against the third-party system, cache it to optimize single-check processing time.

### 13.3 Algorithm

Optimizing the number of requests against a third-party system can also lie in the check algorithm. Prefer scraping
the maximum of data in one check and then filter the results programmatically instead of issuing multiple very specific
requests that would result in longer execution time and greater load on the target system.

### 13.4 Timeout

A Plugin must always include a timeout to avoid never ending checks that might overload your monitoring
system when something is broken and that, for any reason, the plugin cannot obtain the information.

[Table of contents](#table_of_contents)

<div id='security'/>

## 14. Security

### 14.1 System commands

If the plugin requires to execute a command at the operating system level, and users can modify the command name or
its parameters, make sure that nobody can leverage your plugin's capabilities to break the underlying
system or access sensitive information.

#### 14.2 Dependencies

There is no need to re-invent the wheel: standard centreon-plugins dependencies provide you with the most common
external libraries that might be required to write a new plugin.

Don't overuse large libraries that might end being unsupported or where some governance modification might lead to
security problems.

[Table of contents](#table_of_contents)

<div id='help_doc'/>

## 15. Help and documentation

For each plugin, the minimum documentation is the help, you have to explain to users what the plugin
is doing and how they can use the built-in options to achieve their own alerting scenario.

You can look at how we handle help at mode level with the centreon-plugins framework [here](develop-with-centreon-plugins.md).

[Table of contents](#table_of_contents)
