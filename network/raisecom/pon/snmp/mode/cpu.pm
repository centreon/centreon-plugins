#
# Copyright 2022 Centreon (http://www.centreon.com/)
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
# Authors : Roman Morandell - i-Vertix
#

package network::raisecom::pon::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => '1s', set => {
            key_values      => [ { name => 'oneSec' } ],
            output_template => '%.2f%% (1sec)',
            perfdatas       => [
                { label => 'cpu_1s', value => 'oneSec', template => '%.2f',
                  min   => 0, max => 100, unit => '%' },
            ],
        }
        },
        { label => '10m', set => {
            key_values      => [ { name => 'tenMin' } ],
            output_template => '%.2f%% (10min)',
            perfdatas       => [
                { label => 'cpu_10m', value => 'tenMin', template => '%.2f',
                  min   => 0, max => 100, unit => '%' },
            ],
        }
        },
        { label => '2h', set => {
            key_values      => [ { name => 'twoHour' } ],
            output_template => '%.2f%% (2h)',
            perfdatas       => [
                { label => 'cpu_2h', value => 'twoHour', template => '%.2f',
                  min   => 0, max => 100, unit => '%' },
            ],
        }
        }
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU Usage ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                   {
                                   });

    return $self;
}

my $mapping = {
    oneSec  => { oid => '.1.3.6.1.4.1.8886.18.1.7.1.1.1.3' },
    tenMin  => { oid => '.1.3.6.1.4.1.8886.18.1.7.1.1.1.4' },
    twoHour => { oid => '.1.3.6.1.4.1.8886.18.1.7.1.1.1.5' }
};

my $oid_raisecomCPUUtilizationEntry = '.1.3.6.1.4.1.8886.18.1.7.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cpu} = {};

    my $snmp_result = $options{snmp}->get_table(
        oid          => $oid_raisecomCPUUtilizationEntry,
        start        => $mapping->{oneSec}->{oid},
        end          => $mapping->{twoHour}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{oneSec}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        foreach my $period (keys $mapping) {
            $self->{cpu}->{$period} = $result->{$period};
        }
    }
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(1s|10m|2h)$'

=item B<--warning-*>

Threshold warning.
Can be: '1s', '10m', '2h'.

=item B<--critical-*>

Threshold critical.
Can be: '1s', '10m', '2h'.

=back

=cut
