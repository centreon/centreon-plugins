#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::cloudfoundry::restapi::mode::appsstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_state_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s'", $self->{result_values}->{state});
    return $msg;
}

sub custom_state_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "App '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'apps', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All apps state are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'started', set => {
                key_values => [ { name => 'started' } ],
                output_template => 'Started : %d',
                perfdatas => [
                    { label => 'started', value => 'started_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'stopped', set => {
                key_values => [ { name => 'stopped' } ],
                output_template => 'Stopped : %d',
                perfdatas => [
                    { label => 'stopped', value => 'stopped_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{apps} = [
        { label => 'state', set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_state_calc'),
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "organization-guid:s"           => { name => 'organization_guid' },
                                    "space-guid:s"                  => { name => 'space_guid' },
                                    "filter-name:s"                 => { name => 'filter_name' },
                                    "warning-state:s"               => { name => 'warning_state' },
                                    "critical-state:s"              => { name => 'critical_state', default => '%{state} !~ /STARTED/i' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_state', 'critical_state']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $apps;
    if (defined($self->{option_results}->{organization_guid}) && $self->{option_results}->{organization_guid} ne '') {
        my $spaces = $options{custom}->get_object(url_path => '/organizations/' . $self->{option_results}->{organization_guid} . '/spaces');
        foreach my $space (@{$spaces}) {
            next if (!defined($space->{entity}->{apps_url}) || $space->{entity}->{apps_url} !~ /^\/v2(.*)/);
            my $result = $options{custom}->get_object(url_path => $1);
            push @{$apps}, @{$result};
        }
    } elsif (defined($self->{option_results}->{space_guid}) && $self->{option_results}->{space_guid} ne '') {
        $apps = $options{custom}->get_object(url_path => '/spaces/' . $self->{option_results}->{space_guid} . '/apps');
    } else {
        $apps = $options{custom}->get_object(url_path => '/apps');
    }

    $self->{global}->{started} = 0;
    $self->{global}->{stopped} = 0;

    foreach my $app (@{$apps}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $app->{entity}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping app '" . $app->{entity}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{apps}->{$app->{metadata}->{guid}} = {
            name => $app->{entity}->{name},
            state => $app->{entity}->{state}
        };
        $self->{global}->{lc($app->{entity}->{state})}++;
    }
    
    if (scalar(keys %{$self->{apps}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Cloud Foundry app state.

=over 8

=item B<--organization-guid>

Only looks for apps from an organization.

=item B<--space-guid>

Only looks for apps from a space.

=item B<--filter-name>

Filter apps name (can be a regexp).

=item B<--warning-state>

Threshold warning.

=item B<--critical-state>

Threshold critical (Default: '%{state} !~ /STARTED/i').

=item B<--warning-*>

Threshold warning for apps count based 
on state (Can be: 'started', 'stopped')

=item B<--critical-*>

Threshold critical for apps count based 
on state (Can be: 'started', 'stopped').

=back

=cut
