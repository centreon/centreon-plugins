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

package apps::oracle::ovm::api::mode::manager;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_manager_output {
    my ($self, %options) = @_;
    
    return "Manager '" . $options{instance_value}->{name} . "' ";
}

sub prefix_jobs_output {
    my ($self, %options) = @_;
    
    return 'Jobs ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'manager', type => 0, cb_prefix_output => 'prefix_manager_output', skipped_code => { -10 => 1 } },
        { name => 'jobs', type => 0, cb_prefix_output => 'prefix_jobs_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{manager} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /running/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{jobs} = [
        { label => 'jobs-succeeded', nlabel => 'manager.jobs.succeeded.count', set => {
                key_values => [ { name => 'success' }, { name => 'name' } ],
                output_template => 'succeeded: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'jobs-failed', nlabel => 'manager.jobs.failed.count', set => {
                key_values => [ { name => 'failure' }, { name => 'name' } ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $manager = $options{custom}->request_api(endpoint => '/Manager');
    my $jobs = $options{custom}->request_api(endpoint => '/Job');

    my $name = $manager->[0]->{id}->{value};
    $name = $manager->[0]->{name}
        if (defined($manager->[0]->{name}) && $manager->[0]->{name} ne '');

    $self->{manager} = {
        name => $name,
        status => lc($manager->[0]->{managerRunState})
    };

    $self->{jobs} = {
        name => $name,
        success => 0,
        failure => 0
    };
    foreach (@$jobs) {
        $self->{jobs}->{ lc($_->{jobSummaryState}) }++
            if (defined($self->{jobs}->{ lc($_->{jobSummaryState}) }));
    }
}

1;

__END__

=head1 MODE

Check manager.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /running/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'jobs-succeeded', 'jobs-failed'.

=back

=cut
