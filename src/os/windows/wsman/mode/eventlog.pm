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

package os::windows::wsman::mode::eventlog;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'events', nlabel => 'events.total.count', set => {
                key_values => [ { name => 'events' } ],
                output_template => 'Number of event(s): %d',
                perfdatas => [
                    { template => '%d', min => 0 }
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
        'filter-eventid:s' => { name => 'eventId' },
        'filter-source:s'  => { name => 'source' },
        'filter-logfile:s' => { name => 'logfile' },
        'filter-type:s'    => { name => 'type' },
        'timeframe:s'      => { name => 'timeframe', default => 1 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{type}) && $self->{option_results}->{type} ne '' &&
        $self->{option_results}->{type} !~ /^(information|error|critical|warning|verbose)$/) {
        $self->{output}->add_option_msg(short_msg => "Unsupported --type option.");
        $self->{output}->option_exit();
    }
}

sub wmi_to_seconds {
    my ($self, %options) = @_;

    # pass in a WMI Timestamp like 2021-11-04T21:24:11.871719Z
    my $sec = '';
    my $age_sec = ''; 
    my $current_dt = '';
    my $current_sec = '';
    my $tz = '';
    my $timezone_direction = '+';
    my $timezone_offset = 0;

    #                        1      2      3      4      5      6      7     8        9
    if ($options{ts} =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}).(\d*)(\S+)$/) {
        my %ts_info= (
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            nanosecond => $7,
            time_zone  => $8  # set later
        );

        my $dt = DateTime->new(%ts_info);
        $sec = $dt->epoch();
        # force the current time into the same timezone as the queried system
        $current_dt = DateTime->now(time_zone => $dt->time_zone());
        $current_sec = $current_dt->epoch();
        $age_sec = $current_sec - $sec;
    } else {
        $self->{output}->add_option_msg(short_msg => 'Wrong time format');
        $self->{output}->option_exit();
    }
   
    return ($sec, $age_sec);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $dt = DateTime->now;
    $dt = $dt->subtract(hours => $self->{option_results}->{timeframe});
    my $date = sprintf("%d%02d%02d%02d%02d%02d.000000-000", $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);

    my $wql = "SELECT EventCode, SourceName, Type, Logfile, TimeGenerated, Message FROM Win32_NTLogEvent where TimeGenerated > '$date'";

    if (defined($self->{option_results}->{eventId}) && $self->{option_results}->{eventId} ne '') {
        $wql .= " And EventCode = $self->{option_results}->{eventId}";
    }
    if (defined($self->{option_results}->{source}) && $self->{option_results}->{source} ne '') {
        $wql .= " And SourceName = '$self->{option_results}->{source}'"; 
    }
    if (defined($self->{option_results}->{type}) && $self->{option_results}->{type} ne '') {
        $wql .= " And Type = '$self->{option_results}->{type}'";
    }
    if (defined($self->{option_results}->{logfile}) && $self->{option_results}->{logfile} ne '') {
        $wql .= " And Logfile = '$self->{option_results}->{logfile}'";
    }
    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => $wql,
        result_type => 'array'
    );

    $self->{global} = { events => 0 };
    foreach (@$results) {
        my $time_generate = $_->{TimeGenerated};
        my ($time, $diff_time) = $self->wmi_to_seconds(ts => $time_generate);

        $self->{output}->output_add(long_msg =>
           sprintf(
               "[EventID: %d][Type: %s][Logfile: %s][Source: %s][Date: %s][Message: %s]",
               $_->{EventCode},
               $_->{Type},
               $_->{Logfile},
               $_->{SourceName},
               scalar(localtime($time)),
               $_->{Message}
           )
        );
        $self->{global}->{events}++;
    }
}

1;

__END__

=head1 MODE

Check Windoes event logs.

=over 8

=item B<--filter-eventid>

Filter on specific event id.

=item B<--filter-source>

Filter on event log source.

=item B<--filter-logfile>

Filter on specific logfile.
Example: Application, System.

=item B<--filter-type>

Filter on specific type.
Can be: 'information', 'critical', 'warning', 'error', 'verbose'.

=item B<--timeframe>

Time frame to filter events on hour (default: 1).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'events'.

=back

=cut
