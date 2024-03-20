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

package centreon::common::monitoring::logs::read;

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc;

sub dump {
    my (%options) = @_;

    return $options{custom}->read();
}

sub parse {
    my (%options) = @_;

    my $parse_mapping;
    foreach (@{$options{parse_mapping}}) {
        next if ($_ !~ /(\S+)=\$(\d+)/);
        $parse_mapping->{'$'.$2} = $1;
    }
    my $date_mapping;
    foreach (@{$options{date_mapping}}) {
        next if ($_ !~ /(\S+)=\$(\d+)/);
        $date_mapping->{'$'.$2} = $1;
    }
    
    my $tz = centreon::plugins::misc::set_timezone(name => $options{timezone});

    my $data = $options{custom}->read();

    my $parsed_data;

    foreach my $line (split /\n/, $data) {
        my $parsed_line;
        next if ($line !~ $options{parse_regexp});
        foreach my $match (keys %{$parse_mapping}) {
            $parsed_line->{$parse_mapping->{$match}} = eval $match;

            if ($parse_mapping->{$match} eq 'date' && defined($options{date_regexp}) && $options{date_regexp} ne '') {
                my $date;
                next if ($parsed_line->{date} !~ $options{date_regexp});
                foreach my $m (keys %{$date_mapping}) {
                    $date->{$date_mapping->{$m}} = eval $m;
                }
                my $dt = DateTime->new(
                    year => $date->{year},
                    month => $date->{month},
                    day => $date->{day},
                    hour => $date->{hour},
                    minute => $date->{minute},
                    second => $date->{second},
                    %$tz
                );
                $parsed_line->{date_parsed} = $date;
                $parsed_line->{date_parsed}->{timestamp} = $dt->epoch;
            }
        }

        push @{$parsed_data}, $parsed_line;
    }

    return $parsed_data;
}

1;

__END__

=head1 MODE

Read and parse logs.

To be used to build modes to retrieve a log file (fashion defined by chosen
custom mode) and parse it with following options :

parse_regexp: regular expression that will parse each log lines and store
capturing groups in $x variables.

parse_mapping: map $x variables with a named key in each entries of the resulted
hash table (can be used multiple times to map all necessary captured groups).

date_regexp: if a date is captured by the first regular expression, this one is
used to capture each part of the date and time.

date_mapping: like for the mapping of the log line captured groups, this option
needs to map each of the following key: year, month, day, hour, minute and
second.

timezone: if the date is captured, one can define its timezone to work with it
for example to cache the timestamp and use a memory code to only look at the
newest log.

Utimately, the %options hash needs to be passed for everything that will make
the custom mode work.

Example:

We want to retrieve 2 values in the last occurrence of a log message. We're not
parsing the date as we will not use it.

use base qw(centreon::plugins::templates::counter);
use centreon::common::monitoring::logs::read;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sessions', nlabel => 'sessions.current.count', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'Current sessions : %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'removed', nlabel => 'sessions.removed.count', set => {
                key_values => [ { name => 'removed' } ],
                output_template => 'Removed sessions : %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $data = centreon::common::monitoring::logs::read::parse(
        %options,
        parse_regexp => '\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3}\s\S{6}\s\{\}\s+\S+\s+\S+\s+(.*)',
        parse_matching => ['message=$1']
    );

    foreach my $entry (reverse @{$data}) {
        next if (defined($entry->{message}) && $entry->{message} ne '' && $entry->{message} !~ /SessionController: checked expiration on (\d+) sessions \(removed (\d+)\)/);
        $self->{global}->{sessions} = $1 - $2;
        $self->{global}->{removed} = $2;
        last;
    }
}

=over 8

=back

=cut
