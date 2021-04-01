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

package network::extreme::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global', },
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total CPU Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu_total', value => 'total', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => '5secs', set => {
                key_values => [ { name => 'extremeCpuMonitorSystemUtilization5secs' }, { name => 'num' }, ],
                output_template => '5 seconds : %.2f %%',
                perfdatas => [
                    { label => 'cpu_5secs', value => 'extremeCpuMonitorSystemUtilization5secs', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num' },
                ],
            }
        },
        { label => '10secs', set => {
                key_values => [ { name => 'extremeCpuMonitorSystemUtilization10secs' }, { name => 'num' }, ],
                output_template => '10 seconds : %.2f %%',
                perfdatas => [
                    { label => 'cpu_10secs', value => 'extremeCpuMonitorSystemUtilization10secs', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num' },
                ],
            }
        },
        { label => '30secs', set => {
                key_values => [ { name => 'extremeCpuMonitorSystemUtilization30secs' }, { name => 'num' }, ],
                output_template => '30 seconds : %.2f %%',
                perfdatas => [
                    { label => 'cpu_30secs', value => 'extremeCpuMonitorSystemUtilization30secs', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num' },
                ],
            }
        },
        { label => '1min', set => {
                key_values => [ { name => 'extremeCpuMonitorSystemUtilization1min' }, { name => 'num' }, ],
                output_template => '1 minute : %.2f %%',
                perfdatas => [
                    { label => 'cpu_1min', value => 'extremeCpuMonitorSystemUtilization1min', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num' },
                ],
            }
        },
        { label => '5min', set => {
                key_values => [ { name => 'extremeCpuMonitorSystemUtilization5mins' }, { name => 'num' }, ],
                output_template => '5 minutes : %.2f %%',
                perfdatas => [
                    { label => 'cpu_5min', value => 'extremeCpuMonitorSystemUtilization5mins', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num' },
                ],
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{cpu}}) > 1 ? return(0) : return(1);
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{num} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

my $mapping = {
    extremeCpuMonitorSystemUtilization5secs => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.5' },
    extremeCpuMonitorSystemUtilization10secs => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.6' },
    extremeCpuMonitorSystemUtilization30secs => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.7' },
    extremeCpuMonitorSystemUtilization1min => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.8' },
    extremeCpuMonitorSystemUtilization5mins => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.9' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_extremeCpuMonitorSystemEntry = '.1.3.6.1.4.1.1916.1.32.1.4.1';
    my $oid_extremeCpuMonitorTotalUtilization = '.1.3.6.1.4.1.1916.1.32.1.2'; # without .0
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_extremeCpuMonitorTotalUtilization },
            { oid => $oid_extremeCpuMonitorSystemEntry, start => $mapping->{extremeCpuMonitorSystemUtilization5secs}->{oid}, end => $mapping->{extremeCpuMonitorSystemUtilization5mins}->{oid} },
        ],
        nothing_quit => 1
    );

    $self->{cpu} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_extremeCpuMonitorSystemEntry}}) {
        next if ($oid !~ /^$mapping->{extremeCpuMonitorSystemUtilization1min}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_extremeCpuMonitorSystemEntry}, instance => $instance);
        
        foreach (keys %{$mapping}) {
            $result->{$_} = undef if (defined($result->{$_}) && $result->{$_} =~ /n\/a/i);
        }
        
        $self->{cpu}->{$instance} = { num => $instance, %$result };
    }

    $self->{global} = { total => $snmp_result->{$oid_extremeCpuMonitorTotalUtilization}->{$oid_extremeCpuMonitorTotalUtilization . '.0'} };
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(1min|5min)$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', '5sec', '10sec', '30sec, '1min', '5min'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', '5sec', '10sec', '30sec, '1min', '5min'.

=back

=cut
