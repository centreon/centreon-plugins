Update soon

### 7.SNMP

Tutorial : How to create a plugin - Using SNMP

**Description**

This example explains how to check a single SNMP value on a PfSense firewall (memory dropped packets).
We use cache file because it's a SNMP counter. So we need to get the value between 2 checks.
We get the value and compare it to warning and critical thresholds.

#### 7.1. Plugin file

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

#### 7.2.Mode file

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

#### 7.3.Command line

This is an example of command line:

```
  $ perl centreon_plugins.pl --plugin apps::pfsense::snmp::plugin --mode memory-dropped-packets --hostname 192.168.0.1 --snmp-community 'public' --snmp-version '2c' --warning '1' --critical '2'
```
Output may display:

```
  OK: Dropped packets due to memory limitations : 0.00 /s | dropped_packets_Per_Sec=0.00;0;;1;2
```

<div id='example'/>