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

package apps::bluemind::local::mode::lmtpd;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_lmtpd_output {
    my ($self, %options) = @_;
    
    return 'Email delivery service ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_lmtpd', type => 0, cb_prefix_output => 'prefix_lmtpd_output' }
    ];
    
    $self->{maps_counters}->{bm_lmtpd} = [
        { label => 'connections-active', nlabel => 'lmtpd.connections.active.count', set => {
                key_values => [ { name => 'active_connections' } ],
                output_template => 'active connections: %s',
                perfdatas => [
                    { value => 'active_connections', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'connections-total', nlabel => 'lmtpd.connections.total.count', display_ok => 0, set => {
                key_values => [ { name => 'connections', diff => 1 } ],
                output_template => 'total connections: %s',
                perfdatas => [
                    { value => 'connections', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'deliveries-success', nlabel => 'lmtpd.deliveries.success.count', display_ok => 0, set => {
                key_values => [ { name => 'deliveries_ok', diff => 1 } ],
                output_template => 'success deliveries: %s',
                perfdatas => [
                    { value => 'deliveries_ok', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'deliveries-failure', nlabel => 'lmtpd.deliveries.failure.count', display_ok => 0, set => {
                key_values => [ { name => 'deliveries_ko', diff => 1 } ],
                output_template => 'failure deliveries: %s',
                perfdatas => [
                    { value => 'deliveries_ko', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'emails-size-total', nlabel => 'lmtpd.emails.size.total.bytes', display_ok => 0, set => {
                key_values => [ { name => 'email_size', diff => 1 } ],
                output_template => 'total emails size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'email_size', template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'sessions-duration-total', nlabel => 'lmtpd.sessions.duration.total.milliseconds', set => {
                key_values => [ { name => 'session_duration_total', diff => 1 } ],
                output_template => 'total sessions duration: %s ms',
                perfdatas => [
                    { value => 'session_duration_total', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'sessions-duration-mean', nlabel => 'lmtpd.sessions.duration.mean.milliseconds', set => {
                key_values => [ { name => 'session_duration_mean' } ],
                output_template => 'mean sessions duration: %s ms',
                perfdatas => [
                    { value => 'session_duration_mean', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'traffic-transport-latency-total', nlabel => 'lmtpd.traffic.transport.latency.total.milliseconds', set => {
                key_values => [ { name => 'traffic_latency_total', diff => 1 } ],
                output_template => 'total traffic transport latency: %s ms',
                perfdatas => [
                    { value => 'traffic_latency_total', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'traffic-transport-latency-mean', nlabel => 'lmtpd.traffic.transport.latency.mean.milliseconds', set => {
                key_values => [ { name => 'traffic_latency_mean' } ],
                output_template => 'mean traffic transport latency: %s ms',
                perfdatas => [
                    { value => 'traffic_latency_mean', template => '%s', min => 0, unit => 'ms' }
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

    # bm-lmtpd.activeConnections,meterType=Gauge value=0
    # bm-lmtpd.connectionCount,meterType=Counter count=1236057
    # bm-lmtpd.deliveries,status=ko,meterType=Counter count=410
    # bm-lmtpd.deliveries,status=ok,meterType=Counter count=1390933
    # bm-lmtpd.emailSize,meterType=DistSum count=5020456,totalAmount=1170102671020,mean=233067
    # bm-lmtpd.sessionDuration,meterType=Timer count=4941893,totalTime=1052591049892285,mean=212993492
    # bm-lmtpd.traffic.transportLatency,meterType=Timer count=5017208,totalTime=272844528075000000,mean=54381745400
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-lmtpd.sock http://127.0.0.1/metrics',
        filter => 'activeConnections|connectionCount|deliveries|emailSize|sessionDuration|traffic\.transportLatency'
    );

    $self->{bm_lmtpd} = {};
    foreach (keys %$result) {
        $self->{bm_lmtpd}->{'deliveries_' . $1} = $result->{$_}->{count} if (/bm-lmtpd\.deliveries.*status=(ok|ko)/);
        $self->{bm_lmtpd}->{active_connections} = $result->{$_}->{value} if (/bm-lmtpd\.activeConnections/);
        $self->{bm_lmtpd}->{connections} = $result->{$_}->{count} if (/bm-lmtpd\.connectionCount/);
        $self->{bm_lmtpd}->{email_size} = $result->{$_}->{totalAmount} if (/bm-lmtpd\.emailSize/);
        if (/bm-lmtpd\.sessionDuration/) {
            $self->{bm_lmtpd}->{session_duration_total} = $result->{$_}->{totalTime} / 100000;
            $self->{bm_lmtpd}->{session_duration_mean} = $result->{$_}->{mean} / 100000;
        }
        if (/bm-lmtpd\.traffic\.transportLatency/) {
            $self->{bm_lmtpd}->{traffic_latency_total} = $result->{$_}->{totalTime} / 100000;
            $self->{bm_lmtpd}->{traffic_latency_mean} = $result->{$_}->{mean} / 100000;
        }
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check email delivery service.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^deliveries'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections-active', 'connections-total',
'deliveries-success', 'deliveries-failure', 'emails-size-total',
'sessions-duration-total', 'sessions-duration-mean', 'traffic-transport-latency-total',
'traffic-transport-latency-mean'.

=back

=cut
