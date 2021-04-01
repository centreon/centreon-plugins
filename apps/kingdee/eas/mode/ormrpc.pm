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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::ormrpc;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'threads-active', nlabel => 'ormrpc.threads.active.count', set => {
                key_values => [ { name => 'active_thread_count' } ],
                output_template => 'threads active: %s',
                perfdatas => [
                    { value => 'active_thread_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'stubs', nlabel => 'ormrpc.stubs.count', display_ok => 0, set => {
                key_values => [ { name => 'stub_count' } ],
                output_template => 'stubs: %s',
                perfdatas => [
                    { value => 'stub_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'proxies', nlabel => 'ormrpc.proxies.count', display_ok => 0, set => {
                key_values => [ { name => 'proxy_count' } ],
                output_template => 'proxies: %s',
                perfdatas => [
                    { value => 'proxy_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'sessions-client', nlabel => 'ormrpc.sessions.client.count', set => {
                key_values => [ { name => 'client_session_count' } ],
                output_template => 'sessions client: %s',
                perfdatas => [
                    { value => 'client_session_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'sessions-server', nlabel => 'ormrpc.sessions.server.count', set => {
                key_values => [ { name => 'server_session_count' } ],
                output_template => 'sessions server: %s',
                perfdatas => [
                    { value => 'server_session_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'clients-invoke-perminute', nlabel => 'ormrpc.clients.invoked.countperminute', display_ok => 0, set => {
                key_values => [ { name => 'client_invoke_count_per_minute' } ],
                output_template => 'clients invoke: %s/m',
                perfdatas => [
                    { value => 'client_invoke_count_per_minute', template => '%s', min => 0, unit => '/m' },
                ],
            }
        },
        { label => 'processed-service-perminute', nlabel => 'ormrpc.processed.service.countperminute', display_ok => 0, set => {
                key_values => [ { name => 'processed_service_count_per_minute' } ],
                output_template => 'processed service: %s/m',
                perfdatas => [
                    { value => 'processed_service_count_per_minute', template => '%s', min => 0, unit => '/m' },
                ],
            }
        },
        { label => 'clients-invoked', nlabel => 'ormrpc.clients.invoked.count', display_ok => 0, set => {
                key_values => [ { name => 'client_invoke_count', diff => 1 } ],
                output_template => 'clients invoked: %s',
                perfdatas => [
                    { value => 'client_invoke_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'processed-service', nlabel => 'ormrpc.processed.service.count', display_ok => 0, set => {
                key_values => [ { name => 'processed_service_count', diff => 1 } ],
                output_template => 'processed service: %s',
                perfdatas => [
                    { value => 'processed_service_count', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'orm rpc ';
}

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options( arguments => {
        'urlpath:s'  => { name => 'url_path', default => "/easportal/tools/nagios/checkrpc.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
    if ($webcontent !~ /ActiveThreadCount=\d+/i) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find ormrpc status');
        $self->{output}->option_exit();
    }

    $self->{global} = {};
    $self->{global}->{active_thread_count} = $1 if ($webcontent =~ /ActiveThreadCount=(\d+)/mi);
    $self->{global}->{stub_count} = $1 if ($webcontent =~ /StubCount=(\d+)/mi);
    $self->{global}->{proxy_count} = $1 if ($webcontent =~ /ProxyCount=(\d+)/mi);
    $self->{global}->{client_session_count} = $1 if ($webcontent =~ /ClientSessionCount=(\d+)/mi);
    $self->{global}->{server_session_count} = $1 if ($webcontent =~ /ServerSessionCount=(\d+)/mi);
    $self->{global}->{client_invoke_count_per_minute} = $1 if ($webcontent =~ /ClientInvokeCountPerMinute=(\d+)/mi);
    $self->{global}->{processed_service_count_per_minute} = $1 if ($webcontent =~ /ProcessedServiceCountPerMinute=(\d+)/mi);
    $self->{global}->{client_invoke_count} = $1 if ($webcontent =~ /ClientInvokeCount=(\d+)/mi);
    $self->{global}->{processed_service_count}  = $1 if ($webcontent =~ /ProcessedServiceCount=(\d+)/mi);

    $self->{cache_name} = 'kingdee_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check EAS instance orm rpc status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkrpc.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'threads-active', 'stubs', 'proxies', 'sessions-client',
'sessions-server', 'clients-invoke-perminute', 'processed-service-perminute',
'clients-invoked', 'processed-service'.

=back

=cut
