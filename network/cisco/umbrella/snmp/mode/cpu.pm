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
#

package network::cisco::umbrella::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'user', nlabel => 'cpu.user.utilization.percentage', set => {
                key_values => [ { name => 'ssCpuRawUser' } ],
                output_template => 'CPU user: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'system', nlabel => 'cpu.system.utilization.percentage', set => {
                key_values => [ { name => 'ssCpuRawSystem' } ],
                output_template => 'CPU system: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'idle', nlabel => 'cpu.idle.utilization.percentage', set => {
                key_values => [ { name => 'ssCpuRawIdle' } ],
                output_template => 'CPU idle: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'CPU Usage: ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1 );
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    ssCpuRawUser    => { oid => '.1.3.6.1.4.1.2021.11.9' },
    ssCpuRawSystem  => { oid => '.1.3.6.1.4.1.2021.11.10' },
    ssCpuRawIdle    => { oid => '.1.3.6.1.4.1.2021.11.11' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_systemStats = '.1.3.6.1.4.1.2021.11';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_systemStats,
        start => $mapping->{ssCpuRawUser}->{oid},
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check system CPUs (User, System, Idle)
An average of all CPUs.

=over 8

=item B<--warning-*>

Threshold warning in percent.
Can be: 'user', 'system', 'idle'.

=item B<--critical-*>

Threshold critical in percent.
Can be: 'user', 'system', 'idle'.

=back

=cut