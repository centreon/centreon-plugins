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

package network::hp::procurve::snmp::mode::environment;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^temperature$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        sensor => [
            ['unknown', 'UNKNOWN'],
            ['bad', 'CRITICAL'],
            ['warning', 'WARNING'],
            ['good', 'OK'],
            ['not present', 'OK']
        ],
        psu => [
            ['psNotPresent', 'OK'],
            ['psNotPlugged', 'WARNING'],
            ['psPowered', 'OK'],
            ['psFailed', 'CRITICAL'],
            ['psPermFailure', 'CRITICAL'],
            ['psMax', 'WARNING'],
            ['psAuxFailure', 'CRITICAL'],
            ['psNotPowered', 'WARNING'],
            ['psAuxNotPowered', 'CRITICAL']
        ],
        fan => [
            ['failed', 'CRITICAL'],
            ['removed', 'OK'],
            ['off', 'WARNING'],
            ['underspeed', 'WARNING'],
            ['overspeed', 'WARNING'],
            ['ok', 'OK'],
            ['maxstate', 'WARNING']
        ]
    };

    $self->{components_path} = 'network::hp::procurve::snmp::mode::components';
    $self->{components_module} = ['fan', 'psu', 'sensor', 'temperature'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

1;

__END__

=head1 MODE

Check sensors (hpicfChassis.mib).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'fan', 'psu', 'sensor', 'temperature'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=sensor).
You can also exclude items from specific instances: --filter=sensor,fan.1

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma separated list)
Can be specific or global: --absent-problem=sensor,temperature.2

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='sensor,CRITICAL,^(?!(good)$)'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
