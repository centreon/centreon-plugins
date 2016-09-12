#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::nortel::standard::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' }, { name => 'num' } ],
                output_template => 'Total CPU Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu_total', value => 'total_absolute', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'num_absolute' },
                ],
            }
        },
        { label => '1m', set => {
                key_values => [ { name => '1m' }, { name => 'num' } ],
                output_template => '1 minute : %.2f %%',
                perfdatas => [
                    { label => 'cpu_1min', value => '1m_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
                ],
            }
        },
        { label => '10m', set => {
                key_values => [ { name => '10m' }, { name => 'num' } ],
                output_template => '10 minutes : %.2f %%',
                perfdatas => [
                    { label => 'cpu_10min', value => '10m_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
                ],
            }
        },
        { label => '1h', set => {
                key_values => [ { name => '1h' }, { name => 'num' } ],
                output_template => '1 hour : %.2f %%',
                perfdatas => [
                    { label => 'cpu_1h', value => '1h_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
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
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $mapping = {
    s5ChasUtilTotalCPUUsage         => { oid => '.1.3.6.1.4.1.45.1.6.3.8.1.1.4' },
    s5ChasUtilCPUUsageLast1Minute   => { oid => '.1.3.6.1.4.1.45.1.6.3.8.1.1.5' },
    s5ChasUtilCPUUsageLast10Minutes => { oid => '.1.3.6.1.4.1.45.1.6.3.8.1.1.6' },
    s5ChasUtilCPUUsageLast1Hour     => { oid => '.1.3.6.1.4.1.45.1.6.3.8.1.1.7' },
};

my $oid_rcSysCpuUtil = '.1.3.6.1.4.1.2272.1.1.20';  # without .0
my $oid_s5ChasUtilEntry = '.1.3.6.1.4.1.45.1.6.3.8.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_rcSysCpuUtil },
                                                            { oid => $oid_s5ChasUtilEntry },
                                                          ], nothing_quit => 1);
    
    $self->{cpu} = {};
    foreach my $oid (keys %{$self->{results}->{$oid_s5ChasUtilEntry}}) {
        next if ($oid !~ /^$mapping->{s5ChasUtilTotalCPUUsage}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_s5ChasUtilEntry}, instance => $instance);
        
        $self->{cpu}->{$instance} = { num => $instance, total => $result->{s5ChasUtilTotalCPUUsage},
                                      '1m' => $result->{s5ChasUtilCPUUsageLast1Minute}, '10m' => $result->{s5ChasUtilCPUUsageLast10Minutes},
                                      '1h' => $result->{s5ChasUtilCPUUsageLast1Hour} };
    }
    
    if (scalar(keys %{$self->{results}->{$oid_rcSysCpuUtil}}) > 0) {
        $self->{cpu}->{0} = { num => 0, total => $self->{results}->{$oid_rcSysCpuUtil}->{$oid_rcSysCpuUtil . '.0'} };
    }
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(1m|10m)$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', '1m', '5m', '10m', '1h'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', '1m', '5m', '10m', '1h'.

=back

=cut
