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

package apps::protocols::tcp::mode::responsetime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use IO::Socket::SSL;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'Connection status on port %s is %s',
        $self->{result_values}->{port},
        $self->{result_values}->{status}
    );
    if ($self->{result_values}->{status} ne 'ok') {
        $msg .= ': ' . $self->{result_values}->{error_message};
    }
    return $msg;
}

sub custom_time_output {
    my ($self, %options) = @_;

    return sprintf(
        "Response time on port %s is %.3fs",
        $self->{result_values}->{port},
        $self->{result_values}->{response_time}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{status} eq "failed"', display_ok => 0, set => {
                key_values => [ { name => 'status' }, { name => 'port' }, { name => 'error_message' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'time', nlabel => 'tcp.response.time.seconds', set => {
                key_values => [ { name => 'response_time' }, { name => 'port' } ],
                closure_custom_output => $self->can('custom_time_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s' => { name => 'hostname' },
        'port:s'     => { name => 'port', },
        'warning:s'  => { name => 'warning', redirect => 'warning-tcp-response-time-seconds' },
        'critical:s' => { name => 'critical', redirect => 'critical-tcp-response-time-seconds' },
        'timeout:s'  => { name => 'timeout', default => 3 },
        'ssl'        => { name => 'ssl' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the hostname option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{port})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the port option');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $connection;
    my $timing0 = [gettimeofday];
    if (defined($self->{option_results}->{ssl})) {
        $connection = IO::Socket::SSL->new(
            PeerAddr => $self->{option_results}->{hostname},
            PeerPort => $self->{option_results}->{port},
            Timeout => $self->{option_results}->{timeout},
        );
    } else {
        $connection = IO::Socket::INET->new(
            PeerAddr => $self->{option_results}->{hostname},
            PeerPort => $self->{option_results}->{port},
            Timeout => $self->{option_results}->{timeout},
        );
    }

    my $timeelapsed = tv_interval($timing0, [gettimeofday]);
    $self->{global} = {
        port => $self->{option_results}->{port},
        status => 'ok',
        response_time => $timeelapsed,
        error_message => ''
    };

    if (!defined($connection)) {
        $self->{global}->{status} = 'failed';
        my $append = '';
        if (defined($!) && $! ne '') {
            $self->{global}->{error_message} = "error=$!";
            $append = ', ';
        }
        $self->{global}->{error_message} .= "${append}ssl_error=$SSL_ERROR" if (defined($SSL_ERROR));
    }

    close($connection) if (defined($connection));
}

1;

__END__

=head1 MODE

Check TCP connection time

=over 8

=item B<--hostname>

IP Addr/FQDN of the host

=item B<--port>

Port used

=item B<--ssl>

Use SSL connection.
(no attempt is made to check the certificate validity by default).

=item B<--timeout>

Connection timeout in seconds (Default: 3)

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{port}, %{error_message}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{port}, %{error_message}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "failed"').
Can used special variables like: %{status}, %{port}, %{error_message}

=item B<--warning-time>

Threshold warning in seconds

=item B<--critical-time>

Threshold critical in seconds

=back

=cut
