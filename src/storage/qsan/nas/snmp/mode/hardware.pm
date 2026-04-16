#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package storage::qsan::nas::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use storage::qsan::nas::snmp::mode::components::resources qw($mapping);

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|disk.temperature|voltage|fan)$';

    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        disk => [
            ['reserved', 'OK'],
            ['good', 'OK'],
            ['.*', 'CRITICAL'],
        ],
        monitor => [
            ['OK', 'OK'],
            ['.*', 'CRITICAL'],
        ],
    };
    
    $self->{monitor_loaded} = 0;
    $self->{components_path} = 'storage::qsan::nas::snmp::mode::components';
    $self->{components_module} = ['disk', 'voltage', 'temperature', 'psu', 'fan'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    if ($self->{monitor_loaded} == 1) {
        $self->{results_monitor} = { %{$self->{results}->{$mapping->{ems_type}->{oid}}}, %{$self->{results}->{$mapping->{ems_item}->{oid}}},
            %{$self->{results}->{$mapping->{ems_value}->{oid}}}, %{$self->{results}->{$mapping->{ems_status}->{oid}}} };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'disk', 'voltage', 'temperature', 'psu', 'fan'

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=fan --filter=psu).
You can also exclude items from specific instances: --filter=fan,1

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='psu,WARNING,^(?!(OK)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'disk.temperature', 'voltage', 'fan' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature', 'disk.temperature', 'voltage', 'fan' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
