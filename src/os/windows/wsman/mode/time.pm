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

package os::windows::wsman::mode::time;

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

sub get_from_datetime {
    my ($self, %options) = @_;

    my @remote_date = (
        $options{year},
        $options{mounth},
        $options{day},
        $options{hour},
        $options{minute},
        $options{second},
        $options{ms}
    );
    
    my $dt = DateTime->new(
        year      => $remote_date[0],
        month     => $remote_date[1],
        day       => $remote_date[2],
        hour      => $remote_date[3],
        minute    => $remote_date[4],
        second    => $remote_date[5],
        time_zone => 'UTC'
    );

    my $timezone = 'UTC';
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $timezone = $self->{option_results}->{timezone};
        my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
        $dt->set_time_zone($tz->{time_zone});
        @remote_date = ($dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);
    }

    return ($dt->epoch(), \@remote_date, $timezone);
}

sub get_target_time {
    my ($self, %options) = @_;

    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => "Select * from Win32_UTCTime",
        result_type => 'array'
    );

    #
    #CLASS: Win32_UTCTime
    #Day;DayOfWeek;Hour;Milliseconds;Minute;Month;Quarter;Second;WeekInMonth;Year
    #23;4;18;0;56;12;4;45;4;2021
    #

    my ($day, $hour, $minute, $month, $second, $year);
    foreach (@$results) {
       $day = $_->{Day};
       $hour = $_->{Hour};
       $minute = $_->{Minute};
       $month = $_->{Month};
       $second = $_->{Second};
       $year = $_->{Year};
    }

    return $self->get_from_datetime(
        year   => $year, 
        mounth => $month, 
        day    => $day, 
        hour   => $hour, 
        minute => $minute, 
        second => $second
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($distant_time, $remote_date, $timezone) = $self->get_target_time(%options);
    if ($distant_time == 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get system date: local time: 0");
        $self->{output}->option_exit();
    }

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
    my $remote_date_formated = sprintf(
        'Local Time: %02d-%02d-%02dT%02d:%02d:%02d (%s)',
        $remote_date->[0], $remote_date->[1], $remote_date->[2],
        $remote_date->[3], $remote_date->[4], $remote_date->[5], $timezone
    );

    $self->{offset} = {
        offset => sprintf('%d', $offset),
        date => $remote_date_formated
    };
}

1;

__END__

=head1 MODE

Check time offset of server with ntp server. Use local time if ntp-host option is not set. 
SNMP gives a date with second precision (no milliseconds). Time precision is not very accurate.
Use threshold with (+-) 2 seconds offset (minimum).

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

Set the timezone of distant server. For Windows, you need to set it.
Can use format: 'Europe/London' or '+0100'.

=back

=cut
