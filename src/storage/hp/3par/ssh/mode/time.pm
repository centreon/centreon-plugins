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

package storage::hp::3par::ssh::mode::time;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'time offset %d second(s): %s',
        $self->{result_values}->{offset},
        $self->{result_values}->{date}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes time are ok' }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'offset', nlabel => 'node.time.offset.seconds', set => {
                key_values => [ { name => 'offset' }, { name => 'date' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', unit => 's', , label_extra_instance => 1 }
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
        'filter-node-id:s' => { name => 'filter_node_id' },
        'ntp-hostname:s'   => { name => 'ntp_hostname' },
        'ntp-port:s'       => { name => 'ntp_port', default => 123 },
        'timezone:s'       => { name => 'timezone' }
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

    # 2022-01-25 15:55:37 MSK (Europe/Moscow)
    return undef if ($options{date} !~ /^\s*(\d{4})-(\d{2})-(\d{2})\s+(\d+):(\d+):(\d+)\s+\S+\s+\(\S+\)/);

    my $timezone = defined($7) ? $7 : 'UTC';
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
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

    my @remote_date = ($dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);
    return ($dt->epoch(), \@remote_date, $timezone);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(commands => ['showdate']);
    #Node Date
    #0    2022-01-25 15:55:37 MSK (Europe/Moscow)
    #1    2022-01-25 15:55:36 MSK (Europe/Moscow)

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

    $self->{nodes} = {};
    foreach my $line (split(/\n/, $content)) {
        next if ($line !~ /^\s*(\d+)\s+(.*)\s*$/);
        my ($node_id, $date) = ($1, $2);

        next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $node_id !~ /$self->{option_results}->{filter_node_id}/);

        my ($distant_time, $remote_date, $timezone) = $self->get_target_time(date => $date);
        next if (!defined($distant_time));

        my $remote_date_formated = sprintf(
            'local time: %02d-%02d-%02dT%02d:%02d:%02d (%s)',
            $remote_date->[0], $remote_date->[1], $remote_date->[2],
            $remote_date->[3], $remote_date->[4], $remote_date->[5], $timezone
        );
        my $offset = $distant_time - $ref_time;

        $self->{nodes}->{'node' . $node_id} = {
            id => $node_id,
            offset => sprintf('%d', $offset),
            date => $remote_date_formated
        };
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get nodes date");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check nodes time offset (use local time if ntp-host option is not set). 

=over 8

=item B<--filter-node-id>

Filter nodes by ID (can be a regexp).

=item B<--ntp-hostname>

Set the ntp hostname (if not set, localtime is used).

=item B<--ntp-port>

Set the ntp port (default: 123).

=item B<--timezone>

Set the timezone for displaying the date (default: UTC).

=item B<--warning-offset>

Time offset warning threshold (in seconds).

=item B<--critical-offset>

Time offset critical Threshold (in seconds).

=back

=cut
