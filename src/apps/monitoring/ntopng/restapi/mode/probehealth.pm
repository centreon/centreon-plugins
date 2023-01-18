#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package apps::monitoring::ntopng::restapi::mode::probehealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpuUtil' } ],
                output_template => 'cpu utilization: %.2f%%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'cpu-load', nlabel => 'cpu.load.percentage', set => {
                key_values => [ { name => 'cpuLoad' } ],
                output_template => 'cpu load: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'memory-usage', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'memoryUsed' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'dropped-alerts', nlabel => 'alerts.dropped.persecond', set => {
                key_values => [ { name => 'droppedAlerts', per_second => 1 } ],
                output_template => 'dropped alerts: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'interface:s' => { name => 'interface', default => 0 }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(
        endpoint => "/lua/rest/v2/get/interface/data.lua",
        get_param => ['ifid=' . $self->{option_results}->{interface} ]
    );

    $self->{global} = {
        memoryUsed => 100 * $results->{rsp}->{system_host_stats}->{mem_used} / $results->{rsp}->{system_host_stats}->{mem_total},
        cpuUtil    => 100 - $results->{rsp}->{system_host_stats}->{cpu_states}->{idle},
        cpuLoad    => $results->{rsp}->{system_host_stats}->{cpu_load},
        droppedAlerts => $results->{rsp}->{system_host_stats}->{dropped_alerts}
    };

    $self->{cache_name} = 'ntopng_' . $options{custom}->get_hostname() . '_' . $self->{mode} . '_' . 
        md5_hex(
            defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '' . '_' .
            defined($self->{option_results}->{interface}) ? $self->{option_results}->{interface} : ''
        );
}
        
1;

__END__

=head1 MODE

Check ntopng probe health.

=over 8

=item B<--interface>

Interface name to check (0 by default).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization', 'cpu-load', 'memory-usage', 'dropped-alerts'.

=back

=cut
