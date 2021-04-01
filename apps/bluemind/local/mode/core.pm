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

package apps::bluemind::local::mode::core;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_core_output {
    my ($self, %options) = @_;
    
    return 'Main engine ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_core', type => 0, cb_prefix_output => 'prefix_core_output' }
    ];
    
    $self->{maps_counters}->{bm_core} = [
        { label => 'calls-received-success', nlabel => 'core.calls.received.success.count', display_ok => 0, set => {
                key_values => [ { name => 'calls_success', diff => 1 } ],
                output_template => 'success calls received: %s',
                perfdatas => [
                    { value => 'calls_success', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'calls-received-failed', nlabel => 'core.calls.received.failure.count', set => {
                key_values => [ { name => 'calls_failure', diff => 1 } ],
                output_template => 'failure calls received: %s',
                perfdatas => [
                    { value => 'calls_failure', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'heartbeat-broadcast', nlabel => 'core.heartbeat.broadcast.running.count', display_ok => 0, set => {
                key_values => [ { name => 'heartbeat_broadcast', diff => 1 } ],
                output_template => 'broadcast heartbeat running: %s',
                perfdatas => [
                    { value => 'heartbeat_broadcast', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'directory-cluster-events', nlabel => 'core.directory.cluster.events.count', display_ok => 0, set => {
                key_values => [ { name => 'cluster_events', diff => 1 } ],
                output_template => 'directory cluster events: %s',
                perfdatas => [
                    { value => 'cluster_events', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'request-handling-total', nlabel => 'core.request.handling.total.milliseconds', set => {
                key_values => [ { name => 'request_handling_time_total', diff => 1 } ],
                output_template => 'total request handling: %s ms',
                perfdatas => [
                    { value => 'request_handling_time_total', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'request-handling-mean', nlabel => 'core.request.handling.mean.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'request_handling_time_mean' } ],
                output_template => 'mean request handling: %s ms',
                perfdatas => [
                    { value => 'request_handling_time_mean', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # bm-core.heartbeat.broadcast,state=core.state.running,meterType=Counter count=1854550
    # bm-core.handlingDuration,meterType=Timer count=695244256,totalTime=1911292590914929,mean=2749095
    # bm-core.callsCount,status=failure,meterType=Counter count=97
    # bm-core.callsCount,status=success,meterType=Counter count=125244086
    # bm-core.directory.cluster.events,meterType=Counter count=14300
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-core.sock http://127.0.0.1/metrics',
        filter => 'bm-core\.heartbeat\.broadcast|bm-core\.handlingDuration|bm-core\.callsCount|bm-core\.directory\.cluster\.events'
    );

    $self->{bm_core} = {};
    foreach (keys %$result) {
        $self->{bm_core}->{'calls_' . $1} = $result->{$_}->{count} if (/bm-core.callsCount.*status=(failure|success)/);
        $self->{bm_core}->{cluster_events} = $result->{$_}->{count} if (/bm-core\.directory\.cluster\.events/);
        if (/bm-core\.handlingDuration/) { # in nanoseconds
            $self->{bm_core}->{request_handling_time_total} = $result->{$_}->{totalTime} / 1000000;
            $self->{bm_core}->{request_handling_time_mean} = $result->{$_}->{mean} / 1000000;
        }
        $self->{bm_core}->{heartbeat_broadcast} = $result->{$_}->{count} if (/bm-core\.heartbeat\.broadcast.*running/);
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check main bluemind engine.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^calls'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'calls-received-success', 'calls-received-failed',
'heartbeat-broadcast', 'directory-cluster-events',
'request-handling-total', 'request-handling-mean'.

=back

=cut
