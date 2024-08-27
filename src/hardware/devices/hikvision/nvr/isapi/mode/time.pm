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

package hardware::devices::hikvision::nvr::isapi::mode::time;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Time offset %d second(s): %s',
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

    my $result = $options{custom}->request_api(endpoint => '/ISAPI/System/time/capabilities');
    if (!defined($result->{localTime})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find time informations");
        $self->{output}->option_exit();
    }

    if ($result->{localTime} !~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(.*)$/) {
        $self->{output}->add_option_msg(short_msg => "unsupported date format");
        $self->{output}->option_exit();
    }

    my $tz = { time_zone => $7 };
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    }

    my $dt = DateTime->new(
        year => $1,
        month => $2,
        day => $3,
        hour => $4,
        minute => $5,
        second => $6,
        %$tz
    );

    return ($dt->epoch(), $result->{localTime});
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($distant_time, $remote_date) = $self->get_target_time(%options);

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
        offset => sprintf('%d', $offset),
        date => $remote_date
    };
}

1;

__END__

=head1 MODE

Check time offset of server with ntp server. Use local time if ntp-host option is not set.

=over 8

=item B<--warning-offset>

Time offset warning threshold (in seconds).

=item B<--critical-offset>

Time offset critical Threshold (in seconds).

=item B<--ntp-hostname>

Set the ntp hostname (if not set, localtime is used).

=item B<--ntp-port>

Set the ntp port (default: 123).

=item B<--timezone>

Override the timezone of distant equipment.
Can use format: 'Europe/London' or '+0100'.

=back

=cut
