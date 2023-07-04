# Plugins / Connectors documentation

<div id='table_of_content_1'/>

*******
Table of contents (1)
1. [Plugins introduction](#introduction)
2. [PLugins development](#plugin_development)
3. [Plugins guidelines and good practices](#guidelines)
4. [List of shared libraries in centreon directory](#librairies)
*******

<div id='introduction'/>

## I. Plugins introduction

<div id='table_of_content_2'/>

*******
Table of contents (2)
1. [Overview](#overview)
2. [Directories layout](#architecture_layout)
3. [Code Style Guidelines](#code-style-guidelines)
*******

[Table of content (1)](#table_of_content_1)

<div id='overview'/>

### 1. Overview

[Table of content (2)](#table_of_content_2)

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

[Table of content (1)](#table_of_content_1)

<div id='architecture_layout'/>

### 2. Directories layout

#### 2.1 Plugins directories layout

[Table of content (2)](#table_of_content_2)

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

#### 2.2 Single plugin directory layout

[Table of content (2)](#table_of_content_2)

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

#### 2.3 Shared directories

[Table of content (2)](#table_of_content_2)

Some specific directories are not related to a domain (os, cloud...) and are 
used across all plugins.

##### 2.3.1 The centreon directory

The centreon directory is specific, it contains:

* **Project libraries/packages**. This is all the code that will help you to 
develop faster by avoiding coding protocol-related things (SNMP, HTTPx, SSH...) 
or common things like options or cache management from scratch. You can read the 
perl modules if you're an experienced developer but there is very little 
chance that you would have to modify anything in it.
* **Common files shared by multiple plugins**. This is to avoid duplicating 
code across the directory tree and ease the maintenance of the project.

An more detailed desception of this libraries is availible [here](#librairies)

##### 2.3.2 The snmp_standard/mode directory

The snmp_standard/mode exists since the beginning when SNMP monitoring was much 
more used than it is today. All the modes it contains use standard OIDs, which 
means that many plugins are relying on these when the manufacturer supports 
standard MIBs on their devices.

[Table of content (1)](#table_of_content_1)

<div id='code-style-guidelines'/>

### 3. Code Style Guidelines

[Table of content (2)](#table_of_content_2)

**Introduction**

Perl code from Pull-request must conform to the following style guidelines. If you find any code which doesn't conform, please fix it.

#### 3.1 Indentation

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

#### 3.2 Comments

There should always be at least 1 space between the # character and the beginning of the comment.  This makes it a little easier to read multi-line comments:

```perl
    # Good comment
    #Wrong comment
```

#### 3.3 Subroutine & Variable Names

Whenever possible, use underscore to seperator words and don't use uppercase characters:

```perl
    sub get_logs {}
    my $start_time;
```
Keys of hash table should be used alphanumeric and underscore characters only (and no quote!):

```perl
    $dogs->{meapolitan_mastiff} = 10;
```

#### 3.4 Curly Brackets, Parenthesis

There should be a space between every control/loop keyword and the opening parenthesis:

```perl
    if ($i == 1) {
        ...
    }
    while ($i == 2) {
        ...
    }
```

#### 3.5 If/Else Statements

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
[Table of content (1)](#table_of_content_1)

<div id='plugin_development'/>

## II. Plugins development

All files showed in this section can be found on the centreon-plugins GitHub in 
the [tutorial](https://github.com/centreon/centreon-plugins/tree/develop/src/contrib/tutorial) **contrib** 
section.

> You have to move the contents of `contrib/tutorial/apps/` to `apps/` if you want to run it for testing purposes.
>
> `cp -R src/contrib/tutorial/apps/* src/apps/`

<div id='table_of_content_3'/>

*******
Table of content (3)
1. [Set up your environment](#set_up_tuto)
2. [Create directory for the new plugin](#make_dir_tuto)
3. [Create the plugin.pm file](#create_plugin_tuto)
4. [Understand the data](#understand_data_tuto)
5. [Input](#input_tuto)
6. [API]
7. [SNMP]
8. [Other example]
9. [Service discovery]
10. [Host discovery]
11. [Commit and push](#commit)
*******

<div id='set_up_tuto'/>

### 1.Set up your environment

[Table of content (3)](#table_of_content_3)

To use the centreon-plugins framework, you'll need the following: 

- A Linux operating system, ideally Debian 11 or RHEL/RHEL-like >= 8
- The [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) command line utility
- A [GitHub](https://github.com/) account.

#### Enable our standard repositories

##### Debian

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
##### RHEL 8 and alike
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

<div id='make_dir_tuto'/>

### 2.Create directories for a new plugin

[Table of content (3)](#table_of_content_3)

Create directories and files required for your **plugin** and **modes**. 

Go to your centreon-plugins local git and create the appropriate directories and files:

```shell
# path to the main directory and the subdirectory containing modes
mkdir -p src/apps/myawesomeapp/api/mode/
# path to the main plugin file
touch src/apps/myawesomeapp/api/plugin.pm
# path to the specific mode(s) file(s)
touch src/apps/myawesomeapp/api/mode/appsmetrics.pm
```

<div id='create_plugin_tuto'/>

### plugin.pm

[Table of content (3)](#table_of_content_3)

This file must contain : 
* license / copyright
* package name
* libraries
* new constructor

First this file contains the Copyright section. At the end of it, you can add your author informations like this :

```
# ...
# Authors : <your name> <<your email>>
```
Then the **package** name : path to your package. '::' instead of '/', and no .pm at the end.

```perl
package path::to::plugin;
```
Used libraries (strict and warnings are mandatory). 

```perl
use strict;
use warnings;
```
Centreon library :

```perl
use base qw(**centreon_library**);
```
There are five kinds of centreon libraries access here :
* centreon::plugins::script_simple : Previously the general use case if no custom is needed, more explainations [here](#custom_mode_tuto) in this section.
* centreon::plugins::script_custom : Need custom directory - More explainations [here](#custom_mode_tuto) in this section.
* centreon::plugins::script_snmp : If SNMP protocol is needed for this plugin
* centreon::plugins::script_sql : If DB acess is needed for this plugin
* centreon::plugins::script_wsman : Concern Windows specific protocols

The plugin need a new constructor to instantiate the object:

```perl

sub new {
      my ($class, %options) = @_;
      my $self = $class->SUPER::new(package => __PACKAGE__, %options);
      bless $self, $class;

      ...

      return $self;
}
```
Plugin version declaration is in the new constructor:

```perl
$self->{version} = '0.1';
```
Several modes can be declared in the new constructor:

```perl
%{$self->{modes}} = (
                      'mode1'    => '<plugin_path>::mode::mode1',
                      'mode2'    => '<plugin_path>::mode::mode2',
                      ...
                      );
```
Then, the module is declared:

```perl
1;
```
A description of the plugin is needed to generate the documentation:

```perl
__END__

=head1 PLUGIN DESCRIPTION

<Add a plugin description here>.

=cut
```
> **TIP** : You can copy-paste an other plugin.pm and adapt some lines (package, arguments...).
 The plugin has ".pm" extension because it's a Perl module. So don't forget to add 1; at the end of the file.

<div id='architecture_mode'/>

### 3.Create the plugin.pm file

[Table of content (3)](#table_of_content_3)

The `plugin.pm` is the first thing to create, it contains:

- A set of instructions to load required libraries and compilation options
- A list of all **mode(s)** and path(s) to their associated files/perl packages
- A description that will display when you list all plugins or display this plugin's help.

Here is the commented version of the plugin.pm file:

```perl title="my-awesome-app plugin.pm file"
[.. license and copyright things ..]

# Name of your perl package
package apps::myawesomeapp::api::plugin;

# Always use strict and warnings, will guarantee that your code is clean and help debugging it
use strict;
use warnings;
# Load the base for your plugin, here we don't do SNMP, SQL or have a custom directory, so we use the _simple base
use base qw(centreon::plugins::script_simple);

# Global sub to create and return the perl object. Don't bother understand what each instruction is doing. 
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    # A version, we don't really use it but could help if your want to version your code
    $self->{version} = '0.1';
    # Important part! 
    #    On the left, the name of the mode as users will use it in their command line
    #    On the right, the path to the file (note that .pm is not present at the end)
    $self->{modes} = {
        'app-metrics' => 'apps::myawesomeapp::api::mode::appmetrics'
    };

    return $self;
}

# Declare this file as a perl module/package
1;

# Beginning of the documenation/help. `__END__` Specify to the interpreter that instructions below don't need to be compiled
# =head1 [..] Specify the section level and the label when using the plugin with --help
# Check my-awesome [..] Quick overview of wath the plugin is doing
# =cut Close the head1 section

__END__

=head1 PLUGIN DESCRIPTION

Check my-awesome-app health and metrics through its custom API

=cut
```

Your first dummy plugin is working, congrats!

Run this command:

`perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --list-mode`

It already outputs a lot of things. Ellipsized lines are basically all standard capabilities
inherited from the **script_custom** base.

You probably already recognized things you've previsously defined in your **plugin.pm** module.

```perl

Plugin Description:
    Check my-awesome-app health and metrics through its custom API

Global Options:
    --mode  Choose a mode.
[..]
    --version
            Display plugin version.
[..]

Modes Available:
   app-metrics
```


<div id='create_mode_tuto'/>

### 4.Understand the data

[Table of content (3)](#table_of_content_3)

Understanding the data is very important as it will drive the way you will design
the **mode** internals. This is the **first thing to do**, no matter what protocol you
are using.

There are several important properties for a piece of data:

- Type of the data to process: string, int... There is no limitation in the kind of data you can process
- Dimensions of the data, is it **global** or linked to an **instance**?
- Data layout, in other words anticipate the kind of **data structure** to manipulate.

In our example, the most common things are present. We can summarize it like that:

- the `health` node is **global** data and is a string. Structure is a simple *key/value* pair
- the `db_queries` node is a collection of **global** integer values about the database. Structure is a hash containing multiple key/value pairs
- the `connections` node contains integer values (`122`, `92`) referring to specific **instances** (`my-awesome-frontend`, `my-awesome-db`). The structure is an array of hashes
- `errors` is the same as `connections` except the data itself tracks errors instead of connections.

Understanding this will be important to code it correctly.

<div id='input_tuto'/>

### 5.Input

[Table of content (3)](#table_of_content_3)

**Context: simple JSON health API**

In this tutorial, we will create a very simple probe checking an application's health
displayed in JSON through a simple API.

You can mockup an API with the free [mocky](https://designer.mocky.io/) tool.
We created one for this tutorial, test it with `curl https://run.mocky.io/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656`

It returns the following output: 

```json title="my-awesome-app health JSON" 
{
    "health": "yellow",
    "db_queries":{
         "select": 1230,
         "update": 640,
         "delete": 44
    },
    "connections":[
      {
        "component": "my-awesome-frontend",
        "value": 122
      },
      {
        "component": "my-awesome-db",
        "value": 92
      }
    ],
    "errors":[
      {
        "component": "my-awesome-frontend",
        "value": 32
      },
      {
        "component": "my-awesome-db",
        "value": 27
      }
    ]
}
```

### 6.API

###  Mode.pm file

[Table of content (2)](#table_of_content_2)

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

> **TIP** : You can have more informations about options format here: http://perldoc.perl.org/Getopt/Long.html

The mode can have a **check_options** method to validate options:

```perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    ...
  }

```
For example, Warning and Critical thresholds can be validate in 
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

Previously went the *run* method, where were perform measurement, check 
thresholds, display output and format performance datas.

Since this method had been split in at least two methods :
* **set_counters** : describe data structure and their properties
  (like  thresholds and how they will be displayed to the users). This 
  method is split in twofunctions

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

<div id='understand_data_tuto'/>

### Create the appmetrics.pm file

[Table of content (4)](#table_of_content_4)

The `appmetrics.pm` file will contain your code, in other words, all the instructions to:

- Declare options for the mode
- Connect to **run.mocky.io** over HTTPS
- Get the JSON from the **/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656** endpoint
- Extract information and format it to be compliant with Centreon.

Let's build it iteratively.

> Important note: function (sub) names must not be modified. For example, you cannot 
> choose to rename `check_options` to `option_check`. 

#### Common declarations and subs

```perl
# Path to your package. '::' instead of '/', and no .pm at the end.
package apps::myawesomeapp::api::mode::appmetrics;

# Don't forget these ;)
use strict;
use warnings;
# We want to connect to an HTTP server, let's use the common module
use centreon::plugins::http;
# Use the counter module. It will save you a lot of work and will manage a lot of things for you.
# Consider this as mandatory when writing a new mode. 
use base qw(centreon::plugins::templates::counter);
# Import some functions that will make your life easier
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
# We will have to process some JSON, no need to reinvent the wheel, load the lib you installed in a previous section
use JSON::XS;
```

Add a `new` function (sub) to initialize the mode: 

```perl
sub new {
    my ($class, %options) = @_;
    # All options/properties of this mode, always add the force_new_perfdata => 1 to enable new metric/performance data naming.
    # It also where you can specify that the plugin uses a cache file for example
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    # This is where you can specify options/arguments your plugin supports.
    # All options here stick to what the centreon::plugins::http module needs to establish a connection
    # You don't have to specify all options from the http module, only the one that the user may want to tweak for its needs
    $options{options}->add_options(arguments => {
        # One the left it's the option name that will be used in the command line. The ':s' at the end is to 
        # define that this options takes a value.  
        # On the right, it's the code name for this option, optionnaly you can define a default value so the user 
        # doesn't have to set it
         'hostname:s'           => { name => 'hostname' },
         'proto:s'              => { name => 'proto', default => 'https' },
         'port:s'               => { name => 'port', default => 443 },
         'timeout:s'            => { name => 'timeout' },
        # These options are here to defined conditions about which status the plugin will return regarding HTTP response code
         'unknown-status:s'     => { name => 'unknown_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
         'warning-status:s'     => { name => 'warning_status' },
         'critical-status:s'    => { name => 'critical_status', default => '' }
    });

    # This is to create a local copy of a centreon::plugins::http that we will manipulate
    # %options basically overwrite default http value with key/value pairs from options above to instantiate the http module
    # Ref https://github.com/centreon/centreon-plugins/blob/520a1f8c10cd434c6dedd1e342285eecff8b9d1b/centreon/plugins/http.pm#L59
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}
```

Add a `check_options` function. This sub will execute right after `new` and allow you to check that the user passed
 mandatory parameter(s) and in some case check that the format is correct. 

```perl
sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # Check if the user provided a value for --hostname option. If not, display a message and exit
    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option');
        $self->{output}->option_exit();
    }
    # Set parameters for http module, note that the $self->{option_results} is a hash containing 
    # all your options key/value pairs.
    $self->{http}->set_options(%{$self->{option_results}});
}

1;
```

Nice work, you now have a mode that can be executed without errors!

Run this command `perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics`, which
outputs this message:

`UNKNOWN: Please set hostname option`

Now let's do some monitoring thanks to centreon-plugins.

#### Declare your counters

This part essentially maps the data you want to get from the API with the internal
counter mode structure.

Remember how we categorized the data in a previous [section](#understand-the-data).

The `$self->{maps_counters_type}` data structure describes these data while the `$self->{maps_counters}->{global}` one defines
their properties like thresholds and how they will be displayed to the users.

```perl
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # health and queries are global metric, they don't refer to a specific instance. 
        # In other words, you cannot get several values for health or queries
        # That's why the type is 0.
        { name => 'health', type => 0, cb_prefix_output => 'prefix_health_output' },
        { name => 'queries', type => 0, cb_prefix_output => 'prefix_queries_output' },
        # app_metrics groups connections and errors and each will receive value for both instances (my-awesome-frontend and my-awesome-db)
        # the type => 1 explicits that
        # as above, you can define a callback (cb) function to manage the output prefix. This function is called 
        # each time a value is passed to the counter and can be shared across multiple counters.
        { name => 'app_metrics', type => 1, cb_prefix_output => 'prefix_app_output' }
    ];

    $self->{maps_counters}->{health} = [
        # This counter is specific because it deals with a string value
        {
            label => 'health',
            # All properties below (before et) are related to the catalog_status_ng catalog function imported at the top of our mode
            type => 2,
            # These properties allow you to define default thresholds for each status but not mandatory.
            warning_default => '%{health} =~ /yellow/', 
            critical_default => '%{health} =~ /red/', 
            # To simplify, manage things related to how get value in the counter, what to display and specific threshold 
            # check because of the type of the data (string)
            set => {
                key_values => [ { name => 'health' } ],
                output_template => 'status: %s',
                # Force ignoring perfdata as the collected data is a string
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    $self->{maps_counters}->{queries} = [
        # The label defines options name, a --warning-select and --critical-select will be added to the mode
        # The nlabel is the name of your performance data / metric that will show up in your graph
        { 
            label => 'select', 
            nlabel => 'myawesomeapp.db.queries.select.count', 
            set => {
            # Key value name is the name we will use to pass the data to this counter. You can have several ones.
                key_values => [ { name => 'select' } ],
                # Output template describe how the value will display
                output_template => 'select: %s',
                # Perfdata array allow you to define relevant metrics properties (min, max) and its sprintf template format
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'update', nlabel => 'myawesomeapp.db.queries.update.count', set => {
                key_values => [ { name => 'update' } ],
                output_template => 'update: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'delete', nlabel => 'myawesomeapp.db.queries.delete.count', set => {
                key_values => [ { name => 'delete' } ],
                output_template => 'delete: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
    $self->{maps_counters}->{app_metrics} = [
        # The app_metrics has two different labels, connection and errors.
        { label => 'connections', nlabel => 'myawesomeapp.connections.count', set => {
                # pay attention the extra display key_value. It will receive the instance value. (my-awesome-db, my-awesome-frontend).
                # the display key_value isn't mandatory but we show it here for education purpose
                key_values => [ { name => 'connections' }, { name => 'display' } ],
                output_template => 'connections: %s',
                perfdatas => [
                    # we add the label_extra_instance option to have one perfdata per instance
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'errors', nlabel => 'myawesomeapp.errors.count', set => {
                key_values => [ { name => 'errors' }, { name => 'display' } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

# This should always be present at the end of the script.
1;
```

> Remember to always move the final `1;` instruction at the end of the script when you add new lines during this tutorial.

The mode compiles. Run the command
supplying a value to the `--hostname` option to see what it displays:

```shell
perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --hostname=fakehost
OK: status : skipped (no value(s)) - select : skipped (no value(s)), update : skipped (no value(s)), delete : skipped (no value(s))
```

You can see some of your counters with the `skipped (no value(s))`, it's normal, this is because we
just created the counters definition and structure but didn't push any values into it.

#### Create prefix callback functions

These functions are not mandatory but help to make the output more readable for a human. We will create
it now but as you have noticed the mode compiles so you can choose to keep those for the polishing moment.

During counters definitions, we associated a callback function to each of them:

- `cb_prefix_output => 'prefix_health_output'`
- `cb_prefix_output => 'prefix_queries_output'`
- `cb_prefix_output => 'prefix_app_output'`

Define those functions by adding it to our `appmetrics.pm` file. They are self-explanatory.

```perl
sub prefix_health_output {
    my ($self, %options) = @_;

    return 'My-awesome-app:';
}

sub prefix_queries_output {
    my ($self, %options) = @_;

    return 'Queries:';
}

sub prefix_app_output {
    my ($self, %options) = @_;

    # This notation allows you to return the value of the instance (the display key_value)
    # to bring some context to the output.
    return "'" . $options{instance_value}->{display} . "' ";
}

1;
```

Execute your command and check that the output matches the one below: 

```shell
perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --hostname=fakehost
OK: My-awesome-app: status : skipped (no value(s)) - Queries: select : skipped (no value(s)), update : skipped (no value(s)), delete : skipped (no value(s))
``` 

The output is easier to read and separators are visible between global counters.

#### Get raw data from API and understand the data structure

It's the moment to write the main sub (`manage_selection`) - the most complex, but also the one that
will transform your mode to something useful and alive.

Think about the logic, what we have to do is:

- Connect to **run.mocky.io** over HTTPS
- Query a specific path corresponding to our API
- Store and process the result
- Spread this result across counters definitions

Start by writing the code to connect to **run.mocky.io**. It is where the centreon-plugins
framework delivers its power.

> All print instructions are available as commented code in the GitHub tutorial resources.

Write the request and add a print to display the received data:

```perl
sub manage_selection {
    my ($self, %options) = @_;
    # We have already loaded all things required for the http module
    # Use the request method from the module to run the GET request against the path
    my ($content) = $self->{http}->request(url_path => '/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656');
    print $content . "\n";
}

1;
```

Run this command `perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --hostname=run.mocky.io`. 

The output should be:

```perl title="Basic raw content print"
{
    "health": "yellow",
    "db_queries":{
         "select": 1230,
         "update": 640,
         "delete": 44
    },
    "connections":[
      {
        "component": "my-awesome-frontend",
        "value": 122
      },
      {
        "component": "my-awesome-db",
        "value": 92
      }
    ],
    "errors":[
      {
        "component": "my-awesome-frontend",
        "value": 32
      },
      {
        "component": "my-awesome-db",
        "value": 27
      }
    ]
}
OK: My-awesome-app: status : skipped (no value(s)) - Queries: select : skipped (no value(s)), update : skipped (no value(s)), delete : skipped (no value(s))
```

Add an `eval` structure to transform `$content` into a data structure that can be easily manipulated with perl. Let's
introduce the standard `Data::Dumper` library that can help understanding your data structures.

We load the Data::Dumper library and use one of its methods to print the JSON. A second line is here to print
a simple message and get you familiar with how to access data within perl data structures.

```perl
sub manage_selection {
    my ($self, %options) = @_;
    # We have already loaded all things required for the http module
    # Use the request method from the imported module to run the GET request against the URL path of our API
    my ($content) = $self->{http}->request(url_path => '/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656');
    
    # Declare a scalar deserialize the JSON content string into a perl data structure
    my $decoded_content;
    eval {
        $decoded_content = JSON::XS->new->decode($content);
    };
    # Catch the error that may arise in case the data received is not JSON
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result");
        $self->{output}->option_exit();    
    }
    use Data::Dumper; 
    print Dumper($decoded_content);
    print "My App health is '" . $decoded_content->{health} . "'\n";
}

1;
```

Run the command `perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --hostname=run.mocky.io`
again and see how it changed.

You now have your JSON deserialized into a perl `$VAR1` which represents your `$decoded_content` structure.

You can also note the result of the latest print and how we accessed the `yellow` value.

```shell tile="Perl data structure from JSON"
$VAR1 = {
          'connections' => [
                             {
                               'component' => 'my-awesome-frontend',
                               'value' => 122
                             },
                             {
                               'value' => 92,
                               'component' => 'my-awesome-db'
                             }
                           ],
          'health' => 'yellow',
          'errors' => [
                        {
                          'value' => 32,
                          'component' => 'my-awesome-frontend'
                        },
                        {
                          'value' => 27,
                          'component' => 'my-awesome-db'
                        }
                      ],
          'db_queries' => {
                            'select' => 1230,
                            'update' => 640,
                            'delete' => 44
                          }
        };
My App health is 'yellow'
```

#### Push data to global counters (type => 0)

Now that we know our data structure and how to access the values, we have to assign this
value to the counters we initially defined. Pay attention to the comments above
the `$self->{health}` and `$self->{db_queries}` assignations.

```perl title="Global counters (type => 0)"
sub manage_selection {
    my ($self, %options) = @_;
    # We have already loaded all things required for the http module
    # Use the request method from the imported module to run the GET request against the URL path of our API
    my ($content) = $self->{http}->request(url_path => '/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656');
    # Uncomment the line below when you reached this part of the tutorial.
    # print $content;

    # Declare a scalar deserialize the JSON content string into a perl data structure
    my $decoded_content;
    eval {
        $decoded_content = JSON::XS->new->decode($content);
    };
    # Catch the error that may arise in case the data received is not JSON
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result");
        $self->{output}->option_exit();    
    }
    # Uncomment the lines below when you reached this part of the tutorial.
    # use Data::Dumper; 
    # print Dumper($decoded_content);
    # print "My App health is '" . $decoded_content->{health} . "'\n";

    # Here is where the counter magic happens.
    
    # $self->{health} is your counter definition (see $self->{maps_counters}->{<name>})
    # Here, we map the obtained string $decoded_content->{health} with the health key_value in the counter.
    $self->{health} = { 
        health => $decoded_content->{health}
    };

    # $self->{queries} is your counter definition (see $self->{maps_counters}->{<name>}) 
    # Here, we map the obtained values from the db_queries nodes with the key_value defined in the counter.
    $self->{queries} = {
        select => $decoded_content->{db_queries}->{select},
        update => $decoded_content->{db_queries}->{update},
        delete => $decoded_content->{db_queries}->{delete}
    };

}

1;
```

Let's run our command again: no more `skipped (no value(s))` message. You even get a
WARNING state because of the `yellow` app state.

```shell
perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --hostname=run.mocky.io
WARNING: My-awesome-app status: yellow | 'myawesomeapp.db.queries.select.count'=1230;;;0; 'myawesomeapp.db.queries.update.count'=640;;;0; 'myawesomeapp.db.queries.delete.count'=44;;;0;
```

Performance data confirm that values for database queries are correctly set as well.

This is how the counters mode template work (`use base qw(centreon::plugins::templates::counter);`), the only thing you have
to do is getting the data from the thing you have to monitor and push it to a counter definition.

Behind the scenes, it manages a lot of things for you:

- Options: `--warning-health --warning-select --warning-update --warning-delete and --critical-` have automatically been defined
- Performance data: thanks to `nlabel` and values from `perfdatas:[]` array in your counters
- Display: It writes the status and substitutes values with the one assigned to the counter

Now, you probably understand better why the preparation work about understanding collected data and the counter definition part is essential: simply because it's the bigger part of the job.

#### Push data to counters having an instance (type => 1)

Now let's deal with counters with instances. That means that the same counters will
receive multiple data, each of these data refering to a specific dimension.

They require to be manipulated in a slightly different way as we will have to specify the
name we want to associate with the data.

First, we have to loop over both `connections` and `errors` arrays to access the app name and
measured value and then spread it within counters.

```perl title="Counters with instances (type 1)"
sub manage_selection {
    my ($self, %options) = @_;
    # We have already loaded all things required for the http module
    # Use the request method from the imported module to run the GET request against the URL path of our API
    my ($content) = $self->{http}->request(url_path => '/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656');
    # Uncomment the line below when you reached this part of the tutorial.
    # print $content;

    # Declare a scalar deserialize the JSON content string into a perl data structure
    my $decoded_content;
    eval {
        $decoded_content = JSON::XS->new->decode($content);
    };
    # Catch the error that may arise in case the data received is not JSON
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result");
        $self->{output}->option_exit();    
    }
    # Uncomment the lines below when you reached this part of the tutorial.
    # use Data::Dumper; 
    # print Dumper($decoded_content);
    # print "My App health is '" . $decoded_content->{health} . "'\n";

    # Here is where the counter magic happens.
    
    # $self->{health} is your counter definition (see $self->{maps_counters}->{<name>})
    # Here, we map the obtained string $decoded_content->{health} with the health key_value in the counter.
    $self->{health} = { 
        health => $decoded_content->{health}
    };

    # $self->{queries} is your counter definition (see $self->{maps_counters}->{<name>}) 
    # Here, we map the obtained values from the db_queries nodes with the key_value defined in the counter.
    $self->{queries} = {
        select => $decoded_content->{db_queries}->{select},
        update => $decoded_content->{db_queries}->{update},
        delete => $decoded_content->{db_queries}->{delete}
    };

    # Initialize an empty app_metrics counter.
    $self->{app_metrics} = {};
    # Loop in the connections array of hashes
    foreach my $entry (@{ $decoded_content->{connections} }) {
        # Same logic than type => 0 counters but an extra key $entry->{component} to associate the value 
        # with a specific instance
        $self->{app_metrics}->{ $entry->{component} }->{display} = $entry->{component};
        $self->{app_metrics}->{ $entry->{component} }->{connections} = $entry->{value};
    };

    # Exactly the same thing with errors
    foreach my $entry (@{ $decoded_content->{errors} }) {
        # Don't need to redefine the display key, just assign a value to the error key_value while 
        # keeping the $entry->{component} key to associate the value with the good instance
        $self->{app_metrics}->{ $entry->{component} }->{errors} = $entry->{value};
    };

}

1;
```

Your `app-metrics` mode is (almost) complete. Once again, the counters template managed a lot
behind the scenes.

Execute this command to see how it evolved since the last execution. We modify the command with some
additional parameters:

- `--warning-health='%{health} eq "care"'` to avoid getting a WARNING, put any value that will not match yellow. Providing it
as a parameter will automatically override the hardcoded default code value
- `--verbose` will display the long output and the details for each `type => 1` counters

```shell
perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --hostname=run.mocky.io --warning-health='%{health} eq "care"' --verbose
```

Here is the expected output: 

```shell
OK: My-awesome-app status: yellow - Queries: select: 1230, update: 640, delete: 44 | 'myawesomeapp.db.queries.select.count'=1230;;;0; 'myawesomeapp.db.queries.update.count'=640;;;0; 'myawesomeapp.db.queries.delete.count'=44;;;0; 'my-awesome-db#myawesomeapp.connections.count'=92;;;0; 'my-awesome-db#myawesomeapp.errors.count'=27;;;0; 'my-awesome-frontend#myawesomeapp.connections.count'=122;;;0; 'my-awesome-frontend#myawesomeapp.errors.count'=32;;;0;
'my-awesome-db' connections: 92, errors: 27
'my-awesome-frontend' connections: 122, errors: 32
```

You now get metrics displayed for both components `'my-awesome-db'` and `'my-awesome-frontend'` and also performance data
for your graphs. Note how the counter template automatically added the instance dimension on the left of the `nlabel` defined 
for each counters: `**my-awesome-frontend#**myawesomeapp.errors.count'=32;;;0;`

#### Help section and assistant to build your centreon objects

Last but not least, you need to write a help section to explain users what your mode is
doing and what options they can use.

The centreon-plugins framework has a built-in assistant to help you with the list of counters
and options.

Run this command to obtain a summary that will simplify the work of creating Centreon commands and write
the mode's help:

```shell
perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --hostname='anyvalue' --list-coun
ters --verbose
```

Get information from its output (shown below) to start building your mode's help:

```shell
counter list: select update delete health connections errors
configuration:  --warning-select='$_SERVICEWARNINGSELECT$' --critical-select='$_SERVICECRITICALSELECT$' --warning-update='$_SERVICEWARNINGUPDATE$' --critical-update='$_SERVICECRITICALUPDATE$' --warning-delete='$_SERVICEWARNINGDELETE$' --critical-delete='$_SERVICECRITICALDELETE$' --warning-health='$_SERVICEWARNINGHEALTH$' --critical-health='$_SERVICECRITICALHEALTH$' --warning-connections='$_SERVICEWARNINGCONNECTIONS$' --critical-connections='$_SERVICECRITICALCONNECTIONS$' --warning-errors='$_SERVICEWARNINGERRORS$' --critical-errors='$_SERVICECRITICALERRORS$'
```

Here is how you can write the help, note that this time you will add the content after the `1;` and add the same
`__END__` instruction like you did in the `plugin.pm` file. 


```perl title="Help section"
__END__

=head1 MODE

Check my-awesome-app metrics exposed through its API

=over 8

=item B<--warning/critical-health>

Warning and critical threshold for application health string. 

Defaults values are: --warning-health='%{health} eq "yellow"' --critical-health='%{health} eq "red"'

=item B<--warning/critical-select>

Warning and critical threshold for select queries

=item B<--warning/critical-update>

Warning and critical threshold for update queries

=item B<--warning/critical-delete>

Warning and critical threshold for delete queries

=item B<--warning/critical-connections>

Warning and critical threshold for connections

=item B<--warning/critical-errors>

Warning and critical threshold for errors

=back
```

You're done! You can enjoy a complete plugin and mode and the help now displays in a specific 
mode section: 


```shell
perl centreon_plugins.pl --plugin=apps::myawesomeapp::api::plugin --mode=app-metrics --help
[..
   All global options from the centreon-plugins framework that your plugin benefits from
..]
Mode:
    Check my-awesome-app metrics exposed through its API

    --warning/critical-health
            Warning and critical threshold for application health string.

            Defaults are: --warning-health='%{health} eq "yellow"' &
            --critical-health='%{health} eq "red"'

    --warning/critical-select
            Warning and critical threshold for select queries

    --warning/critical-update
            Warning and critical threshold for update queries

    --warning/critical-delete
            Warning and critical threshold for delete queries

    --warning/critical-connections
            Warning and critical threshold for connections

    --warning/critical-errors
            Warning and critical threshold for errors
```

<div id='custom_mode_tuto'/>

### Convert in custom mode

[Table of content (3)](#table_of_content_3)

Custom mode is a well established type of plugin. Then it can be usefull to understand the way to build and use it.
Custom is a mode thinking for when you may have different way to collect plugin input. More broadly, build plugins using custom mode afford flexibility if later you have to add a new way to give input in a plugin. This is the main reason why most of latest plugins are in custom mode baseline.

Most of the time the way to collect input use api and this is the most common custom mode you will find in plugins.
There are also cli file for command line or tcp, etc.

In our example case of tutoral it's an api case. 

#### 7.1 Create custom file 

First we need to create the custom file : api.pm

```shell
mkdir -p src/apps/myawesomeapp/api/custom/
touch src/apps/myawesomeapp/api/custom/api.pm
```
#### 7.2 Change in pulgin.pm

First we need to change plugins script libraririe :
```perl
centreon::plugins::script_simple
```
replace by 
```perl
centreon::plugins::script_custom
```
Then in new constructor a new line calling for the custom is needed
```perl
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        'app-metrics' => 'apps::myawesomeapp::api::mode::appmetrics'
    };

    $self->{custom_modes}->{api} = 'apps::myawesomeapp::api::custom::api';
    return $self;
}
```
#### 7.3 Change in mode.pm

Custom mode allows to change the way to obtain input, thus all that concern input and the way to process it is push to the custom file. The mode file will contain all needed functions for processing input to give the output needed.

First the new constructor will change :
```perl
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    return $self;
}
```

The check_options function is push into the custom file because it was usefull for the input formating

The manage_selection function is update to remove all that concern the input management.

```perl
sub manage_selection {
    my ($self, %options) = @_;
    
    #This line replace the input section previously available here
    my $results = $options{custom}->request_api();
    
    # $self->{health} is your counter definition (see $self->{maps_counters}->{<name>})
    # Here, we map the obtained string $decoded_content->{health} with the health key_value in the counter.
    $self->{health} = {
        health => $results->{health}
    };
    
    # $self->{queries} is your counter definition (see $self->{maps_counters}->{<name>})
    # Here, we map the obtained values from the db_queries nodes with the key_value defined in the counter.
    $self->{queries} = {
        select => $results->{db_queries}->{select},
        update => $results->{db_queries}->{update},
        delete => $results->{db_queries}->{delete}
    };
    
    # Initialize an empty app_metrics counter.
    $self->{app_metrics} = {};
    # Loop in the connections array of hashes
    foreach my $entry (@{ $results->{connections} }) {
        # Same logic than type => 0 counters but an extra key $entry->{component} to associate the value
        # with a specific instance
        $self->{app_metrics}->{ $entry->{component} }->{display} = $entry->{component};
        $self->{app_metrics}->{ $entry->{component} }->{connections} = $entry->{value}
    };
    
     # Exactly the same thing with errors
    foreach my $entry (@{ $results->{errors} }) {
        # Don't need to redefine the display key, just assign a value to the error key_value while
        # keeping the $entry->{component} key to associate the value with the good instance
        $self->{app_metrics}->{ $entry->{component} }->{errors} = $entry->{value};
    };
}
```

#### 7.4 New file : api.pm

As explained in the previous section, the custom file will contain all needed functions about input and the way to process it.

This new file needs to contains the packages and libraries declarations :
```perl
package apps::myawesomeapp::api::custom::api;

use strict;
use warnings;

use centreon::plugins::http;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use JSON::XS;
```

It also contains the following functions :
* new constructor : construct the object in the same way than in mode file previously
* set_options
* set_defaults
* check_options
* settings
* request_api

##### new constructor

```perl
sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    # Check if an output option is available
    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    # Check if options are avaliable
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        # Adding options legacy from appsmetrics.pm in single mode
        $options{options}->add_options(arguments => {
            'hostname:s'           => { name => 'hostname' },
            'proto:s'              => { name => 'proto', default => 'https' },
            'port:s'               => { name => 'port', default => 443 },
            'timeout:s'            => { name => 'timeout' },
            'unknown-status:s'     => { name => 'unknown_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-status:s'     => { name => 'warning_status' },
            'critical-status:s'    => { name => 'critical_status', default => '' }
        });
    }
    # Adding Help structure to the object
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);
    # Adding output structure to the object
    $self->{output} = $options{output};
    # Command line legacy from appsmetrics.pm in single mode
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}
```
##### set_options

This function overwrite the set_options function in http module

```perl
sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}
```
##### set_defaults

This function is empty and is call remain unclear

```perl
sub set_defaults {}
```
##### check_options



```perl
sub check_options {
    my ($self, %options) = @_;

    # Check if options are propely define
    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{unknown_status} = (defined($self->{option_results}->{unknown_status})) ? $self->{option_results}->{unknown_status} : '';
    $self->{warning_status} = (defined($self->{option_results}->{warning_status})) ? $self->{option_results}->{warning_status} : '';
    $self->{critical_status} = (defined($self->{option_results}->{critical_status})) ? $self->{option_results}->{critical_status} : '';

    # Check if the user provided a value for --hostname option. If not, display a message and exit
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option');
        $self->{output}->option_exit();
    }

    return 0;
}
```
##### settings

This function allows initialize api object options structure and feed it calling set_options

```perl
sub settings {
    my ($self, %options) = @_;

    # Initialize options structure
    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{unknown_status} = $self->{unknown_status};
    $self->{option_results}->{warning_status} = $self->{warning_status};
    $self->{option_results}->{critical_status} = $self->{critical_status};

    # Feed options structure using set_options 
    $self->{http}->set_options(%{$self->{option_results}});
}
```
##### request_api

```perl
sub request_api {
    my ($self, %options) = @_;
    
    # Define APi options needed for request
    $self->settings();

    my ($content) = $self->{http}->request(url_path => '/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656');

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result");
        $self->{output}->option_exit();
    }

    return $decoded;
}
```

<div id='tutoriel_2'/>

### 7.SNMP

Tutorial : How to create a plugin - Using SNMP

**Description**

This example explains how to check a single SNMP value on a PfSense firewall (memory dropped packets).
We use cache file because it's a SNMP counter. So we need to get the value between 2 checks.
We get the value and compare it to warning and critical thresholds.

#### 1. Plugin file

First, create the plugin directory and the plugin file:

```
  $ mkdir -p apps/pfsense/snmp
  $ touch apps/pfsense/snmp/plugin.pm
```
> **TIP** : PfSense is a firewall application and we check it using SNMP protocol

Then, edit **plugin.pm** and add the following lines:

```perl
  #
  # Copyright 2023 Centreon (http://www.centreon.com/)
  #
  # Centreon is a full-fledged industry-strength solution that meets
  # the needs in IT infrastructure and application monitoring for
  # service performance.
  #
  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at
  #
  #     http://www.apache.org/licenses/LICENSE-2.0
  #
  # Unless required by applicable law or agreed to in writing, software
  # distributed under the License is distributed on an "AS IS" BASIS,
  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  # See the License for the specific language governing permissions and
  # limitations under the License.
  #

  # Path to the plugin
  package apps::pfsense::snmp::plugin;

  # Needed libraries
  use strict;
  use warnings;
  # Use this library to check using SNMP protocol
  use base qw(centreon::plugins::script_snmp);
```
> **TIP** : Don't forget to edit 'Authors' line.

Add **new** method to instantiate the plugin:

```perl
  sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    # Plugin version
    $self->{version} = '0.1';

    # Modes association
    %{$self->{modes}} = (
                         # Mode name => path to the mode
                         'memory-dropped-packets'   => 'apps::pfsense::snmp::mode::memorydroppedpackets',
                         );

    return $self;
  }
```
Declare this plugin as a perl module:

```perl
  1;
```
Add a description to the plugin:

```perl
  __END__

  =head1 PLUGIN DESCRIPTION

  Check pfSense in SNMP.

  =cut
```
> **TIP** : This description is printed with '--help' option.

#### 2.Mode file

Then, create the mode directory and the mode file:

```shell
  $ mkdir apps/pfsense/snmp/mode
  $ touch apps/pfsense/snmp/mode/memorydroppedpackets.pm
```
Edit **memorydroppedpackets.pm** and add the following lines:

```perl
  #
  # Copyright 2023 Centreon (http://www.centreon.com/)
  #
  # Centreon is a full-fledged industry-strength solution that meets
  # the needs in IT infrastructure and application monitoring for
  # service performance.
  #
  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at
  #
  #     http://www.apache.org/licenses/LICENSE-2.0
  #
  # Unless required by applicable law or agreed to in writing, software
  # distributed under the License is distributed on an "AS IS" BASIS,
  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  # See the License for the specific language governing permissions and
  # limitations under the License.
  #

  # Path to the plugin
  package apps::pfsense::snmp::mode::memorydroppedpackets;

  # Needed library for modes
  use base qw(centreon::plugins::mode);

  # Needed libraries
  use strict;
  use warnings;

  # Custom library
  use POSIX;

  # Needed library to use cache file
  use centreon::plugins::statefile;
```
Add **new** method to instantiate the mode:

```perl
  sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    # Mode version
    $self->{version} = '1.0';

    # Declare options
    $options{options}->add_options(arguments =>
                                {
                                  # option name        => variable name
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                });

    # Instantiate cache file
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
  }
```
> **TIP** : A default value can be added to options.
  Example : "warning:s" => { name => 'warning', default => '80'},

Add **check_options** method to validate options:

```perl
  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # Validate threshold options with threshold_validate method
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

    # Validate cache file options using check_options method of statefile library
    $self->{statefile_value}->check_options(%options);
  }
```
Add **run** method to execute mode:

```perl
  sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object

    # Get SNMP options
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    # SNMP oid to request
    my $oid_pfsenseMemDropPackets = '.1.3.6.1.4.1.12325.1.200.1.2.6.0';
    my ($result, $value);

    # Get SNMP value for oid previsouly defined
    $result = $self->{snmp}->get_leef(oids => [ $oid_pfsenseMemDropPackets ], nothing_quit => 1);
    # $result is a hash table where keys are oids
    $value = $result->{$oid_pfsenseMemDropPackets};

    # Read the cache file
    $self->{statefile_value}->read(statefile => 'pfsense_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    # Get cache file values
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $old_memDropPackets = $self->{statefile_value}->get(name => 'memDropPackets');

    # Create a hash table with new values that will be write to cache file
    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $new_datas->{memDropPackets} = $value;

    # Write new values to cache file
    $self->{statefile_value}->write(data => $new_datas);

    # If cache file didn't have any values, create it and wait another check to calculate value
    if (!defined($old_timestamp) || !defined($old_memDropPackets)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Fix when PfSense reboot (snmp counters initialize to 0)
    $old_memDropPackets = 0 if ($old_memDropPackets > $new_datas->{memDropPackets});

    # Calculate time between 2 checks
    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0);

    # Calculate value per second
    my $memDropPacketsPerSec = ($new_datas->{memDropPackets} - $old_memDropPackets) / $delta_time;

    # Calculate exit code by comparing value to thresholds
    # Exit code can be : 'OK', 'WARNING', 'CRITICAL', 'UNKNOWN'
    my $exit_code = $self->{perfdata}->threshold_check(value => $memDropPacketsPerSec,
                                                       threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    # Add a performance data
    $self->{output}->perfdata_add(label => 'dropped_packets_Per_Sec',
                                  value => sprintf("%.2f", $memDropPacketsPerSec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    # Add output
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Dropped packets due to memory limitations : %.2f /s",
                                    $memDropPacketsPerSec));

    # Display output
    $self->{output}->display();
    $self->{output}->exit();
  }
```
Declare this plugin as a perl module:

```perl
  1;
```
Add a description of the mode options:

```perl
  __END__

  =head1 MODE

  Check number of packets per second dropped due to memory limitations.

  =over 8

  =item B<--warning>

  Threshold warning for dropped packets in packets per second.

  =item B<--critical>

  Threshold critical for dropped packets in packets per second.

  =back

  =cut
```

#### 3.Command line

This is an example of command line:

```
  $ perl centreon_plugins.pl --plugin apps::pfsense::snmp::plugin --mode memory-dropped-packets --hostname 192.168.0.1 --snmp-community 'public' --snmp-version '2c' --warning '1' --critical '2'
```
Output may display:

```
  OK: Dropped packets due to memory limitations : 0.00 /s | dropped_packets_Per_Sec=0.00;0;;1;2
```

<div id='example'/>

### 8. Other examples 

[Table of content (1)](#table_of_content_1)

---

#### 1. Example 1

We want to develop the following SNMP plugin:

* measure the current sessions and current SSL sessions usages.

```perl
  package my::module::name;
  
  use base qw(centreon::plugins::templates::counter);
  
  use strict;
  use warnings;
  
  sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'sessions', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'Current sessions : %s',
                perfdatas => [
                    { label => 'sessions', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'sessions-ssl', set => {
                key_values => [ { name => 'sessions_ssl' } ],
                output_template => 'Current ssl sessions : %s',
                perfdatas => [
                    { label => 'sessions_ssl', template => '%s', min => 0 },
                ],
            }
        },
    ];
  }
  
  sub manage_selection {
    my ($self, %options) = @_;

    # OIDs are fake. Only for the example.
    my ($oid_sessions, $oid_sessions_ssl) = ('.1.2.3.4.0', '.1.2.3.5.0');
    
    my $result = $options{snmp}->get_leef(
      oids => [ $oid_sessions, $oid_sessions_ssl ],
      nothing_quit => 1
    );
    $self->{global} = {
      sessions => $result->{$oid_sessions},
      sessions_ssl => $result->{$oid_sessions_ssl}
    };
  }
```
Output may display:

```
  OK: Current sessions : 24 - Current ssl sessions : 150 | sessions=24;;;0; sessions_ssl=150;;;0;
```
As you can see, we create two arrays of hash tables in **set_counters** method. We use arrays to order the output.

* **maps_counters_type**: global configuration. Attributes list:

  * *name*: the name is really important. It will be used in hash **map_counters** and also in **manage_selection** as you can see.
  * *type*: 0 or 1. With 0 value, the output will be written in the short output. With the value 1, it depends if we have one or multiple instances.
  * *message_multiple*: only useful with *type* 1 value. The message will be displayed in short ouput if we have multiple instances selected.
  * *message_separator*: the string displayed between counters (Default: ', ').
  * *cb_prefix_output*, *cb_suffix_output*: name of a method (in a string) to callback. Methods will return a string to be displayed before or after **all** counters.
  * *cb_init*: name of a method (in a string) to callback. Method will return 0 or 1. With 1 value, counters are not checked.

* **maps_counters**: complex structure to configure counters. Attributes list:

  * *label*: name used for threshold options.
  * *type*: depend of data dimensions
    * 0 : global
    * 1 : instance
    * 2 : group
    * 3 : multiple
  * *threshold*: if we set the value to 0. There is no threshold check options (can be used if you want to set and check option yourself).
  * *set*: hash table:
  
    * *keys_values*: array of hashes. Set values used for the counter. Order is important (by default, the first value is used to check). 

      * *name*: attribute name. Need to match with attributes in **manage_selection** method!
      * *diff*: if we set the value to 1, we'll have the difference between two checks (need a statefile!).
      * *per_second*: if we set the value to 1, the *diff* values will be calculated per seconds (need a statefile!). No need to add diff attribute.
    
    * *output_template*: string to display. '%s' will be replaced by the first value of *keys_values*.
    * *output_use*: which value to be used in *output_template* (If not set, we use the first value of *keys_values*).
    * *output_change_bytes*: if we set the value to 1 or 2, we can use a second '%s' in *output_template* to display the unit. 1 = divide by 1024 (Bytes), 2 = divide by 1000 (bits).
    * *perfdata*: array of hashes. To configure perfdatas
    
      * *label*: name displayed.
      * *value*: value to used. It's the name from *keys_values*.
      * *template*: value format (could be for example: '%.3f').
      * *unit*: unit displayed.
      * *min*, *max*: min and max displayed. You can use a value from *keys_values*.
      * *label_extra_instance*: if we set the value to 1, perhaps we'll have a suffix concat with *label*.
      * *instance_use*: which value from *keys_values* to be used. To be used if *label_extra_instance* is 1.

#### 2. Example 2

We want to add the current number of sessions by virtual servers.

```perl
  package my::module::name;
  
  use base qw(centreon::plugins::templates::counter);
  
  use strict;
  use warnings;
  
  sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'vs', type => 1, cb_prefix_output => 'prefix_vs_output', message_multiple => 'All Virtual servers are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-sessions', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'current sessions : %s',
                perfdatas => [
                    { label => 'total_sessions', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-sessions-ssl', set => {
                key_values => [ { name => 'sessions_ssl' } ],
                output_template => 'current ssl sessions : %s',
                perfdatas => [
                    { label => 'total_sessions_ssl', template => '%s', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{vs} = [
        { label => 'sessions', set => {
                key_values => [ { name => 'sessions' }, { name => 'display' } ],
                output_template => 'current sessions : %s',
                perfdatas => [
                    { label => 'sessions', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'sessions-ssl', set => {
                key_values => [ { name => 'sessions_ssl' }, { name => 'display' } ],
                output_template => 'current ssl sessions : %s',
                perfdatas => [
                    { label => 'sessions_ssl', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
  }
  
  sub prefix_vs_output {
    my ($self, %options) = @_;
    
    return "Virtual server '" . $options{instance_value}->{display} . "' ";
  }
  
  sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total ";
  }
  
  sub manage_selection {
    my ($self, %options) = @_;

    # OIDs are fake. Only for the example.
    my ($oid_sessions, $oid_sessions_ssl) = ('.1.2.3.4.0', '.1.2.3.5.0');
    
    my $result = $options{snmp}->get_leef(oids => [ $oid_sessions, $oid_sessions_ssl ],
                                          nothing_quit => 1);
    $self->{global} = { sessions => $result->{$oid_sessions},
                        sessions_ssl => $result->{$oid_sessions_ssl}
                      };
    my $oid_table_vs = '.1.2.3.10';
    my $mapping = {
        vsName        => { oid => '.1.2.3.10.1' },
        vsSessions    => { oid => '.1.2.3.10.2' },
        vsSessionsSsl => { oid => '.1.2.3.10.3' },
    };
    
    $self->{vs} = {};
    $result = $options{snmp}->get_table(oid => $oid_table_vs,
                                        nothing_quit => 1);
    foreach my $oid (keys %{$result->{ $oid_table_vs }}) {
        next if ($oid !~ /^$mapping->{vsName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $data = $options{snmp}->map_instance(mapping => $mapping, results => $result->{$oid_table_vs}, instance => $instance);
        
        $self->{vs}->{$instance} = { display => $data->{vsName}, 
                                     sessions => $data->{vsSessions}, sessions_ssl => $data->{vsSessionsSsl}};
    }
  }
```
If we have at least 2 virtual servers:

```
  OK: Total current sessions : 24, current ssl sessions : 150 - All Virtual servers are ok | total_sessions=24;;;0; total_sessions_ssl=150;;;0; sessions_foo1=11;;;0; sessions_ssl_foo1=70;;;0; sessions_foo2=13;;;0; sessions_ssl_foo2=80;;;0;
  Virtual server 'foo1' current sessions : 11, current ssl sessions : 70
  Virtual server 'foo2' current sessions : 13, current ssl sessions : 80
```

#### 3. Example 3

The model can also be used to check strings (not only counters). So we want to check the status of a virtualserver.

```perl
  package my::module::name;
  
  use base qw(centreon::plugins::templates::counter);
  
  use strict;
  use warnings;
  
  sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vs', type => 1, cb_prefix_output => 'prefix_vs_output', message_multiple => 'All Virtual server status are ok' }
    ];    
    $self->{maps_counters}->{vs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output')
            }
        }
    ];
  }
  
  sub custom_threshold_output {
    my ($self, %options) = @_; 
    my $status = 'ok';
    
    if ($self->{result_values}->{status} =~ /problem/) {
        $status = 'critical';
    }
    return $status;
  }
  
  sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("status is '%s'", $self->{result_values}->{status});
    return $msg;
  }
  
  sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
  }
  
  sub prefix_vs_output {
    my ($self, %options) = @_;
    
    return "Virtual server '" . $options{instance_value}->{display} . "' ";
  }
  
  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

  }
  
  sub manage_selection {
    my ($self, %options) = @_;

    my $oid_table_vs = '.1.2.3.10';
    my $mapping = {
        vsName        => { oid => '.1.2.3.10.1' },
        vsStatus      => { oid => '.1.2.3.10.4' },
    };
    
    $self->{vs} = {};
    my $result = $options{snmp}->get_table(oid => $oid_table_vs,
                                        nothing_quit => 1);
    foreach my $oid (keys %{$result->{ $oid_table_vs }}) {
        next if ($oid !~ /^$mapping->{vsName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $data = $options{snmp}->map_instance(mapping => $mapping, results => $result->{$oid_table_vs}, instance => $instance);
        
        $self->{vs}->{$instance} = { display => $data->{vsName}, 
                                     status => $data->{vsStatus} };
    }
  }
```
The following example show 4 new attributes:

* *closure_custom_calc*: should be used to do more complex calculation.
* *closure_custom_output*: should be used to have a more complex output (An example: want to display the total, free and used value at the same time).
* *closure_custom_perfdata*: should be used to manage yourself the perfdata.
* *closure_custom_threshold_check*: should be used to manage yourself the threshold check.

[Table of content (1)](#table_of_content_1)

<div id='guidelines'/>

<div id='commit'/>

### 9. Service discovery

### 10. Host discovery

### 11. Commit and push

[Table of content (3)](#table_of_content_3)

Before committing a plugin, you need to create an **enhancement ticket** on the 
centreon-plugins forge : http://forge.centreon.com/projects/centreon-plugins

Once plugin and modes are developed, you can commit (commit messages in english)
and push your work:

```shell
  git add path/to/plugin
  git commit -m "Add new plugin for XXXX refs #<ticked_id>"
  git push
```

## III. Plugins guidelines

<div id='table_of_content_4'/>

*******
Table of contents (4)
 1. [Outputs](#outputs)
 2. [Options](#options)
 3. [Discovery](#discovery)
 4. [Performances](#performances)
 5. [Security](#security)
 6. [Help and documentation](#help_doc)
*******

A large part of these guidelines come from the [Monitoring Plugins project](https://www.monitoring-plugins.org/doc/guidelines.html). Indeed, some of these are outdated, not relevant anymore or related to a language you don’t use. We will focus on those that we consider as the most important, but this is still a great piece of content you should read.

<div id='outputs'/>

### 1. Outputs

[Table of content (4)](#table_of_content_4)

#### 1.1 Formatting

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

#### 1.2 Short output

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

##### Centreon Plugin example

The output when checking several storage partitions on a server, when everything is OK:

`OK: All storages are ok |`

The output of the same plugin, when one of the storage partition space usages triggers a WARNING threshold:

`WARNING: Storage '/var/lib' Usage Total: 9.30 GB Used: 956.44 MB (10.04%) Free: 8.37 GB (89.96%) |`

#### 1.3 Performance data and metrics

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

##### Centreon Plugin Performance Data / Metrics examples

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

#### 1.4 Extended output

The extended output's primary purpose is to display each bit of collected information separately on a single line. It will only print if the user adds a `--verbose` flag to its command.

Overall, you should use it to:

* add extra context (numbered instance, serial number) about a checked component
* print items the check excludes because plugin options have filtered them out
* organize how the information is displayed using groups that follow the logic of the check.

##### Centreon Plugin example

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
<div id='options'/>

### 2. Options

[Table of content (4)](#table_of_content_4)

Option management is a central piece of a successful plugin. You should:

* Carefully name your options to make them **self-explanatory**
* For a given option, **only one format** is possible (either a flag or a value, but not both)
* Always **check** for values supplied by the user and print a **clear message** when they do not fit with plugin requirements
* Set default option value when relevant

<div id='discovery'/>

###  3. Discovery

[Table of content (4)](#table_of_content_4)

This section describes how you should format your data to comply with the requirements of Centreon Discovery UI modules.

In a nutshell:

* [host discovery](/docs/monitoring/discovery/hosts-discovery) allows you to return a JSON list the autodiscovery module will understand so the user can choose to automatically or manually add to its monitoring configuration. Optionally, it can use one of the discovered items properties to make some decisions (filter in or out, create or assign a specific host group, etc.)
* [service discovery](/docs/monitoring/discovery/services-discovery) allows you to return XML data to help users configure unitary checks and link them to a given host (e.g. each VPN definition in AWS VPN, each network interface on a router...).

There's no choice here; you should stick with the guidelines described hereafter if you want your code to be fully compliant with our modules.

#### 3.1 Hosts

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

#### 3.2 Services

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

<div id='performances'/>

### 4. Performances

[Table of content (4)](#table_of_content_4)

A monitoring plugin has to do one thing and do it right - it's important to code your plugin with the idea to make
it as efficient as possible. Keep in mind that your Plugin might run every minute, against a large
number of devices, so a minor optimization can result in important benefits at scale.

Also think about the 'thing' you're monitoring, it's important to always try to reduce the overhead of a check
from the monitored object point of view.

#### 4.1 Execution time

The most basic way to bench a plugin performance is its execution time. Use the
`time` command utility to run your check and measure over several runs how it behaves.

#### 4.2 Cache

In some cases, it can be interesting to cache some information.

Caching in a local file might save some calls against an API, for example do not authenticate at every check.
When possible, use the token obtained at the first check and stored in the cache file to only call the
authentication endpoint when it's absolutely necessary.

More generally, when an identifier, name or anything that would never change across different executions requires a
request against the third-party system, cache it to optimize single-check processing time.

#### 4.3 Algorithm

Optimizing the number of requests against a third-party system can also lie in the check algorithm. Prefer scraping
the maximum of data in one check and then filter the results programmatically instead of issuing multiple very specific
requests that would result in longer execution time and greater load on the target system.

#### 4.3 Timeout

A Plugin must always include a timeout to avoid never ending checks that might overload your monitoring
system when something is broken and that, for any reason, the plugin cannot obtain the information.

<div id='security'/>

### 5. Security

[Table of content (4)](#table_of_content_4)

#### 5.1 System commands

If the plugin requires to execute a command at the operating system level, and users can modify the command name or
its parameters, make sure that nobody can leverage your plugin's capabilities to break the underlying
system or access sensitive information.

#### 5.2 Dependencies

There is no need to re-invent the wheel: standard centreon-plugins dependencies provide you with the most common
external libraries that might be required to write a new plugin.

Don't overuse large libraries that might end being unsupported or where some governance modification might lead to
security problems.

<div id='help_doc'/>

### 6. Help and documentation

[Table of content (5)](#table_of_content_4)

For each plugin, the minimum documentation is the help, you have to explain to users what the plugin
is doing and how they can use the built-in options to achieve their own alerting scenario.

You can look at how we handle help at mode level with the centreon-plugins framework [here](develop-with-centreon-plugins.md).

[Table of content (1)](#table_of_content_1)


<div id='librairies'/>

## IV. List of shared libraries in centreon directory

This chapter describes Centreon libraries which you can use in your development.

<div id='table_of_content_5'/>

*******
Table of content (5)
1. [Output](#lib_output)
2. [Perfdata](#lib_perfdata)
3. [SNMP](#lib_snmp)
4. [Misc](#lib_misc)
5. [Statefile](#lib_statefile)
6. [HTTP](#lib_http)
7. [DBI](#lib_dbi)
8. [Model Classes Usage](#model_class_usage)
*******

[Table of content (1)](#table_of_content_1)

<div id='lib_output'/>

### 1. Output

[Table of content (5)](#table_of_content_5)

This library allows you to build output of your plugin.

--------------
#### 1.1 output_add
--------------

**Description**

Add string to output (print it with display method). If status is different than 'ok', output associated with 'ok' status is not printed

**Parameters**

| Parameter | Type   | Default | Description                                 |
|-----------|--------|---------|---------------------------------------------|
| severity  | String | OK      | Status of the output.                       |
| separator | String | \-      | Separator between status and output string. |
| short_msg | String |         | Short output (first line).                  |
| long_msg  | String |         | Long output (used with --verbose option).   |

**Example**

This is an example of how to manage output:

```perl

$self->{output}->output_add(severity  => 'OK',
                            short_msg => 'All is ok');
$self->{output}->output_add(severity  => 'Critical',
                            short_msg => 'There is a critical problem');
$self->{output}->output_add(long_msg  => 'Port 1 is disconnected');

$self->{output}->display();
```
Output displays :

```
CRITICAL - There is a critical problem
Port 1 is disconnected
```
--------------
#### 1.2 perfdata_add
--------------

**Description**

Add performance data to output (print it with **display** method).
Performance data are displayed after '|'.

**Parameters**

| Parameter | Type   | Default | Description                            |
|-----------|--------|---------|----------------------------------------|
| label     | String |         | Label of the performance data.         |
| value     | Int    |         | Value of the performance data.         |
| unit      | String |         | Unit of the performance data.          |
| warning   | String |         | Warning threshold.                     |
| critical  | String |         | Critical threshold.                    |
| min       | Int    |         | Minimum value of the performance data. |
| max       | Int    |         | Maximum value of the performance data. |

**Example**

This is an example of how to add performance data:

```perl

$self->{output}->output_add(severity  => 'OK',
                            short_msg => 'Memory is ok');
$self->{output}->perfdata_add(label    => 'memory_used',
                              value    => 30000000,
                              unit     => 'B',
                              warning  => '80000000',
                              critical => '90000000',
                              min      => 0,
                              max      => 100000000);

$self->{output}->display();
```
Output displays :

```
OK - Memory is ok | 'memory_used'=30000000B;80000000;90000000;0;100000000
```

<div id='lib_perfdata'/>

### 2. Perfdata

[Table of content (5)](#table_of_content_5)

This library allows you to manage performance data.

--------------
#### 2.1 get_perfdata_for_output
--------------

**Description**
Manage thresholds of performance data for output.

**Parameters**

| Parameter | Type         | Default | Description                                               |
|-----------|--------------|---------|-----------------------------------------------------------|
| **label** | String       |         | Threshold label.                                          |
| total     | Int          |         | Percent threshold to transform in global.                 |
| cast_int  | Int (0 or 1) |         | Cast absolute to int.                                     |
| op        | String       |         | Operator to apply to start/end value (uses with 'value'). |
| value     | Int          |         | Value to apply with 'op' option.                          |

**Example**

This is an example of how to manage performance data for output:

```perl

my $format_warning_perfdata  = $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => 1000000000, cast_int => 1);
my $format_critical_perfdata = $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => 1000000000, cast_int => 1);

$self->{output}->perfdata_add(label    => 'memory_used',
                              value    => 30000000,
                              unit     => 'B',
                              warning  => $format_warning_perfdata,
                              critical => $format_critical_perfdata,
                              min      => 0,
                              max      => 1000000000);

```
**tip**
In this example, instead of print warning and critical thresholds in 'percent', the function calculates and prints these in 'bytes'.

--------------
#### 2.2 threshold_validate
--------------

**Description**

Validate and affect threshold to a label.

**Parameters**

| Parameter | Type   | Default | Description      |
|-----------|--------|---------|------------------|
| label     | String |         | Threshold label. |
| value     | String |         | Threshold value. |

**Example**

This example checks if warning threshold is correct:

```perl

if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
  $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
  $self->{output}->option_exit();
}
```
**tip**
You can see the correct threshold format here: https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT

--------------
#### 2.3 threshold_check
--------------

**Description**


Check performance data value with threshold to determine status.

**Parameters**

| Parameter | Type         | Default | Description                                            |
|-----------|--------------|---------|--------------------------------------------------------|
| value     | Int          |         | Performance data value to compare.                     |
| threshold | String array |         | Threshold label to compare and exit status if reached. |

**Example**

This example checks if performance data reached thresholds:

```perl
$self->{perfdata}->threshold_validate(label => 'warning', value => 80);
$self->{perfdata}->threshold_validate(label => 'critical', value => 90);
my $prct_used = 85;

my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

$self->{output}->output_add(severity  => $exit,
                            short_msg => sprint("Used memory is %i%%", $prct_used));
$self->{output}->display();
```
Output displays :

```
  WARNING - Used memory is 85% |
```
--------------
#### 2.4 change_bytes
--------------

**Description**

Convert bytes to human readable unit.
Return value and unit.

**Parameters**

| Parameter | Type | Default | Description                        |
|-----------|------|---------|------------------------------------|
| value     | Int  |         | Performance data value to convert. |
| network   |      | 1024    | Unit to divide (1000 if defined).  |

**Example**

This example change bytes to human readable unit:

```perl

my ($value, $unit) = $self->{perfdata}->change_bytes(value => 100000);

print $value.' '.$unit."\n";
```
Output displays :

```
  100 KB
```

<div id='lib_snmp'/>

### 3. SNMP

[Table of content (5)](#table_of_content_5)

This library allows you to use SNMP protocol in your plugin.
To use it, add the following line at the beginning of your **plugin.pm**:

```perl

use base qw(centreon::plugins::script_snmp);
```

--------------
#### 3.1 get_leef
--------------

**Description**

Return hash table table of SNMP values for multiple OIDs (do not work with SNMP table).

**Parameters**

**Example**

This is an example of how to get 2 SNMP values:

```perl

my $oid_hrSystemUptime = '.1.3.6.1.2.1.25.1.1.0';
my $oid_sysUpTime = '.1.3.6.1.2.1.1.3.0';

my $result = $self->{snmp}->get_leef(oids => [ $oid_hrSystemUptime, $oid_sysUpTime ], nothing_quit => 1);

print $result->{$oid_hrSystemUptime}."\n";
print $result->{$oid_sysUpTime}."\n";
```
--------------
#### 3.2 load
--------------

**Description**

Load a range of OIDs to use with **get_leef** method.

**Parameters**

| Parameter       | Type         | Default | Description                                                    |
|-----------------|--------------|---------|----------------------------------------------------------------|
| **oids**        | String array |         | Array of OIDs to check.                                        |
| instances       | Int array    |         | Array of OID instances to check.                               |
| instance_regexp | String       |         | Regular expression to get instances from **instances** option. |
| begin           | Int          |         | Instance to begin                                              |
| end             | Int          |         | Instance to end                                                |

**Example**

This is an example of how to get 4 instances of a SNMP table by using **load** method:

```perl
my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

$self->{snmp}->load(oids => [$oid_dskPercentNode], instances => [1,2,3,4]);

my $result = $self->{snmp}->get_leef(nothing_quit => 1);

use Data::Dumper;
print Dumper($result);
```
This is an example of how to get multiple instances dynamically (memory modules of Dell hardware) by using **load** method:

```perl
my $oid_memoryDeviceStatus = '.1.3.6.1.4.1.674.10892.1.1100.50.1.5';
my $oid_memoryDeviceLocationName = '.1.3.6.1.4.1.674.10892.1.1100.50.1.8';
my $oid_memoryDeviceSize = '.1.3.6.1.4.1.674.10892.1.1100.50.1.14';
my $oid_memoryDeviceFailureModes = '.1.3.6.1.4.1.674.10892.1.1100.50.1.20';

my $result = $self->{snmp}->get_table(oid => $oid_memoryDeviceStatus);
$self->{snmp}->load(oids => [$oid_memoryDeviceLocationName, $oid_memoryDeviceSize, $oid_memoryDeviceFailureModes],
                    instances => [keys %$result],
                    instance_regexp => '(\d+\.\d+)$');

my $result2 = $self->{snmp}->get_leef();

use Data::Dumper;
print Dumper($result2);
```
--------------
#### 3.3 get_table
--------------

**Description**

Return hash table of SNMP values for SNMP table.

**Parameters**

| Parameter    | Type         | Default | Description                                             |
|--------------|--------------|---------|---------------------------------------------------------|
| **oid**      | String       |         | OID of the snmp table to check.                         |
| start        | Int          |         | First OID to check.                                     |
| end          | Int          |         | Last OID to check.                                      |
| dont_quit    | Int (0 or 1) | 0       | Don't quit even if an SNMP error occured.               |
| nothing_quit | Int (0 or 1) | 0       | Quit if no value is returned.                           |
| return_type  | Int (0 or 1) | 0       | Return a hash table with one level instead of multiple. |

**Example**

This is an example of how to get a SNMP table:

```perl
my $oid_rcDeviceError            = '.1.3.6.1.4.1.15004.4.2.1';
my $oid_rcDeviceErrWatchdogReset = '.1.3.6.1.4.1.15004.4.2.1.2.0';

my $results = $self->{snmp}->get_table(oid => $oid_rcDeviceError, start => $oid_rcDeviceErrWatchdogReset);

use Data::Dumper;
print Dumper($results);
```
--------------
#### 3.4 get_multiple_table
--------------

**Description**

Return hash table of SNMP values for multiple SNMP tables.

**Parameters**

| Parameter    | Type         | Default | Description                                                |
|--------------|--------------|---------|------------------------------------------------------------|
| oids         | Hash table   | -       | Hash table of OIDs to check (Can be set by 'load' method). |
| -            | -            | -       | Keys can be: "oid", "start", "end".                        |
| dont_quit    | Int (0 or 1) | 0       | Don't quit even if an SNMP error occured.                  |
| nothing_quit | Int (0 or 1) | 0       | Quit if no value is returned.                              |
| return_type  | Int (0 or 1) | 0       | Return a hash table with one level instead of multiple.    |      

**Example**

This is an example of how to get 2 SNMP tables:

```perl
my $oid_sysDescr        = ".1.3.6.1.2.1.1.1";
my $aix_swap_pool       = ".1.3.6.1.4.1.2.6.191.2.4.2.1";

my $results = $self->{snmp}->get_multiple_table(oids => [
                                                      { oid => $aix_swap_pool},
                                                      { oid => $oid_sysDescr },
                                                ]);

use Data::Dumper;
print Dumper($results);
```
--------------
#### 3.5 get_hostname
--------------

**Description**

Get hostname parameter (useful to get hostname in mode).

**Parameters**

None.

**Example**

This is an example of how to get hostname parameter:

```perl
my $hostname = $self->{snmp}->get_hostname();
```
--------------
#### 3.6 get_port
--------------

**Description**


Get port parameter (useful to get port in mode).

**Parameters**

None.

**Example**

This is an example of how to get port parameter:

```perl
my $port = $self->{snmp}->get_port();
```
--------------
#### 3.7 oid_lex_sort
--------------

**Description**

Return sorted OIDs.

**Parameters**

| Parameter | Type         | Default | Description            |
|-----------|--------------|---------|------------------------|
| **-**     | String array |         | Array of OIDs to sort. |

**Example**

This example prints sorted OIDs:

```perl
foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$my_oid}})) {
  print $oid;
}
```

<div id='lib_misc'/>

### 4. Misc

[Table of content (5)](#table_of_content_5)

This library provides a set of miscellaneous methods.
To use it, you can directly use the path of the method:

```perl
centreon::plugins::misc::<my_method>;
```
--------------
#### 4.1 trim
--------------

**Description**

Strip whitespace from the beginning and end of a string.

**Parameters**

| Parameter | Type   | Default | Description      |
|-----------|--------|---------|------------------|
| **-**     | String |         | String to strip. |

**Example**

This is an example of how to use **trim** method:

```perl
my $word = '  Hello world !  ';
my $trim_word =  centreon::plugins::misc::trim($word);

print $word."\n";
print $trim_word."\n";
```
Output displays :

```
Hello world !
```
--------------
#### 4.2 change_seconds
--------------

**Description**

Convert seconds to human readable text.

**Parameters**

| Parameter | Type | Default | Description                   |
|-----------|------|---------|-------------------------------|
| **-**     | Int  |         | Number of seconds to convert. |

**Example**

This is an example of how to use **change_seconds** method:

```perl
my $seconds = 3750;
my $human_readable_time =  centreon::plugins::misc::change_seconds($seconds);

print 'Human readable time : '.$human_readable_time."\n";
```
Output displays :

```
Human readable time : 1h 2m 30s
```
--------------
#### 4.3 backtick
--------------

**Description**

Execute system command.

**Parameters**

| Parameter       | Type         | Default | Description                             |
|-----------------|--------------|---------|-----------------------------------------|
| **command**     | String       |         | Command to execute.                     |
| arguments       | String array |         | Command arguments.                      |
| timeout         | Int          | 30      | Command timeout.                        |
| wait_exit       | Int (0 or 1) | 0       | Command process ignore SIGCHLD signals. |
| redirect_stderr | Int (0 or 1) | 0       | Print errors in output.                 |

**Example**

This is an example of how to use **backtick** method:

```perl
my ($error, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                    command => 'ls /home',
                                    timeout => 5,
                                    wait_exit => 1
                                    );

print $stdout."\n";
```
Output displays files in '/home' directory.

--------------
#### 4.4 execute
--------------

**Description**

Execute command remotely.

**Parameters**

| Parameter       | Type   | Default | Description                                                     |
|-----------------|--------|---------|-----------------------------------------------------------------|
| **output**      | Object |         | Plugin output ($self->{output}).                                |
| **options**     | Object |         | Plugin options ($self->{option_results}) to get remote options. |
| sudo            | String |         | Use sudo command.                                               |
| **command**     | String |         | Command to execute.                                             |
| command_path    | String |         | Command path.                                                   |
| command_options | String |         | Command arguments.                                              |

**Example**

This is an example of how to use **execute** method.
We suppose ``--remote`` option is enabled:

```perl
my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                              options => $self->{option_results},
                                              sudo => 1,
                                              command => 'ls /home',
                                              command_path => '/bin/',
                                              command_options => '-l');
```
Output displays files in /home using ssh on a remote host.

--------------
#### 4.5 windows_execute
---------------

**Description**

Execute command on Windows.

**Parameters**

| Parameter       | Type   | Default | Description                          |
|-----------------|--------|---------|--------------------------------------|
| **output**      | Object |         | Plugin output ($self->{output}).     |
| **command**     | String |         | Command to execute.                  |
| command_path    | String |         | Command path.                        |
| command_options | String |         | Command arguments.                   |
| timeout         | Int    |         | Command timeout.                     |
| no_quit         | Int    |         | Don't quit even if an error occured. |

**Example**

This is an example of how to use **windows_execute** method.

```perl
my $stdout = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                      timeout => 10,
                                                      command => 'ipconfig',
                                                      command_path => '',
                                                      command_options => '/all');
```
Output displays IP configuration on a Windows host.

<div id='lib_statefile'/>

### 5.Statefile

[Table of content (5)](#table_of_content_5)


This library provides a set of methods to use a cache file.
To use it, add the following line at the beginning of your **mode**:

```perl
use centreon::plugins::statefile;
```

--------------
#### 5.1 read
--------------

**Description**

Read cache file.

**Parameters**

| Parameter         | Type   | Default | Description                  |
|-------------------|--------|---------|------------------------------|
| **statefile**     | String |         | Name of the cache file.      |
| **statefile_dir** | String |         | Directory of the cache file. |
| memcached         | String |         | Memcached server to use.     |

**Example**

This is an example of how to use **read** method:

```perl
$self->{statefile_value} = centreon::plugins::statefile->new(%options);
$self->{statefile_value}->check_options(%options);
$self->{statefile_value}->read(statefile => 'my_cache_file',
                               statefile_dir => '/var/lib/centreon/centplugins'
                              );

use Data::Dumper;
print Dumper($self->{statefile_value});
```
Output displays cache file and its parameters.

--------------
#### 5.2 get
--------------

**Description**

Get data from cache file.

**Parameters**

| Parameter | Type   | Default | Description                  |
|-----------|--------|---------|------------------------------|
| name      | String |         | Get a value from cache file. |

**Example**

This is an example of how to use **get** method:

```perl
$self->{statefile_value} = centreon::plugins::statefile->new(%options);
$self->{statefile_value}->check_options(%options);
$self->{statefile_value}->read(statefile => 'my_cache_file',
                               statefile_dir => '/var/lib/centreon/centplugins'
                              );

my $value = $self->{statefile_value}->get(name => 'property1');
print $value."\n";
```
Output displays value for 'property1' of the cache file.

--------------
#### 5.3 write
--------------

**Description**

Write data to cache file.

**Parameters**

| Parameter | Type   | Default | Description                  |
|-----------|--------|---------|------------------------------|
| data      | String |         | Data to write in cache file. |

**Example**

This is an example of how to use **write** method:

```perl
$self->{statefile_value} = centreon::plugins::statefile->new(%options);
$self->{statefile_value}->check_options(%options);
$self->{statefile_value}->read(statefile => 'my_cache_file',
                               statefile_dir => '/var/lib/centreon/centplugins'
                              );

my $new_datas = {};
$new_datas->{last_timestamp} = time();
$self->{statefile_value}->write(data => $new_datas);
```
Then, you can read the result in '/var/lib/centreon/centplugins/my_cache_file', timestamp is written in it.

<div id='lib_http'/>

### 6. HTTP

[Table of content (5)](#table_of_content_5)

This library provides a set of methodss to use HTTP protocol.
To use it, add the following line at the beginning of your **mode**:

```perl
use centreon::plugins::http;
```

Some options must be set in **plugin.pm**:

| Option       | Type   | Description                                             |
|--------------|--------|---------------------------------------------------------|
| **hostname** | String | IP Addr/FQDN of the webserver host.                     |
| **port**     | String | HTTP port.                                              |
| **proto**    | String | Used protocol ('http' or 'https').                      |
| credentials  |        | Use credentials.                                        |
| ntlm         |        | Use NTLM authentication (if ``--credentials`` is used). |
| username     | String | Username (if ``--credentials`` is used).                |
| password     | String | User password (if ``--credentials`` is used).           |
| proxyurl     | String | Proxy to use.                                           |
| url_path     | String | URL to connect (start to '/').                          |

--------------
#### 6.1 connect
--------------

**Description**

Test a connection to an HTTP url.
Return content of the webpage.

**Parameters**

This method use plugin options previously defined.

**Example**

This is an example of how to use **connect** method.

We suppose these options are defined :
* --hostname = 'google.com'
* --urlpath  = '/'
* --proto    = 'http'
* --port     = 80

```perl
$self->{http} = centreon::plugins::http->new(output => $self->{output}, options => $self->{options});
$self->{http}->set_options(%{$self->{option_results}});
my $webcontent = $self->{http}->request();
print $webcontent;
```
Output displays content of the webpage '\http://google.com/'.

<div id='lib_dbi'/>

### 7. DBI

[Table of content (5)](#table_of_content_5)

This library allows you to connect to databases.
To use it, add the following line at the beginning of your **plugin.pm**:

```perl
use base qw(centreon::plugins::script_sql);
```

--------------
#### 7.1 connect
--------------

**Description**

Connect to databases.

**Parameters**

| Parameter | Type         | Default | Description                        |
|-----------|--------------|---------|------------------------------------|
| dontquit  | Int (0 or 1) | 0       | Don't quit even if errors occured. |

**Example**

This is an example of how to use **connect** method.

The format of the connection string can have the following forms:

```
    DriverName:database_name
    DriverName:database_name@hostname:port
    DriverName:database=database_name;host=hostname;port=port
```
In plugin.pm:

```perl
$self->{sqldefault}->{dbi} = ();
$self->{sqldefault}->{dbi} = { data_source => 'mysql:host=127.0.0.1;port=3306' };
```
In your mode:

```perl
$self->{sql} = $options{sql};
my ($exit, $msg_error) = $self->{sql}->connect(dontquit => 1);
```
Then, you are connected to the MySQL database.

--------------
#### 7.2 query
--------------

**Description**

Send query to database.

**Parameters**

| Parameter | Type   | Default | Description        |
|-----------|--------|---------|--------------------|
| query     | String |         | SQL query to send. |

**Example**

This is an example of how to use **query** method:

```perl
$self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Slow_queries'});
my ($name, $result) = $self->{sql}->fetchrow_array();

print 'Name : '.$name."\n";
print 'Value : '.$value."\n";
```
Output displays count of MySQL slow queries.

--------------
#### 7.3 fetchrow_array
--------------

**Description**

Return Array from sql query.

**Parameters**

None.

**Example**

This is an example of how to use **fetchrow_array** method:

```perl
$self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Uptime'});
my ($dummy, $result) = $self->{sql}->fetchrow_array();

print 'Uptime : '.$result."\n";
```
Output displays MySQL uptime.

--------------
#### 7.4 fetchall_arrayref
--------------

**Description**

Return Array from SQL query.

**Parameters**

None.

**Example**

This is an example of how to use **fetchrow_array** method:

```perl
$self->{sql}->query(query => q{
      SELECT SUM(DECODE(name, 'physical reads', value, 0)),
          SUM(DECODE(name, 'physical reads direct', value, 0)),
          SUM(DECODE(name, 'physical reads direct (lob)', value, 0)),
          SUM(DECODE(name, 'session logical reads', value, 0))
      FROM sys.v_$sysstat
});
my $result = $self->{sql}->fetchall_arrayref();

my $physical_reads = @$result[0]->[0];
my $physical_reads_direct = @$result[0]->[1];
my $physical_reads_direct_lob = @$result[0]->[2];
my $session_logical_reads = @$result[0]->[3];

print $physical_reads."\n";
```
Output displays physical reads on Oracle database.

--------------
#### 7.5 fetchrow_hashref
--------------

**Description**

Return Hash table from SQL query.

**Parameters**

None.

**Example**

This is an example of how to use **fetchrow_hashref** method:

```perl
$self->{sql}->query(query => q{
  SELECT datname FROM pg_database
});

while ((my $row = $self->{sql}->fetchrow_hashref())) {
  print $row->{datname}."\n";
}
```
Output displays Postgres databases.

<div id='model_class_usage'/>

--------------
### 8. Model Classes Usage
--------------
**Introduction**

With the experience of plugin development, we have created two classes:

* centreon::plugins::templates::counter
* centreon::plugins::templates::hardware

It was developed to have a more consistent code and less redundant code. 
According to context, you should use one of two classes for modes. 
Following classes can be used for whatever plugin type (SNMP, Custom, DBI,...).

**Class counter**

*When to use it ?*

If you have some counters (CPU Usage, Memory, Session...), you should use that 
class.
If you have only one global counter to check, it's maybe not useful to use it 
(but only for these case).

*Class methods*

List of methods:

* **new**: class constructor. Overload if you need to add some specific options 
or to use a statefile.
* **check_options**: overload if you need to check your specific options.
* **manage_selection**: overload if *mandatory*. Method to get informations for 
the equipment.
* **set_counters**: overload if **mandatory**. Method to configure counters.

**Class hardware**






TODO





[Table of content (1)](#table_of_content_1)


