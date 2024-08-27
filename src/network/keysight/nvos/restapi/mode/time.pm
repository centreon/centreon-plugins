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

package network::keysight::nvos::restapi::mode::time;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'time offset %d second(s): %s',
        $self->{result_values}->{offset},
        $self->{result_values}->{date}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'offset', type => 0 }
    ];

    $self->{maps_counters}->{offset} = [
        {
            label => 'ntp-status',
            type => 2,
            critical_default => '%{status} !~ /in_reach|in_sync/i',
            set => {
                key_values => [ { name => 'status' } ],
                output_template => 'ntp status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'offset', nlabel => 'time.offset.seconds', set => {
                key_values => [ { name => 'offset' }, { name => 'date' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', unit => 's' }
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
        'ntp-hostname:s' => { name => 'ntp_hostname' },
        'ntp-port:s'     => { name => 'ntp_port', default => 123 },
        'timezone:s'     => { name => 'timezone' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
   
    if (defined($self->{option_results}->{ntp_hostname})) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'Net::NTP',
            error_msg => "Cannot load module 'Net::NTP'."
        );
    }
}

sub get_target_time {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        endpoint => '/api/system',
        get_param => ['properties=system_time,ntp_server_status']
    );
    if (!defined($result->{system_time})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find time informations");
        $self->{output}->option_exit();
    }

    my $tz = {};
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    }

    my $dt = DateTime->from_epoch(epoch => $result->{system_time} / 1000, %$tz);

    return ($dt->epoch(), $dt->iso8601(), $result->{ntp_server_status});
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($distant_time, $remote_date, $ntp_status) = $self->get_target_time(%options);

    my $ref_time;
    if (defined($self->{option_results}->{ntp_hostname}) && $self->{option_results}->{ntp_hostname} ne '') {
        my %ntp;

        eval {
            %ntp = Net::NTP::get_ntp_response($self->{option_results}->{ntp_hostname}, $self->{option_results}->{ntp_port});
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Couldn't connect to ntp server: " . $@);
            $self->{output}->option_exit();
        }

        $ref_time = $ntp{'Transmit Timestamp'};
    } else {
        $ref_time = time();
    }

    my $offset = $distant_time - $ref_time;
    $self->{offset} = {
        status => lc($ntp_status),
        offset => sprintf('%d', $offset),
        date => $remote_date
    };
}

1;

__END__

=head1 MODE

Check time offset of server with ntp server. Use local time if ntp-host option is not set.

=over 8

=item B<--unknown-ntp-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-ntp-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-ntp-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /in_reach|in_sync/i')
You can use the following variables: %{status}

=item B<--warning-offset>

Define the time offset (in seconds) that will trigger a WARNING status.

=item B<--critical-offset>

Define the time offset (in seconds) that will trigger a CRITICAL status.

=item B<--ntp-hostname>

Set the NTP hostname (if not set, localtime is used).

=item B<--ntp-port>

Set the NTP port (default: 123).

=item B<--timezone>

Override the timezone of distant equipment.
Can use format: 'Europe/London' or '+0100'.

=back

=cut
