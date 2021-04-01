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

package network::huawei::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', set => {
                key_values => [ { name => 'cpu' }, { name => 'num' }, ],
                output_template => 'Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu', value => 'cpu', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{num} . "' ";
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

my $oid_hwEntityCpuUsage = '.1.3.6.1.4.1.2011.5.25.31.1.1.1.1.5';
my $oid_hwAvgDuty5min = '.1.3.6.1.4.1.2011.6.3.4.1.4';
my $oid_hwResOccupancy = '.1.3.6.1.4.1.2011.6.3.17.1.1.3';
my $map_type = { 1 => 'memory', 2 => 'messageUnits', 3 => 'cpu' };

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(oids => [
        { oid => $oid_hwEntityCpuUsage },
        { oid => $oid_hwAvgDuty5min },
        { oid => $oid_hwResOccupancy },
    ], nothing_quit => 1);
    
    $self->{cpu} = {};
    my $num = 1;
    if (defined($results->{$oid_hwAvgDuty5min}) && scalar(keys %{$results->{$oid_hwAvgDuty5min}}) > 0) {
        foreach (keys %{$results->{$oid_hwAvgDuty5min}}) {
            $self->{cpu}->{$num} = { num => $num, cpu => $results->{$oid_hwAvgDuty5min}->{$_} };
            $num++;
        }
    } elsif (defined($results->{$oid_hwEntityCpuUsage}) && scalar(keys %{$results->{$oid_hwEntityCpuUsage}}) > 0) {
        foreach (keys %{$results->{$oid_hwEntityCpuUsage}}) {
            $self->{cpu}->{$num} = { num => $num, cpu => $results->{$oid_hwEntityCpuUsage}->{$_} };
            $num++;
        }
    } else {
        foreach (keys %{$results->{$oid_hwResOccupancy}}) {
            /\.([0-9]*?)$/;
            next if (!defined($map_type->{$1}) || $map_type->{$1} ne 'cpu');
            $self->{cpu}->{$num} = { num => $num, cpu => $results->{$oid_hwResOccupancy}->{$_} };
            $num++;
        }
    }
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
