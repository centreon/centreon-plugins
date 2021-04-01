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

package apps::bluemind::local::mode::hps;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_hps_output {
    my ($self, %options) = @_;
    
    return 'Authentication service ';
}
sub prefix_upstream_output {
    my ($self, %options) = @_;

    return "Upstream '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_hps', type => 0, cb_prefix_output => 'prefix_hps_output' },
        { name => 'bm_hps_upstream', type => 1, cb_prefix_output => 'prefix_upstream_output', message_multiple => 'All upstreams are ok' }
    ];
    
    $self->{maps_counters}->{bm_hps} = [
        { label => 'authentication-success', nlabel => 'hps.authentication.success.count', display_ok => 0, set => {
                key_values => [ { name => 'auth_success', diff => 1 } ],
                output_template => 'success authentication: %s',
                perfdatas => [
                    { value => 'auth_success', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'authentication-failure', nlabel => 'hps.authentication.failure.count', set => {
                key_values => [ { name => 'auth_failure', diff => 1 } ],
                output_template => 'failure authentication: %s',
                perfdatas => [
                    { value => 'auth_failure', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-protected', nlabel => 'hps.requests.protected.count', display_ok => 0, set => {
                key_values => [ { name => 'requests_protected', diff => 1 } ],
                output_template => 'protected requests: %s',
                perfdatas => [
                    { value => 'requests_protected', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-maintenance', nlabel => 'hps.requests.maintenance.count', set => {
                key_values => [ { name => 'requests_maintenance', diff => 1 } ],
                output_template => 'maintenance requests: %s',
                perfdatas => [
                    { value => 'requests_maintenance', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{bm_hps_upstream} = [
        { label => 'upstream-requests-time-total', nlabel => 'hps.upstream.requests.time.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'requests_time_total', diff => 1 }, { name => 'display' } ],
                output_template => 'total requests time: %s ms',
                perfdatas => [
                    { value => 'requests_time_total', template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'upstream-requests-time-mean', nlabel => 'hps.upstream.requests.time.mean.milliseconds', set => {
                key_values => [ { name => 'requests_time_mean' }, { name => 'display' } ],
                output_template => 'mean requests time: %s ms',
                perfdatas => [
                    { value => 'requests_time_mean', template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'upstream-requests-size-total', nlabel => 'hps.upstream.requests.size.total.bytes', display_ok => 0, set => {
                key_values => [ { name => 'requests_size', diff => 1 } ],
                output_template => 'total requests size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'requests_size', template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'upstream-requests-total', nlabel => 'hps.upstream.requests.total.count', display_ok => 0, set => {
                key_values => [ { name => 'requests', diff => 1 } ],
                output_template => 'total requests: %s',
                perfdatas => [
                    { value => 'requests', template => '%s', min => 0 }
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
        'filter-upstream:s' => { name => 'filter_upstream' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # bm-hps.authCount,status=failure,meterType=Counter count=855
    # bm-hps.authCount,status=success,meterType=Counter count=11957
    # bm-hps.ftlTemplates.requests,meterType=Counter count=23064
    # bm-hps.requestsCount,kind=protected,meterType=Counter count=3080815
    # bm-hps.requestsCount,kind=maintenance,meterType=Counter count=1
    # bm-hps.upstreamRequestSize,path=/login,meterType=DistSum count=331977,totalAmount=0,mean=0
    # bm-hps.upstreamRequestTime,path=/login,meterType=Timer count=37864,totalTime=70405376220,mean=1859427
    # bm-hps.upstreamRequestsCount,path=/login,meterType=Counter count=1383
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-hps.sock http://127.0.0.1/metrics',
        filter => 'authCount|ftlTemplates\.requests|requestsCount|upstreamRequestSize|upstreamRequestTime|upstreamRequestsCount'
    );

    $self->{bm_hps} = {};
    $self->{bm_hps_upstream} = {};
    foreach (keys %$result) {
        $self->{bm_hps}->{'auth_' . $1} = $result->{$_}->{count} if (/bm-hps\.authCount.*status=(failure|success)/);
        $self->{bm_hps}->{'requests_' . $1} = $result->{$_}->{count} if (/bm-hps\.requestsCount.*kind=(maintenance|protected)/);

        if (/bm-hps\.upstreamRequestTime.*path=(.*?),/) {
            my $upstream = $1;
            if (defined($self->{option_results}->{filter_upstream}) && $self->{option_results}->{filter_upstream} ne '' &&
                $upstream !~ /$self->{option_results}->{filter_upstream}/) {
                $self->{output}->output_add(long_msg => "skipping upstream '" . $upstream . "': no matching filter.", debug => 1);
                next;
            }

            $self->{bm_hps_upstream}->{$upstream} = {
                display => $upstream,
                requests_time_total => $result->{$_}->{totalTime} / 100000,
                requests_time_mean => $result->{$_}->{mean} / 100000,
                requests_size => $result->{"bm-hps.upstreamRequestSize,path=$upstream,meterType=DistSum"}->{totalAmount},
                requests => $result->{"bm-hps.upstreamRequestsCount,path=$upstream,meterType=Counter"}->{count}
            };
        }
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check authentication service.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='maintenance'

=item B<--filter-upstream>

Filter upstream name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'authentication-success', 'authentication-failure', 'requests-protected', 
'requests-maintenance', 'upstream-requests-time-total', 'upstream-requests-time-mean',
'upstream-requests-size-total, 'upstream-requests-total'.

=back

=cut
