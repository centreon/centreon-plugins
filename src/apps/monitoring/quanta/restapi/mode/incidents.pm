#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::quanta::restapi::mode::incidents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_output {
    my ($self, %options) = @_;

    return "Incident for interaction '" . $options{instance_value}->{interaction_name} . "' ";
}

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Incidents ';
}

sub custom_duration_output {
    my ($self, %options) = @_;

    if ($self->{result_values}->{status} =~ 'Open') {
        return sprintf(
            'start time: %s, duration: %s',
            $self->{result_values}->{start_time},
            centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration})
        );
    } else {
        return sprintf(
            'start time: %s, end time: %s, duration: %s',
            $self->{result_values}->{start_time},
            $self->{result_values}->{end_time},
            centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration})
        );
    }
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' },
        { name => 'incidents', type => 1, message_multiple => 'No ongoing incident', cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'incidents-total', nlabel => 'quanta.incidents.total.count', set => {
                key_values      => [ { name => 'total' }  ],
                output_template => 'total: %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{incidents} = [
        { label => 'incident-status',
            type => 2,
            warning_default => '',
            critical_default => '%{status} =~ "open"',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'interaction_name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'incident-type',
            type => 2,
            warning_default => '',
            critical_default => '',
            set => {
                key_values => [ { name => 'kind' }, { name => 'display' }, { name => 'interaction_name' } ],
                output_template => 'type: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'incident-duration', nlabel => 'quanta.incident.duration.seconds', set => {
                key_values => [ { name => 'duration' }, { name => 'start_time' }, { name => 'end_time' }, { name => 'status'} ],
                closure_custom_output => $self->can('custom_duration_output'),
		        closure_custom_perfdata => sub { return 0; }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "ignore-closed" => { name => 'ignore_closed' },
        "journey-id:s"  => { name => 'journey_id' },
        "site-id:s"     => { name => 'site_id' },
        "timeframe:s"   => { name => 'timeframe', default => 3600 }
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{journey_id} = (defined($self->{option_results}->{journey_id})) ? $self->{option_results}->{journey_id} : '';
    $self->{site_id} = (defined($self->{option_results}->{site_id})) ? $self->{option_results}->{site_id} : '';
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : '';

    if (!defined($self->{site_id}) || $self->{site_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --site-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{journey_id}) || $self->{journey_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --journey-id option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_configuration_api(
        endpoint    => '/sites/' . $self->{site_id} . '/user_journeys/' . $self->{journey_id} . '/incidents',
        get_param => 'range=' . $self->{timeframe}
    );
    $self->{global}->{total} = 0;
    foreach my $incident (@{$results->{incidents}}) {
        my $kind = ($incident->{kind} =~ s/_/ /gr);
        my $end_time = defined($incident->{end_clock}) ? $incident->{end_clock} : time();
        next if (defined($self->{option_results}->{ignore_closed}) && defined($incident->{end_clock}));
        my $interaction = $options{custom}->list_objects(type => 'interaction', site_id => $self->{site_id}, journey_id => $self->{journey_id}, interaction_id => $incident->{interaction_id});
        $self->{incidents}->{$incident->{id}} = {
            display => $incident->{id},
            kind => $kind,
            interaction_name => $interaction->{interaction}->{name},
            start_time => POSIX::strftime('%d-%m-%Y %H:%M:%S %Z', localtime($incident->{start_clock})),
            end_time => POSIX::strftime('%d-%m-%Y %H:%M:%S %Z', localtime($end_time)),
            duration => $end_time - $incident->{start_clock}
        };
        if (defined($incident->{end_clock})) {
            $self->{incidents}->{$incident->{id}}->{status} = 'closed';
        } else {
            $self->{incidents}->{$incident->{id}}->{status} = 'open';
        }

    $self->{global}->{total}++;
    }
    #use Data::Dumper; print Dumper($self->{incidents}); exit 0;
}

1;

__END__

=head1 MODE

Check Quanta by Centreon overview performance metrics.

=over 8

=item B<--site-id>

Set ID of the site (mandatory option).

=item B<--timeframe>

Set timeframe in seconds (default: 86400).

=item B<--warning-*> B<--critical-*>

Can be: 'total-response-time', 'availability',
'step-response-time'.

=back

=cut
