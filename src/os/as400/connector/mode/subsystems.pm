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

package os::as400::connector::mode::subsystems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_jobs_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{name}, $self->{result_values}->{library}],
        value => $self->{result_values}->{jobs_active},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub prefix_subsys_output {
    my ($self, %options) = @_;

    return sprintf(
        "Subsystem '%s' [library: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{library}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Subsystems ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 }  },
        { name => 'subsys', type => 1, cb_prefix_output => 'prefix_subsys_output', message_multiple => 'All subsystems are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'subsystems-total', nlabel => 'subsystems.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    foreach ('active', 'ending', 'inactive', 'restricted', 'starting') {
        push @{$self->{maps_counters}->{global}},
            { label => 'subsystems-' . $_, nlabel => 'subsystems.' . $_ . '.count', set => {
                    key_values => [ { name => $_ }, { name => 'total' } ],
                    output_template => $_ . ': %s',
                    perfdatas => [
                        { template => '%s', min => 0, max => 'total' }
                    ]
                }
            };
    }

    $self->{maps_counters}->{subsys} = [
         {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /ending|restricted|starting/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'library' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'jobs-active', nlabel => 'subsystem.jobs.active.count', set => {
                key_values => [ { name => 'jobs_active' }, { name => 'name' }, { name => 'library' } ],
                output_template => 'current active jobs: %s',
                 closure_custom_perfdata => $self->can('custom_jobs_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'include-subsystem-name:s'    => { name => 'include_subsystem_name' },
        'filter-subsystem-name:s'     => { redirect => 'include_subsystem_name' },
        'include-subsystem-library:s' => { name => 'include_subsystem_library' },
        'filter-subsystem-library:s'  => { redirect => 'include_subsystem_library' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{uuid} = '';
    foreach ('filter_counters', 'include_subsystem_name', 'include_subsystem_library') {
        if (defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne '') {
            $self->{uuid} .= $self->{option_results}->{$_};
        }
    }
}

my $map_subsys_status = {
    '*ACTIVE' => 'active', 
    '*ENDING' => 'ending', 
    '*INACTIVE' => 'inactive', 
    '*RESTRICTED' => 'restricted', 
    '*STARTING' => 'starting'
};

sub manage_selection {
    my ($self, %options) = @_;

    my %cmd = (command => 'listSubsystems', args => {});
    if ($self->{uuid} ne '') {
        $cmd{args}->{uuid} = $self->{uuid};
    }
    my $subsys = $options{custom}->request_api(%cmd);

    $self->{global} = { total => 0, active => 0, ending => 0, inactive => 0, restricted => 0, starting => 0 };
    $self->{subsys} = {};
    foreach my $entry (@{$subsys->{result}}) {
        if (defined($self->{option_results}->{include_subsystem_name}) && $self->{option_results}->{include_subsystem_name} ne '' &&
            $entry->{name} !~ /$self->{option_results}->{include_subsystem_name}/) {
            $self->{output}->output_add(long_msg => "skipping subsystem '" . $entry->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{include_subsystem_library}) && $self->{option_results}->{include_subsystem_library} ne '' &&
            $entry->{library} !~ /$self->{option_results}->{include_subsystem_library}/) {
            $self->{output}->output_add(long_msg => "skipping subsystem '" . $entry->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{subsys}->{ $entry->{name} . ':' . $entry->{library} } = {
            name => $entry->{name},
            library => $entry->{library},
            status => $map_subsys_status->{ $entry->{status} },
            jobs_active => $entry->{currentActiveJobs}
        };

        $self->{global}->{ $map_subsys_status->{ $entry->{status} } }++;
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check subsystems.

=over 8

=item B<--include-subsystem-name>

Filter subsystems by name (can be a regexp).

=item B<--include-subsystem-library>

Filter subsystems by library (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}, %{library}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /ending|restricted|starting/i').
You can use the following variables: %{status}, %{name}, %{library}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{name}, %{library}

=item B<--warning-jobs-active>

Threshold.

=item B<--critical-jobs-active>

Threshold.

=item B<--warning-subsystems-active>

Threshold.

=item B<--critical-subsystems-active>

Threshold.

=item B<--warning-subsystems-ending>

Threshold.

=item B<--critical-subsystems-ending>

Threshold.

=item B<--warning-subsystems-inactive>

Threshold.

=item B<--critical-subsystems-inactive>

Threshold.

=item B<--warning-subsystems-restricted>

Threshold.

=item B<--critical-subsystems-restricted>

Threshold.

=item B<--warning-subsystems-starting>

Threshold.

=item B<--critical-subsystems-starting>

Threshold.

=item B<--warning-subsystems-total>

Threshold.

=item B<--critical-subsystems-total>

Threshold.

=back

=cut
