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

package network::perle::ids::snmp::mode::systemusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu-load', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_load' } ],
                output_template => 'cpu load : %.2f %%',
                perfdatas => [
                    { value => 'cpu_load', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'memory-free', nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'memory_free' } ],
                output_template => 'memory free : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'memory_free', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'flashdisk-free', nlabel => 'flashdisk.free.bytes', set => {
                key_values => [ { name => 'flashdisk_free' } ],
                output_template => 'flash disk free : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'flashdisk_free', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
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

    my $oid_perleAverageCPUUtilization = '.1.3.6.1.4.1.1966.22.44.1.24.0';
    my $oid_perleMemory = '.1.3.6.1.4.1.1966.22.44.1.25.0'; # 295928 Kbytes free
    my $oid_perleFlashdisk = '.1.3.6.1.4.1.1966.22.44.1.26.0';
    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_perleAverageCPUUtilization, $oid_perleMemory, $oid_perleFlashdisk
        ],
        nothing_quit => 1
    );

    my ($cpu_load, $mem_free, $flashdisk_free);
    $cpu_load = $1
        if (defined($result->{$oid_perleAverageCPUUtilization}) && $result->{$oid_perleAverageCPUUtilization} =~ /((?:\d+)(?:\.\d+)?)/);
    $mem_free = $1 * 1024 if (defined($result->{$oid_perleMemory}) && $result->{$oid_perleMemory} =~ /(\d+)/);
    $flashdisk_free = $1 * 1024 if (defined($result->{$oid_perleFlashdisk}) && $result->{$oid_perleFlashdisk} =~ /(\d+)/);
    $self->{global} = { 
        cpu_load => $cpu_load,
        memory_free => $mem_free,
        flashdisk_free => $flashdisk_free,
    };
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory-free$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-free' (B), 'cpu-load' (%), 'flashdisk-free' (B)

=back

=cut
