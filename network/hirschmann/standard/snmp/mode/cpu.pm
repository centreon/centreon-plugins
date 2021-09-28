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

package network::hirschmann::standard::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'Cpu utilization: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization-current', nlabel => 'cpu.utilization.current.percentage', set => {
                key_values => [ { name => 'cpu_util' } ],
                output_template => '%.2f%% (current)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'cpu-utilization-30m', nlabel => 'cpu.utilization.30m.percentage', set => {
                key_values => [ { name => 'cpu_util_avg' } ],
                output_template => '%.2f%% (30min)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_enable = {
    1 => 'enable', 2 => 'disable'
};

my $mapping = {
    hios => {
        measure_enable => { oid => '.1.3.6.1.4.1.248.11.22.1.8.1', map => $map_enable }, # hm2DiagEnableMeasurement
        cpu_util       => { oid => '.1.3.6.1.4.1.248.11.22.1.8.10.1' }, # hm2DiagCpuUtilization
        cpu_util_avg   => { oid => '.1.3.6.1.4.1.248.11.22.1.8.10.2' }  # hm2DiagCpuAverageUtilization
    },
    classic => {
        measure_enable => { oid => '.1.3.6.1.4.1.248.14.2.15.1', map => $map_enable }, # hmEnableMeasurement
        cpu_util       => { oid => '.1.3.6.1.4.1.248.14.2.15.2.1' }, # hmCpuUtilization
        cpu_util_avg   => { oid => '.1.3.6.1.4.1.248.14.2.15.2.2' }  # hmCpuAverageUtilization
    }
};

sub check_cpu {
    my ($self, %options) = @_;

    my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => 0);
    return 0 if (!defined($result->{cpu_util}));

    if ($result->{measure_enable} eq 'disable') {
        $self->{output}->add_option_msg(short_msg => 'resource measurement is disabled');
        $self->{output}->option_exit();
    }
    $self->{global} = {
        cpu_util => $result->{cpu_util},
        cpu_util_avg => $result->{cpu_util_avg}
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{hios}}), values(%{$mapping->{classic}})) ],
        nothing_quit => 1
    );
    if ($self->check_cpu(snmp => $options{snmp}, type => 'hios', snmp_result => $snmp_result) == 0) {
        $self->check_cpu(snmp => $options{snmp}, type => 'classic', snmp_result => $snmp_result);
    }
}

1;

__END__

=head1 MODE

Check cpu.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization-current' (%), 'cpu-utilization-30m' (%).

=back

=cut
