#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package network::lenovo::flexsystem::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_message_output', message_multiple => 'All CPU usages are ok' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' }, { name => 'display' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { value => 'average_1m', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' }, { name => 'display' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { value => 'average_5m', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_message_output {
    my ($self, %options) = @_;

    return "Switch '" . $options{instance_value}->{display} . "' CPU average usage: ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-switch-num:s' => { name => 'filter_switch_num' }
    });

    return $self;
}

my $mapping = {
    average_1m => { oid => '.1.3.6.1.4.1.20301.2.5.1.2.2.12.1.1.5' }, # mpCpuStatsUtil1MinuteSwRev
    average_5m => { oid => '.1.3.6.1.4.1.20301.2.5.1.2.2.12.1.1.6' } # mpCpuStatsUtil5MinutesSwRev
};

my $oid_mpCpuStatsRevTableEntry = '.1.3.6.1.4.1.20301.2.5.1.2.2.12.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_mpCpuStatsRevTableEntry,
        start => $mapping->{average_1m}->{oid},
        nothing_quit => 1
    );

    $self->{cpu} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{average_1m}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_switch_num}) && $self->{option_results}->{filter_switch_num} ne '' &&
            $instance !~ /$self->{option_results}->{filter_switch_num}/) {
            $self->{output}->output_add(long_msg => "skipping member '" . $instance . "': no matching filter.", debug => 1);
            next;
        }

        $self->{cpu}->{'switch' . $instance} = {
            display => $instance,
            %$result
        };
    }
}

1;

__END__

=head1 MODE

Check CPU usage (over the last minute).

=over 8

=item B<--filter-switch-num>

Filter switch number.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'average-1m' (%), 'average-5m' (%).

=back

=cut
