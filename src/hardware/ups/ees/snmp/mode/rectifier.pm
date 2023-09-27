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

package hardware::ups::ees::snmp::mode::rectifier;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub rectifier_custom_output {
    my ($self, %options) = @_;

    return sprintf(
        "installed: %d, communicating: %d, used capacity: %.2f%%",
        $self->{result_values}->{installed},
        $self->{result_values}->{communicating},
        $self->{result_values}->{used_capacity}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'rectifier', type => 0 }
    ];

    $self->{maps_counters}->{rectifier} = [
        {
            label           => 'status',
            warning_default => '%{installed} != %{communicating}',
            type            => 2,
            set             => {
                key_values                     => [
                    { name => 'used_capacity' },
                    { name => 'installed' },
                    { name => 'communicating' }
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_output          => $self->can('rectifier_custom_output')
            }
        },
        {
            label => 'used-capacity', display_ok => 0, nlabel => 'rectifier.capacity.used.percentage',
            set   => {
                key_values      => [ { name => 'used_capacity' } ],
                output_template => 'used capacity: %.2f%%',
                perfdatas       => [ { template => '%.2f', min => 0, max => 100, unit => '%' } ]
            }
        },
        {
            label => 'installed', display_ok => 0, nlabel => 'rectifier.installed.count',
            set   => {
                key_values      => [ { name => 'installed' } ],
                output_template => 'installed: %d',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        {
            label => 'communicating', display_ok => 0, nlabel => 'rectifier.communicating.count',
            set   => {
                key_values      => [ { name => 'communicating' } ],
                output_template => 'communicating: %d',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_numberOfInstalledRectifiers = '.1.3.6.1.4.1.6302.2.1.2.11.1.0';
    my $oid_numberOfRectifiersCommunicating = '.1.3.6.1.4.1.6302.2.1.2.11.2.0';
    my $oid_rectifiersUsedCapacity = '.1.3.6.1.4.1.6302.2.1.2.11.3.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [
            $oid_numberOfInstalledRectifiers,
            $oid_numberOfRectifiersCommunicating,
            $oid_rectifiersUsedCapacity
        ],
        nothing_quit => 1
    );

    $self->{rectifier} = {
        installed     => $snmp_result->{$oid_numberOfInstalledRectifiers},
        communicating => $snmp_result->{$oid_numberOfRectifiersCommunicating},
        used_capacity => $snmp_result->{$oid_rectifiersUsedCapacity}
    };
}

1;

__END__

=head1 MODE

Check rectifier.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{installed},  %{communicating},  %{used_capacity}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{installed} != %{communicating}').
You can use the following variables: %{installed},  %{communicating},  %{used_capacity}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{installed},  %{communicating},  %{used_capacity}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'used-capacity', 'installed', 'communicating'

=back

=cut
