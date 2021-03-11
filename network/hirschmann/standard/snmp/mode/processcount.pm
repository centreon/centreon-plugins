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

package network::hirschmann::standard::snmp::mode::processcount;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_proc_output {
    my ($self, %options) = @_;

    return 'Number of processes running: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_proc_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'processes-running-current', nlabel => 'processes.running.current.count', set => {
                key_values => [ { name => 'proc_run' } ],
                output_template => '%s (current)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'processes-running-max', nlabel => 'processes.running.maximum.count', set => {
                key_values => [ { name => 'proc_run_max' } ],
                output_template => '%s (maximum last 30min)',
                perfdatas => [
                    { template => '%s', min => 0  }
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
        proc_run       => { oid => '.1.3.6.1.4.1.248.11.22.1.8.10.3' }, # hm2DiagCpuRunningProcesses
        proc_run_max   => { oid => '.1.3.6.1.4.1.248.11.22.1.8.10.4' }  # hm2DiagCpuMaxRunningProcesses
    },
    classic => {
        measure_enable => { oid => '.1.3.6.1.4.1.248.14.2.15.1', map => $map_enable }, # hmEnableMeasurement
        proc_run       => { oid => '.1.3.6.1.4.1.248.14.2.15.2.3' }, # hmCpuRunningProcesses
        proc_run_max   => { oid => '.1.3.6.1.4.1.248.14.2.15.2.4' }  # hmCpuMaxRunningProcesses
    }
};

sub check_proc {
    my ($self, %options) = @_;

    my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => 0);
    return 0 if (!defined($result->{proc_run}));

    if ($result->{measure_enable} eq 'disable') {
        $self->{output}->add_option_msg(short_msg => 'resource measurement is disabled');
        $self->{output}->option_exit();
    }
    $self->{global} = $result;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{hios}}), values(%{$mapping->{classic}})) ],
        nothing_quit => 1
    );
    if ($self->check_proc(snmp => $options{snmp}, type => 'hios', snmp_result => $snmp_result) == 0) {
        $self->check_proc(snmp => $options{snmp}, type => 'classic', snmp_result => $snmp_result);
    }
}

1;

__END__

=head1 MODE

Check number of processes.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'processes-running-current', 'processes-running-max'.

=back

=cut
