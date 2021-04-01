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

package cloud::kubernetes::mode::clusterevents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_event_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{object} = $options{new_datas}->{$self->{instance} . '_object'};
    $self->{result_values}->{message} = $options{new_datas}->{$self->{instance} . '_message'};
    $self->{result_values}->{count} = $options{new_datas}->{$self->{instance} . '_count'};
    $self->{result_values}->{first_seen_time} = $options{new_datas}->{$self->{instance} . '_first_seen'};
    $self->{result_values}->{last_seen_time} = $options{new_datas}->{$self->{instance} . '_last_seen'};
    # 2021-03-09T11:01:00Z, UTC timezone
    if ($self->{result_values}->{first_seen_time} =~ /^\s*(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6
        );
        $self->{result_values}->{first_seen} = time() - $dt->epoch;
    }
    if ($self->{result_values}->{last_seen_time} =~ /^\s*(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6
        );
        $self->{result_values}->{last_seen} = time() - $dt->epoch;
    }

    return 0;
}

sub custom_event_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Event '%s' for object '%s' with message '%s'",
        $self->{result_values}->{type},
        $self->{result_values}->{object},
        $self->{result_values}->{message}
    );
    $msg .= sprintf(", Count: %s, First seen: %s ago (%s), Last seen: %s ago (%s)",
        $self->{result_values}->{count},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{first_seen}),
        $self->{result_values}->{first_seen_time},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{last_seen}),
        $self->{result_values}->{last_seen_time}
    ) if (defined($self->{result_values}->{count}) && $self->{result_values}->{count} ne '');

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Number of events ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'events', type => 1 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'warning', nlabel => 'events.type.warning.count', set => {
                key_values => [ { name => 'warning' } ],
                output_template => 'Warning : %d',
                perfdatas => [
                    { label => 'warning_events', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'normal', nlabel => 'events.type.normal.count', set => {
                key_values => [ { name => 'normal' } ],
                output_template => 'Normal : %d',
                perfdatas => [
                    { label => 'normal_events', template => '%d', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{events} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{type} =~ /warning/i',
            critical_default => '%{type} =~ /error/i',
            set => {
                key_values => [
                    { name => 'object' }, { name => 'count' }, { name => 'first_seen' }, { name => 'last_seen' },
                    { name => 'message' }, { name => 'reason' }, { name => 'type' }
                ],
                closure_custom_calc => $self->can('custom_event_calc'),
                closure_custom_output => $self->can('custom_event_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-type:s"         => { name => 'filter_type' },
        "filter-namespace:s"    => { name => 'filter_namespace' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{events} = {};

    my $results = $options{custom}->kubernetes_list_events();

    $self->{global} = { normal => 0, warning => 0 };
    
    foreach my $event (@{$results}) {
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $event->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $event->{type} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_namespace}) && $self->{option_results}->{filter_namespace} ne '' &&
            $event->{metadata}->{namespace} !~ /$self->{option_results}->{filter_namespace}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $event->{metadata}->{namespace} . "': no matching filter namespace.", debug => 1);
            next;
        }

        $self->{global}->{lc($event->{type})}++;
        
        $self->{events}->{$event->{metadata}->{uid}} = {
            name => $event->{metadata}->{name},
            namespace => $event->{metadata}->{namespace},
            object => $event->{involvedObject}->{kind} . "/" . $event->{involvedObject}->{name},
            count => (defined($event->{count})) ? $event->{count} : "",
            first_seen => (defined($event->{firstTimestamp})) ? $event->{firstTimestamp} : "",
            last_seen => (defined($event->{lastTimestamp})) ? $event->{lastTimestamp} : "",
            message => $event->{message},
            reason => $event->{reason},
            type => $event->{type}
        }
    }
}

1;

__END__

=head1 MODE

Check cluster events.

=over 8

=item B<--filter-type>

Filter event type (can be a regexp).

=item B<--filter-namespace>

Filter namespace (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{type} =~ /warning/i')
Can use special variables like: %{name}, %{namespace}, %{type},
%{object}, %{message}, %{count}, %{first_seen}, %{last_seen}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{type} =~ /error/i').
Can use special variables like: %{name}, %{namespace}, %{type},
%{object}, %{message}, %{count}, %{first_seen}, %{last_seen}.

=back

=cut
