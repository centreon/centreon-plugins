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

package database::oracle::mode::eventwaitsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'event_count', type => 0 },
        { name => 'event', type => 1, cb_prefix_output => 'prefix_event_output', message_multiple => 'All event waits are OK', skipped_code => { -11 => 1, -10 => 1 } },
    ];


    $self->{maps_counters}->{event_count} = [
        { label => 'event-count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Event Wait Count : %s events',
                perfdatas => [
                    { label => 'event_wait_count', template => '%s', min => 0 }
                ],
            }
        },
    ];
    $self->{maps_counters}->{event} = [
        { label => 'total-waits-sec', set => {
                key_values => [ { name => 'total_waits', per_second => 1 }, { name => 'display' } ],
                output_template => 'Total Waits : %.2f/s',
                perfdatas => [
                    { label => 'total_waits', template => '%.2f',
                      unit => '/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-waits-time', set => {
                key_values => [ { name => 'time_waited_micro', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                output_template => 'Total Waits Time : %.2f %%', output_use => 'prct_wait', threshold_use => 'prct_wait',
                perfdatas => [
                    { label => 'total_waits_time', value => 'prct_wait', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
   ],
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_time_waited_micro'} - $options{old_datas}->{$self->{instance} . '_time_waited_micro'};
    $self->{result_values}->{prct_wait} = 100 * ($delta_total / 1000000) / $options{delta_time};

    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'   => { name => 'filter_name' },
        'wait-time-min:s' => { name => 'wait_time_min', default => 1000 },
        'show-details'    => { name => 'show_details' }
    });

    return $self;
}

sub prefix_event_output {
    my ($self, %options) = @_;

    return "Event '" . $options{instance_value}->{display} . "' ";
}

sub event_count_and_details {
    my ($self, %options) = @_;

    my $query_count = "SELECT count(*) as NB
        FROM v\$session
        WHERE  WAIT_TIME_MICRO>" . $self->{option_results}->{wait_time_min} . "
        AND status='ACTIVE' and WAIT_CLASS <>'Idle'";

    $self->{sql}->query(query => $query_count);
    my $result = $self->{sql}->fetchrow_hashref();

    $self->{event_count}->{count} = $result->{NB};

    if (defined($self->{option_results}->{show_details})) {
        my $query_details = "SELECT
                                 a.username USERNAME,
                                 a.program PROGRAM,
                                 a.event EVENT,
                                 round(a.WAIT_TIME_MICRO/1000000,0) SEC_WAIT,
                                 d.sql_text SQL_TEXT
                             FROM
                                 v\$session a,
                                 v\$sqlstats d
                             WHERE
                                 a.sql_id = d.sql_id
                                 and a.status='ACTIVE'
                                 and a.wait_class <> 'Idle'
                                 and WAIT_TIME_MICRO>" . $self->{option_results}->{wait_time_min} . "
                                 and a.sid not in (SELECT SID FROM V\$SESSION WHERE audsid = userenv('SESSIONID'))
                             ORDER BY
                                a.WAIT_TIME_MICRO desc";
                                
        $self->{sql}->query(query => $query_details );
        while (my $result = $self->{sql}->fetchrow_hashref()) {
            $self->{output}->output_add(long_msg => sprintf("Username: '%s', Program: '%s' Event: '%s', Second wait: '%s's, Details: '%s'\n",
                                                         $result->{USERNAME}, $result->{PROGRAM}, $result->{EVENT}, $result->{SEC_WAIT}, $result->{SQL_TEXT}));
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query = q{
        SELECT e.event#, e.name,
                NVL(s.total_waits, 0), NVL(s.total_timeouts, 0), NVL(s.time_waited, 0),
                NVL(s.time_waited_micro, 0), NVL(s.average_wait, 0)
          FROM v$event_name e LEFT JOIN sys.v_$system_event s ON e.name = s.event
        };
    if ($self->{sql}->is_version_minimum(version => '10')) {
        $query = q{
            SELECT e.event_id, e.name,
                NVL(s.total_waits, 0), NVL(s.total_timeouts, 0), NVL(s.time_waited, 0),
                NVL(s.time_waited_micro, 0), NVL(s.average_wait, 0)
            FROM v$event_name e LEFT JOIN sys.v_$system_event s ON e.name = s.event
        };
    }

    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    $self->{event} = {};
    foreach my $row (@$result) {
        my ($name, $total_waits, $time_waited_micro) = ($row->[1], $row->[2], $row->[5]);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{event}->{$name} = {
            display => $name,
            total_waits => $total_waits,
            time_waited_micro => $time_waited_micro
        };
    }

    if ($self->{sql}->is_version_minimum(version => '10')) {
        $self->event_count_and_details();
    }

    $self->{sql}->disconnect();

    if (scalar(keys %{$self->{event}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No event found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "oracle_" . $self->{mode} . '_' . $self->{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

}

1;

__END__

=head1 MODE

Check Oracle event wait usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total-waits-sec', 'total-waits-time', 'event-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-waits-sec', 'total-waits-time', 'event-count'.

=item B<--filter-name>

Filter by event name. Can be a regex.

=item B<--wait-time-min>

Time in ms above which we count an event as waiting

=item B<--show-details>

Print details of waiting events (user, query, ...) in long output

=back

=cut
