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

package apps::bluemind::local::mode::webserver;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_webserver_output {
    my ($self, %options) = @_;
    
    return 'Web application server ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_webserver', type => 0, cb_prefix_output => 'prefix_webserver_output' },
    ];
    
    $self->{maps_counters}->{bm_webserver} = [
        { label => 'requests-time-total', nlabel => 'webserver.requests.time.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'requests_time_total', diff => 1 } ],
                output_template => 'total requests time: %s ms',
                perfdatas => [
                    { value => 'requests_time_total', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'requests-time-mean', nlabel => 'webserver.requests.time.mean.milliseconds', set => {
                key_values => [ { name => 'requests_time_mean' } ],
                output_template => 'mean requests time: %s ms',
                perfdatas => [
                    { value => 'requests_time_mean', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'requests-total', nlabel => 'webserver.requests.total.count', set => {
                key_values => [ { name => 'requests', diff => 1 } ],
                output_template => 'total requests: %s',
                perfdatas => [
                    { value => 'requests', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-status-200', nlabel => 'webserver.requests.status.200.count', display_ok => 0, set => {
                key_values => [ { name => 'requests_200', diff => 1 } ],
                output_template => 'total 200 requests: %s',
                perfdatas => [
                    { value => 'requests_200', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-status-304', nlabel => 'webserver.requests.status.304.count', display_ok => 0, set => {
                key_values => [ { name => 'requests_304', diff => 1 } ],
                output_template => 'total 304 requests: %s',
                perfdatas => [
                    { value => 'requests_304', template => '%s', min => 0 }
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

    # bm-webserver.appCache.requestTime,meterType=Timer count=91005,totalTime=46688008481,mean=513026
    # bm-webserver.appCache.requests,meterType=Counter count=8552
    # bm-webserver.staticFile.requests,status=200,meterType=Counter count=318881
    # bm-webserver.staticFile.requests,status=304,meterType=Counter count=3485778
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-webserver.sock http://127.0.0.1/metrics',
        filter => 'appCache|staticFile\.requests'
    );

    $self->{bm_webserver} = {};
    foreach (keys %$result) {
        $self->{bm_webserver}->{'requests_' . $1} = $result->{$_}->{count} if (/bm-webserver\.staticFile\.requests.*,status=(200|304)/);
        $self->{bm_webserver}->{requests} = $result->{$_}->{count} if (/bm-webserver\.appCache\.requests/);

        if (/bm-webserver\.appCache\.requestTime/) {
            $self->{bm_webserver}->{requests_time_total} = $result->{$_}->{totalTime} / 100000;
            $self->{bm_webserver}->{requests_time_mean} = $result->{$_}->{mean} / 100000;
        }
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check web application server.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='requests-time-mean'

=item B<--filter-upstream>

Filter upstream name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'requests-time-total', 'requests-time-mean', 'requests-total',
'requests-status-200', 'requests-status-304'.

=back

=cut
