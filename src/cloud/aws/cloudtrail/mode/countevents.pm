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

package cloud::aws::cloudtrail::mode::countevents;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'event-type:s' => { name => 'event_type' },
        'error-message:s' => { name => 'error_message' },
        'delta:s' => { name => 'delta' },
        'warning-count:s'    => { name => 'warning_count' },
        'critical-count:s'   => { name => 'critical_count' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-count', value => $self->{option_results}->{warning_count})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-count threshold '" . $self->{option_results}->{warning_count} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-count', value => $self->{option_results}->{critical_count})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-count threshold '" . $self->{option_results}->{critical_count} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{events} = $options{custom}->cloudtrail_events(
        event_type => $self->{option_results}->{event_type},
        error_message => $self->{option_results}->{error_message},
        delta => $self->{option_results}->{delta}
    );

    my $count;
    if (length($self->{option_results}->{event_type}) || length($self->{option_results}->{error_message})) {
        $count = 0;
        foreach my $event (@{$self->{events}}) {
            if ((length($self->{option_results}->{event_type}) && ($event->{eventType} eq $self->{option_results}->{event_type}))
                || (length($self->{option_results}->{error_message}) && length($event->{errorMessage}) && $event->{errorMessage} =~ $self->{option_results}->{error_message})) {
                $count++;
            }
        }
    } else {
        $count = scalar @{$self->{events}};
    }

    my $exit = $self->{perfdata}->threshold_check(value => $count, threshold => [ { label => 'critical-count', exit_litteral => 'critical' }, { label => 'warning-count', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Number of events: %.2f", $count));
    $self->{output}->perfdata_add(label => "events_count", unit => '',
                                  value => sprintf("%.2f", $count),
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

Check cloudtrail events.

=over 8

=item B<--event-type>

Filter by event type.

=item B<--error-message>

Filter on an error message pattern

=item B<--delta>

Time depth for search (minutes).

=item B<--warning-count>

Set warning threshold for the number of events.

=item B<--critical-count>

Set critical threshold for the number of events.

=back

=cut
