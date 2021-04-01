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

package centreon::common::cisco::ironport::xmlapi::mode::systemusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::http;
use XML::Simple;
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'system status: ' . $self->{result_values}->{system_status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{system_status} = $options{new_datas}->{$self->{instance} . '_system_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
         { label => 'system-status', threshold => 0, set => {
                key_values => [ { name => 'system_status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'memory', nlabel => 'system.memory.usage.percentage', set => {
                key_values => [ { name => 'ram_utilization' } ],
                output_template => 'memory usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'cpu-total', nlabel => 'system.cpu.total.utilization.percentage', set => {
                key_values => [ { name => 'total_utilization' } ],
                output_template => 'total cpu usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'diskio', nlabel => 'system.disk.io.usage.percentage', set => {
                key_values => [ { name => 'disk_utilization' } ],
                output_template => 'disk i/o usage: %.2f %%',
                perfdatas => [
                    {  template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'log', nlabel => 'system.logging.disk.usage.percentage', set => {
                key_values => [ { name => 'log_used' } ],
                output_template => 'logging disk usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'resource-conservation', nlabel => 'system.resource.conservation.current.count', set => {
                key_values => [ { name => 'resource_conservation' } ],
                output_template => 'resource conservation mode: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ],
            }
        },
        { label => 'connections-in', nlabel => 'system.connections.inbound.current.count', set => {
                key_values => [ { name => 'conn_in' } ],
                output_template => 'current inbound connections: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ],
            }
        },
        { label => 'connections-out', nlabel => 'system.connections.outbound.current.count', set => {
                key_values => [ { name => 'conn_out' } ],
                output_template => 'current outbound connections: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ],
            }
        },
        { label => 'queue-active-recipients', nlabel => 'system.queue.recipients.active.current.count', set => {
                key_values => [ { name => 'active_recips' } ],
                output_template => 'queue active recipients: %s',
                perfdatas => [
                    { value => 'active_recips', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-quarantine', nlabel => 'system.queue.messages.quarantine.current.count', set => {
                key_values => [ { name => 'msgs_in_quarantine' } ],
                output_template => 'messages in quarantine: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-workqueue', nlabel => 'system.queue.messages.workqueue.current.count', set => {
                key_values => [ { name => 'msgs_in_work_queue' } ],
                output_template => 'messages in work queue: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-received', nlabel => 'system.queue.messages.received.persecond', set => {
                key_values => [ { name => 'msgs_received_lifetime', per_second => 1 } ],
                output_template => 'messages received: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0 },
                ],
            }
        },
        { label => 'queuedisk', nlabel => 'system.queue.disk.usage.percentage', set => {
                key_values => [ { name => 'queuedisk' } ],
                output_template => 'queue disk usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname' },
        'port:s'        => { name => 'port', },
        'proto:s'       => { name => 'proto', default => 'https' },
        'urlpath:s'     => { name => 'url_path', default => "/xml/status" },
        'username:s'    => { name => 'username' },
        'password:s'    => { name => 'password' },
        'timeout:s'     => { name => 'timeout' },
        'unknown-http-status:s'     => { name => 'unknown_http_status' },
        'warning-http-status:s'     => { name => 'warning_http_status' },
        'critical-http-status:s'    => { name => 'critical_http_status' },
        'warning-system-status:s'   => { name => 'warning_system_status', default => '' },
        'critical-system-status:s'  => { name => 'critical_system_status', default => '%{system_status} !~ /online/i' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{username}) || $self->{option_results}->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{password}) || $self->{option_results}->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify password option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{curl_opt})) {
        $self->{option_results}->{curl_opt} = ['CURLOPT_SSL_VERIFYPEER => 0'];
    }
    if (!defined($self->{option_results}->{ssl_opt})) {
        $self->{option_results}->{ssl_opt} = ['SSL_verify_mode => SSL_VERIFY_NONE'];
    }

    $self->{option_results}->{credentials} = 1;
    $self->{http}->set_options(%{$self->{option_results}});
    $self->change_macros(macros => ['warning_system_status', 'critical_system_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $self->{http}->request(
        unknown_status => $self->{option_results}->{unknown_http_status},
        warning_status => $self->{option_results}->{warning_http_status},
        critical_status => $self->{option_results}->{critical_http_status},
    );

    my $xml_result;
    eval {
        $xml_result = XMLin($content,
            ForceArray => [],
            KeyAttr => [], 
            SuppressEmpty => ''
        );
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    $self->{global} = {
        system_status => $xml_result->{system}->{status},
    };
    foreach (@{$xml_result->{gauges}->{gauge}}) {
        $self->{global}->{$_->{name}} = $_->{current};
    }
    foreach (@{$xml_result->{counnters}->{counter}}) {
        $self->{global}->{$_->{name} . '_lifetime'} = $_->{lifetime};
    }

    $self->{global}->{queuedisk} = $self->{global}->{kbytes_used} * 100 / ($self->{global}->{kbytes_used} + $self->{global}->{kbytes_free});
    $self->{cache_name} = "cisco_ironport_" . $self->{option_results}->{hostname}  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--hostname>

IP Address or FQDN of the webserver host

=item B<--port>

Port used.

=item B<--proto>

Protocol used http or https (Default: https)

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/xml/status')

=item B<--username>

Specify username for authentication

=item B<--password>

Specify password for authentication

=item B<--timeout>

Threshold for HTTP timeout

=item B<--unknown-http-status>

Threshold unknown for http response code (Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-http-status>

Threshold warning for http response code

=item B<--critical-http-status>

Threshold critical for http response code

=item B<--warning-system-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{system_status}

=item B<--critical-system-status>

Set critical threshold for status (Default: '%{system_status} !~ /online/i').
Can used special variables like: %{system_status}

=item B<--warning-*> B<--critical-*> 

Warning threshold.
Can be: 'memory' (%), 'cpu-total' (%), 'diskio' (%), 'log' (%), 'resource-conservation',
'connections-in', 'connections-out', 'queue-active-recipients', 'messages-quarantine',
'messages-workqueue', 'queuedisk' (%), 'messages-received'.

=back

=cut
