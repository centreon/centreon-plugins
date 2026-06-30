#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

my $oid_snsNodeIndex   = '.1.3.6.1.4.1.11256.1.11.7.1.1';
my $oid_snsFwSerial = '.1.3.6.1.4.1.11256.1.11.7.1.2';

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:fan|temperature)$';

    $self->{cb_hook1} = 'detect_topology';
    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        fan => [
            ['running', 'OK'],
            ['.*',      'CRITICAL']
        ],
        psu => [
            ['OK',  'OK'],
            ['.*',  'CRITICAL']
        ],
        disk => [
            ['PASSED',       'OK'],
            ['NotSupported', 'OK'],
            ['.*',           'CRITICAL']
        ]
    };

    $self->{components_path}   = 'network::stormshield::snmp::mode::components';
    $self->{components_module} = ['temperature', 'fan', 'psu', 'disk'];
}

sub detect_topology {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    my $ha_result = $options{snmp}->get_table(
        oid          => $oid_snsNodeIndex,
        nothing_quit => 0
    );

    $self->{ha_nodes}   = [];
    $self->{ha_serials} = {};

    if (!defined $ha_result || scalar(keys %$ha_result) == 0) {
        # Single Node
        $self->{is_ha} = 0;
        push @{$self->{ha_nodes}}, '0';
        $self->{ha_serials}->{'0'} = 'single';
        return;
    }

    # HA
    $self->{is_ha} = 1;
    foreach my $oid (sort keys %$ha_result) {
        if ($oid =~ /^$oid_snsNodeIndex\.(\d+)$/) {
            push @{$self->{ha_nodes}}, $1;
        }
    }

    my @serial_oids = map { "$oid_snsFwSerial.$_" } @{$self->{ha_nodes}};
    my $serial_res  = $options{snmp}->get_leef(oids => \@serial_oids, nothing_quit => 0);
    foreach my $node_id (@{$self->{ha_nodes}}) {
        my $s = $serial_res->{"$oid_snsFwSerial.$node_id"};
        $self->{ha_serials}->{$node_id} = defined $s ? $s : "node$node_id";
    }
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp}    = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware components (temperature, fan, PSU, disk).
Automatically detects single-node and high-availability (HA) cluster configurations.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'disk', 'fan', 'psu', 'temperature'.

=item B<--filter>

Exclude items given as a comma-separated list (example: --filter=fan).
You can also exclude specific instances: --filter=fan,1

=item B<--absent-problem>

Return an error if a component is not present (default: skip).
Can be set globally or per instance: --absent-problem='component_name' or
--absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Override the status returned by the plugin when the status label matches a
regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='disk,WARNING,missing'

=item B<--warning>

Set warning threshold for 'temperature' or 'fan' (syntax: type,regexp,threshold).
Example: --warning='temperature,.*,60'

=item B<--critical>

Set critical threshold for 'temperature' or 'fan' (syntax: type,regexp,threshold).
Example: --critical='temperature,.*,70'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type
(replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type
(replace '*' with the component type).

=back

=cut