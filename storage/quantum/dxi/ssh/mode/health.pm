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

package storage::quantum::dxi::ssh::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return "status is '" . $self->{result_values}->{status} . "' [state = " . $self->{result_values}->{state} . "]";
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Health check '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All health check status are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
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

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /Ready|Success/i' },
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

    my $stdout = $options{custom}->execute_command(command => 'syscli --list healthcheckstatus');
    # Output data:
    #   Healthcheck Status
    #   Total count = 2
    #   [HealthCheck = 1]
    #     Healthcheck Name = De-Duplication
    #     State = enabled
    #     Started = Mon Dec 17 05:00:01 2018
    #     Finished = Mon Dec 17 05:02:01 2018
    #     Status = Success
    #   [HealthCheck = 2]
    #     Healthcheck Name = Integrity
    #     State = disabled
    #     Started =
    #     Finished =
    #     Status = Ready

    $self->{global} = {};
    my $id;
    foreach (split(/\n/, $stdout)) {
        $id = $1 if (/.*\[HealthCheck\s=\s(.*)\]$/i);
        $self->{global}->{$id}->{status} = $1 if (/.*Status\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{state} = $1 if (/.*State\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{name} = $1 if (/.*Healthcheck\sName\s=\s(.*)$/i && defined($id) && $id ne '');
    }
}

1;

__END__

=head1 MODE

Check health status.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{name}, %{status}, %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /Ready|Success/i').
Can used special variables like: %{name}, %{status}, %{state}

=back

=cut
