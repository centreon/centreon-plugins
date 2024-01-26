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

package storage::hp::p2000::xmlapi::mode::time;

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
        'oid:s'          => { name => 'oid' },
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

    if ($options{date} !~ /^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})$/i) {
        $self->{output}->add_option_msg(short_msg => "unknown date format: $options{date}");
        $self->{output}->option_exit();
    }

    my $timezone = 'UTC';
    if (defined($options{timezone}) && $options{timezone} ne '') {
        $timezone = $options{timezone};
    } elsif (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $timezone = $self->{option_results}->{timezone};
    }
    my $tz = centreon::plugins::misc::set_timezone(name => $timezone);
    
    my $dt = DateTime->new(
        year       => $1,
        month      => $2,
        day        => $3,
        hour       => $4,
        minute     => $5,
        second     => $6,
        %$tz
    );

    my $epoch = $dt->epoch();
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $timezone = $self->{option_results}->{timezone};
        $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
        $dt->set_time_zone($tz->{time_zone}) if (defined($tz->{time_zone}));
    }

    my @remote_date = ($dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);
    return ($dt->epoch(), \@remote_date, $timezone);
}

sub get_target_time {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->get_infos(
        cmd => 'show controller-date', 
        base_type => 'time-settings-table',
        properties_name => '^(?:date-time|time-zone-offset)$'
    );

    if (!defined($result->[0])) {
        $self->{output}->add_option_msg(short_msg => 'cannot get informations');
        $self->{output}->option_exit();
    }

    return $self->get_from_datetime(date => $result->[0]->{'date-time'}, timezone => $result->[0]->{'time-zone-offset'});
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
        'Local Time : %02d-%02d-%02dT%02d:%02d:%02d (%s)',
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

Check time offset (use local time if ntp-host option is not set). 

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

Set the timezone for displaying the date (default: UTC).

=back

=cut
