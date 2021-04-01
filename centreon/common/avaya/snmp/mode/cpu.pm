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

package centreon::common::avaya::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' },
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'usage : %s %%',
                perfdatas => [
                    { label => 'cpu_usage', value => 'cpu',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

my $map_cpu_monitoring = { 1 => 'disabled', 2 => 'enabled' };

my $mapping = {
    genCpuUtilizationEnableMonitoring   => { oid => '.1.3.6.1.4.1.6889.2.1.11.1.1.1.1.2', map => $map_cpu_monitoring },
    genCpuAverageUtilization            => { oid => '.1.3.6.1.4.1.6889.2.1.11.1.1.1.1.5' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_genCpuUtilizationEntry = '.1.3.6.1.4.1.6889.2.1.11.1.1.1.1';
    my $results = $options{snmp}->get_table(oid => $oid_genCpuUtilizationEntry, nothing_quit => 1);
    $self->{cpu} = {};
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{genCpuAverageUtilization}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        
        if ($result->{genCpuUtilizationEnableMonitoring} eq 'disabled') {
            next;
        }

        $self->{cpu}->{$instance} = {
            display => $instance,
            cpu => $result->{genCpuAverageUtilization},
        };
    }
    
    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found (or cpu monitoring is disabled).");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
