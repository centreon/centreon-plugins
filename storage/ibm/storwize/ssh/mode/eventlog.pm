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

package storage::ibm::storwize::ssh::mode::eventlog;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'           => { name => 'warning', },
        'critical:s'          => { name => 'critical', },
        'filter-event-id:s'   => { name => 'filter_event_id'  },
        'filter-message:s'    => { name => 'filter_message' },
        'retention:s'         => { name => 'retention' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

    my $last_timestamp = '';
    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} =~ /^\d+$/) {
        # by default UTC timezone used
        my $dt = DateTime->from_epoch(epoch => time() - $self->{option_results}->{retention});
        my $dt_format = sprintf("%d%02d%02d%02d%02d%02d", substr($dt->year(), 2), $dt->month(), $dt->day(), $dt->hour(), $dt->minute(), $dt->second());
        $last_timestamp = 'last_timestamp>=' . $dt_format . ":";
    }
    $self->{ls_command} = "svcinfo lseventlog -message no -alert yes -filtervalue '${last_timestamp}fixed=no' -delim :";
}

sub run {
    my ($self, %options) = @_;

    my $content = $options{custom}->execute_command(command => $self->{ls_command});
    my $result = $options{custom}->get_hasharray(content => $content, delim => ':');

    my ($num_eventlog_checked, $num_errors) = (0, 0);
    foreach (@$result) {
        $num_eventlog_checked++;
        if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' &&
            $_->{description} !~ /$self->{option_results}->{filter_message}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{description} . "': no matching filter description.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_event_id}) && $self->{option_results}->{filter_event_id} ne '' &&
            $_->{event_id} !~ /$self->{option_results}->{filter_event_id}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{event_id} . "': no matching filter event id.", debug => 1);
            next;
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                '%s : %s - %s', 
                scalar(localtime($_->{last_timestamp})),
                $_->{event_id}, $_->{description}
            )
        );
        $num_errors++;
    }

    $self->{output}->output_add(long_msg => sprintf("Number of message checked: %s", $num_eventlog_checked));
    my $exit = $self->{perfdata}->threshold_check(value => $num_errors, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf("%d problem detected (use verbose for more details)", $num_errors)
    );
    $self->{output}->perfdata_add(
        label => 'problems',
        value => $num_errors,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check eventlogs.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--filter-event-id>

Filter on event id.

=item B<--filter-message>

Filter on event message.

=item B<--retention>

Get eventlog of X last seconds. For the last minutes: --retention=60

=back

=cut
