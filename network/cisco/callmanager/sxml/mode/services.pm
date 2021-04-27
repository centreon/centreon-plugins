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

package network::cisco::callmanager::sxml::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my @list_statuses = (
    'started', 'stopped', 'starting', 'stopping', 'unknown'
);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [reason: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{reason}
    );
}

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Services ';
}

sub prefix_service_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' },
        { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{services} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /starting|started/i and %{reason} !~ /service not activate/i', set => {
                key_values => [ { name => 'status' }, { name => 'reason' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    foreach (@list_statuses) {
       push @{$self->{maps_counters}->{global}}, {
           label => 'services-' . $_, nlabel => 'services.' . $_ . '.count', set => {
                key_values => [ { name => $_ }, { name => 'total' } ],
                output_template => $_ . ': %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

my $map_reason_code = {
    -1 => '--',
    -1000 => 'Component already initialized', -1001 => 'Entry replaced',
    -1002 => 'Component not initialized', -1003 => 'Component is running',
    -1005 => 'Unable to process event', -1006 => 'Registration already present',
    -1007 => 'Unsuccessful completion', -1008 => 'Registration not found',
    -1009 => 'Missing or invalid environment variable', -1010 => 'No such service',
    -1011 => 'Component is reserved for platform', -1012=> 'Bad arguments',
    -1013 => 'Internal error', -1014 => 'Entry was already present',
    -1015 => 'Error opening IPC', -1016 => 'No license available',
    -1017 => 'Error opening file', -1018 => 'Error reading file',
    -1019 => 'Component is not running', -1020 => 'Signal ignored',
    -1021 => 'Notification ignored', -1022 => 'Buffer overflow',
    -1023 => 'Cannot parse', -1024 => 'Out of memory',
    -1025 => 'Not connected', -1026 => 'Component already exists',
    -1027 => 'Message was truncated', -1028 => 'Component is empty',
    -1029 => 'Operation is pending', -1030 => 'Transaction does not exist',
    -1031 => 'Operation timed-out', -1032 => 'File is locked',
    -1033 => 'Feature is not implemented yet',
    -1034 => 'Alarm was already set', -1035 => 'Alarm was already clear',
    -1036 => 'Dependency is in active state', -1037 => 'Dependency is not in active state',
    -1038 => 'Circular dependencies detected', -1039 => 'Component already started',
    -1040 => 'Component already stopped', -1041 => 'Dependencies still pending',
    -1042 => 'Requested process state transition not allowed', -1043 => 'No changes',
    -1044 => 'Boundary violation for data structure', -1045 => 'Operation not supported',
    -1046 => 'Process recovery in progress', -1047 => 'Process recovery in progress',
    -1048 => 'Operation pending on active dependencies', -1049 => 'Operation pending on active dependents',
    -1050 => 'Shutdown is in progress', -1051 => 'Invalid Table Handle',
    -1052 => 'Data Base not initialized', -1053 => 'Data Directory',
    -1054 => 'Table Full', -1055 => 'Deleted Data',
    -1056 => 'No Such Record', -1057 => 'Component already in specified state',
    -1058 => 'Out of range', -1059 => 'Cannot create object',
    -1060 => 'MSO refused, standby system not ready.', -1061 => 'MSO refused, standby state update still in progress. Try again later.',
    -1062 => 'MSO refused, standby state update failed. Verify configuration on standby.', -1063 => 'MSO refused, Warm start-up in progress.',
    -1064 => 'MSO refused, Warm start-up Failed.', -1065 => 'MSO refused, System is not in active state',
    -1066 => 'MSO refused, Detected standalone Flag', -1067 => 'Invalid Token presented in request',
    -1068 => 'Service Not Activated', -1069 => 'Commanded Out of Service',
    -1070 => 'Multiple Modules have error', -1071 => 'Encountered exception',
    -1072 => 'Invalid context path was specified', -1073 => 'No context exists',
    -1074 => 'No context path was specified', -1075 => 'Application already exists'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->cc_get_service_status();

    $self->{global} = { total => 0 };
    $self->{global}->{$_} = 0 foreach (@list_statuses);

    $self->{services} = {};
    foreach (@$results) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping service '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{services}->{ $_->{name} } = {
            name => $_->{name},
            status => $_->{status},
            reason => $map_reason_code->{ $_->{reason_code} }
        };
        $self->{global}->{ $_->{status} }++;
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check services.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter services by name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{reason}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{reason}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /starting|started/i and %{reason} !~ /service not activate/i').
Can used special variables like:  %{status}, %{reason}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'services-started', 'services-stopped', 'services-starting', 'services-stopping', 'services-unknown'.

=back

=cut
