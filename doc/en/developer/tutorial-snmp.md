# SNMP plugin tutorial

All files showed in this section can be found on the centreon-plugins GitHub in 
the [tutorial](https://github.com/centreon/centreon-plugins/tree/develop/src/contrib/tutorial) **contrib** 
section.

> You have to move the contents of `contrib/tutorial/apps/` to `apps/` if you want to run it for testing purposes.
>
> `cp -R src/contrib/tutorial/network/* src/network/`

You also need to be able to use linux standard snmpwalk in your development environment.
If you can't, you can use [this snmpwalk](https://github.com/centreon/centreon-plugins/blob/develop/tests/resources/snmp/os_linux_snmp_plugin.snmpwalk) coupled with snmpsim (in Docker for example)

**Description**

This example explains how to check a single SNMP oid value to check system CPUs.

## 1. Understand the data

Understanding the data is very important as it will drive the way you will design
the **mode** internals. This is the **first thing to do**, no matter what protocol you
are using.

There are several important properties for a piece of data:

- Type of the data to process: string, int... There is no limitation in the kind of data you can process
- Dimensions of the data, is it **global** or linked to an **instance**?
- Data layout, in other words anticipate the kind of **data structure** to manipulate.

Here we use a very simple example with only one oid value : `hrProcessorLoad` = `.1.3.6.1.2.1.25.3.3.1.2`
If you use [this snmpwalk](https://github.com/centreon/centreon-plugins/blob/develop/tests/resources/snmp/os_linux_snmp_plugin.snmpwalk) you have this values :
```
.1.3.6.1.2.1.25.3.3.1.2.768 = INTEGER: 6
.1.3.6.1.2.1.25.3.3.1.2.769 = INTEGER: 16
```
- the `cpu` node contains integer values (`6`, `16`) referring to specific **instances** (`768`, `769`). The structure is an array of hashes

## 2. Create directories for a new plugin

Create directories and files required for your **plugin** and **modes**. 

Go to your centreon-plugins local git and create the appropriate directories and files:

```shell
# path to the main directory and the subdirectory containing modes
mkdir -p src/network/mysnmpplugin/snmp/mode
# path to the main plugin file
touch network/mysnmpplugin/snmp/plugin.pm
# path to the specific mode(s) file(s) => for example appsmetrics.pm
touch network/mysnmpplugin/snmp/mode/cpu.pm
```

## 3. Create the plugin file : plugin.pm

Edit **plugin.pm** and add the following lines:

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
  package network::mysnmpplugin::snmp::plugin;

  # Needed libraries
  use strict;
  use warnings;
  # Use this library to check using SNMP protocol
  use base qw(centreon::plugins::script_snmp);
```
> **TIP** : Don't forget to edit 'Authors' line.

Add ```new``` method to instantiate the plugin:

```perl
  sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    # Modes association
    $self->{modes} = {
         # Mode name => path to the mode
        'cpu'   => 'network::mysnmpplugin::snmp::mode::cpu'
    };

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

  Check my-plugin-snmp CPU through SNMP.

  =cut
```
> **TIP** : This description is printed with '--help' option.

To test if this plugin file works you can run this command:

`perl centreon_plugins.pl --plugin=apps::mysnmpplugin:::api::plugin --list-mode`

It already outputs a lot of things. Ellipsized lines are basically all standard capabilities
inherited from the **script_custom** base.

```perl
Plugin Description:
    Check CPU through SNMP.

Global Options:
    --mode  Choose a mode.
[...]
    --version
            Display plugin version.
[...]

Modes Available:
   cpu

```

## 4. Create the mode file : cpu.pm

### 4.1 Common declarations and new constructor

Edit **cpu.pm** and add the following lines:

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
package network::mysnmpplugin::snmp::mode::cpu;

# Consider this as mandatory when writing a new mode. 
use base qw(centreon::plugins::templates::counter);

# Needed libraries
use strict;
use warnings;

```

Add a `new` function (sub) to initialize the mode: 

```perl
sub new {
    my ($class, %options) = @_;
    # All options/properties of this mode, always add the force_new_perfdata => 1 to enable new metric/performance data naming.
    # It also where you can specify that the plugin uses a cache file for example
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    # Declare options
    $options{options}->add_options(arguments => {
        # One the left it's the option name that will be used in the command line. The ':s' at the end is to
        # define that this options takes a value.
        # On the right, it's the code name for this option, optionnaly you can define a default value so the user
        # doesn't have to set it.
        # option name        => variable name
        'filter-id:s' => { name => 'filter_id' }
    });

    return $self;
}
```

### 4.2 Declare your counters

This part essentially maps the data you want to get from the SNMP with the internal
counter mode structure.

Remember how we categorized the data in the previous section understand-the-data.

The `$self->{maps_counters_type}` data structure describes these data while the `$self->{maps_counters}->{global}` one defines
their properties like thresholds and how they will be displayed to the users.

```perl
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # cpu will receive value for both instances (768 and 769) : the type => 1 explicits that
        # You can define a callback (cb) function to manage the output prefix. This function is called 
        # each time a value is passed to the counter and can be shared across multiple counters.
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-usage-prct', nlabel => 'cpu.usage.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'name' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    # we add the label_extra_instance option to have one perfdata per instance
                    { label => 'cpu', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1,  instance_use => 'name' }
                ]
            }
        }
    ];
}
```

### 4.3 Create prefix callback functions

These functions are not mandatory but help to make the output more readable for a human. We will create
it now but as you have noticed the mode compiles so you can choose to keep those for the polishing moment.

During counters definitions, we associated a callback function like this :
- `cb_prefix_output => 'prefix_cpu_output'`

Define those function by adding it to our `cpu.pm` file. It is self-explanatory.

```perl
sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{name} . "' usage: ";
}
```

### 4.4 Get raw data from SNMP and understand the data structure

It's the moment to write the main sub (`manage_selection`) - the most complex, but also the one that
will transform your mode to something useful and alive.

Think about the logic, what we have to do is:

- Query a specific path corresponding to a SNMP oid
- Store and process the result
- Spread this result across counters definitions

```perl
sub manage_selection {
    my ($self, %options) = @_;
    ###################################################
    ##### Load SNMP informations to a result hash #####
    ###################################################

    # Select relevant oids for CPU monitoring
    my $mapping = {
        # hashKey => { oid => 'oid_number_path'}
        hrProcessorID    => { oid => '.1.3.6.1.2.1.25.3.3.1.1' },
        hrProcessorLoad     => { oid => '.1.3.6.1.2.1.25.3.3.1.2' }
        #
    };

    # Point at the begining of the SNMP table
    # Oid to point the table ahead all the oids given in mapping
    my $oid_hrProcessorTable = '.1.3.6.1.2.1.25.3.3.1';

    # Use SNMP Centreon plugins tools to push SNMP result in hash to handle with.
    my $cpu_result = $options{snmp}->get_table(
        oid => $oid_hrProcessorTable,
        nothing_quit => 1
    );

    ###################################################
    ##### SNMP Result table to browse             #####
    ###################################################
    foreach my $oid (keys %{$cpu_result}) {
        next if ($oid !~ /^$mapping->{hrProcessorID}->{oid}\.(.*)$/);

        # Catch table instance if exist :
        # Instance is a number availible for a same oid refering to different target
        my $instance = $1;
        # Uncomment the lines below to see what instance looks like :

        # use Data::Dumper;
        # print Dumper($oid);
        # print Dumper($instance);

        # Data Dumper returns : with oid = hrProcessorID.instance
        # $VAR1 = '.1.3.6.1.2.1.25.3.3.1.1.769';
        # $VAR1 = '769';
        # $VAR1 = '.1.3.6.1.2.1.25.3.3.1.1.768';
        # $VAR1 = '768';

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $cpu_result, instance => $instance);

        # Here is the way to handle with basic name/id filter.
        # This filter is compare with hrProcessorID and in case of no match the oid is skipped
        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $result->{hrProcessorID} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{hrProcessorID} . "': no matching filter.", debug => 1);
            next;
        }

        # If the oid is not skipped above, here is convert the target values in result hash.
        # Here is where the counter magic happens.
        # $self->{cpu} is your counter definition (see $self->{maps_counters}->{<name>})
        # Here, we map the obtained string $result->{hrProcessorLoad} with the cpu_usage key_value in the counter.
        $self->{cpu}->{$instance} = {
            name => $result->{hrProcessorID},
            cpu_usage => $result->{hrProcessorLoad}
        };
    }

    # IMPORTANT !
    # If you use a way to filter the values set in result hash,
    # check if at the end of parsing the result table isn't empty.
    # If it's the case, add a message for user to explain the filter doesn't match.
    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No processor ID matching with filter found.");
        $self->{output}->option_exit();
    }
}
```

Declare this plugin as a perl module:

```perl
  1;
```

Execute this command (`--verbose` will display the long output and the details for each `type => 1` counters).
This command is based on use Docker SNMPSIM to simulate snmpwalk behavior (hostname, snmp-community and snmp-port).

```shell
perl centreon_plugins.pl --plugin=network::mysnmpplugin::snmp::plugin --mode=cpu --hostname=localhost --snmp-community=local/os_linux_snmp_plugin --snmp-port=2024 --verbose
```

Here is the expected output: 

```shell
OK: All CPUs are ok | '.0.0#cpu.usage.percentage'=6.00%;;;0;100 '.0.0#cpu.usage.percentage'=16.00%;;;0;100
CPU '.0.0' usage: 6.00 %
CPU '.0.0' usage: 16.00 %
```

### 4.5 Help section and assistant to build your centreon objects

Last but not least, you need to write a help section to explain users what your mode is
doing and what options they can use.

The centreon-plugins framework has a built-in assistant to help you with the list of counters
and options.

Run this command to obtain a summary that will simplify the work of creating Centreon commands and write
the mode's help:

```shell
perl centreon_plugins.pl --plugin=network::mysnmpplugin::snmp::plugin --mode=cpu --hostname='anyvalue' --list-counters --verbose
```

Get information from its output (shown below) to start building your mode's help:

```shell
counter list: cpu-usage-prct 
configuration:  --warning-cpu-usage-prct='$_SERVICEWARNINGCPUUSAGEPRCT$' --critical-cpu-usage-prct='$_SERVICECRITICALCPUUSAGEPRCT$'
```

Here is how you can write the help, note that this time you will add the content after the `1;` and add the same
`__END__` instruction like you did in the `plugin.pm` file. 

```perl
__END__

=head1 MODE

Check system CPUs.

=over 8

=item B<--filter-id>

Filter on one ID name.

=item B<--warning>

Warning threshold for CPU.

=item B<--critical>

Critical threshold for CPU.

=back

=cut
```