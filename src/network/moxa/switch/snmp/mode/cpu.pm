#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::moxa::switch::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return 'cpu average usage: ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization-5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'cpu_load5s' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'cpu-utilization-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_load1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'cpu-utilization-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_load5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

my $mapping = {
    iks6726a    => {
        cpu_load5s => { oid => '.1.3.6.1.4.1.8691.7.116.1.53' },
        cpu_load1m => { oid => '.1.3.6.1.4.1.8691.7.116.1.54' },
        cpu_load5m => { oid => '.1.3.6.1.4.1.8691.7.116.1.55' }
    },
    eds405a => {
        cpu_load5s => { oid => '.1.3.6.1.4.1.8691.7.6.1.53' },
        cpu_load1m => { oid => '.1.3.6.1.4.1.8691.7.6.1.54' },
        cpu_load5m => { oid => '.1.3.6.1.4.1.8691.7.6.1.55' }
    },
    edsp506e => {
        cpu_load5s => { oid => '.1.3.6.1.4.1.8691.7.162.1.53' },
        cpu_load1m => { oid => '.1.3.6.1.4.1.8691.7.162.1.54' },
        cpu_load5m => { oid => '.1.3.6.1.4.1.8691.7.162.1.55' }
    },
    edsp506a => {
        cpu_load5s => { oid => '.1.3.6.1.4.1.8691.7.41.1.53' },
        cpu_load1m => { oid => '.1.3.6.1.4.1.8691.7.41.1.54' },
        cpu_load5m => { oid => '.1.3.6.1.4.1.8691.7.41.1.55' }
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            map(
                $_->{oid} . '.0',
                values(%{$mapping->{iks6726a}}),
                values(%{$mapping->{eds405a}}),
                values(%{$mapping->{edsp506e}}),
                values(%{$mapping->{edsp506a}})
            )
        ],
        nothing_quit => 1
    );

    foreach (keys %$mapping) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$_}, results => $snmp_result, instance => 0);
        next if (!defined($result->{cpu_load5m}));
        $self->{global} = $result;
        last;
    }
}

1;

__END__

=head1 MODE

Check CPU usage

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='1m|5m'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization-1s', 'cpu-utilization-1m', 'cpu-utilization-5m'.

=back

=cut
