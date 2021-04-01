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

package cloud::cloudfoundry::restapi::mode::instancesstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_app_state_output {
    my ($self, %options) = @_;

    return sprintf(
        "App '%s' state is '%s'",
        $self->{result_values}->{name}, $self->{result_values}->{state}
    );
}

sub custom_inst_state_output {
    my ($self, %options) = @_;

    return sprintf("state is '%s'", $self->{result_values}->{state});
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Instance '" . $options{instance_value}->{id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'app', type => 0 },
        { name => 'global', type => 0 },
        { name => 'instances', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All instances state are ok' },
    ];

    $self->{maps_counters}->{app} = [
        { label => 'app-state', type => 2, critical_default => '%{state} !~ /STARTED/i', set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_app_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check =>  \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'running', nlabel => 'instances.running.count', set => {
                key_values => [ { name => 'running' } ],
                output_template => 'Running : %d',
                perfdatas => [
                    { label => 'running', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'stopped', nlabel => 'instances.stopped.count', set => {
                key_values => [ { name => 'stopped' } ],
                output_template => 'Stopped : %d',
                perfdatas => [
                    { label => 'stopped', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'crashed', nlabel => 'instances.crashed.count', set => {
                key_values => [ { name => 'crashed' } ],
                output_template => 'Crashed : %d',
                perfdatas => [
                    { label => 'crashed', template => '%d', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{instances} = [
        { label => 'instance-state', type => 2, critical_default => '%{state} !~ /RUNNING/i', set => {
                key_values => [ { name => 'state' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_inst_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_inst_state_threshold'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'app-guid:s' => { name => 'app_guid' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{app_guid}) || $self->{option_results}->{app_guid} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify app-guid option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $app = $options{custom}->get_object(url_path => '/apps/' . $self->{option_results}->{app_guid});

    $self->{app}->{name} = $app->{entity}->{name};
    $self->{app}->{state} = $app->{entity}->{state};

    if ($self->{app}->{state} =~ /^STARTED$/) {
        $self->{global}->{running} = 0;
        $self->{global}->{stopped} = 0;
        $self->{global}->{crashed} = 0;

        my $instances = $options{custom}->get_object(url_path => '/apps/' . $self->{option_results}->{app_guid} . '/stats');

        foreach my $instance (keys %{$instances}) {
            $self->{instances}->{$instance} = {
                id => $instance,
                state => $instances->{$instance}->{state},
            };
            $self->{global}->{lc($instances->{$instance}->{state})}++;
        }
    }
}

1;

__END__

=head1 MODE

Check Cloud Foundry app state and instances usage.

=over 8

=item B<--app-guid>

App guid to look for.

=item B<--warning-app-state>

Threshold warning for app state.

=item B<--critical-app-state>

Threshold critical for app state (Default: '%{state} !~ /STARTED/i').

=item B<--warning-instance-state>

Threshold warning for instances state.

=item B<--critical-instance-state>

Threshold critical for instances state (Default: '%{state} !~ /RUNNING/i').

=item B<--warning-*>

Threshold warning for instances count based 
on state (Can be: 'running', 'stopped', 'crashed')

=item B<--critical-*>

Threshold critical for instances count based 
on state (Can be: 'running', 'stopped', 'crashed').

=back

=cut
