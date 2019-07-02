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

package storage::avid::isis::snmp::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("System Director state is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_SystemDirectorState'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'SystemDirectorState' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'redistributing-count', set => {
                key_values => [ { name => 'WorkspaceRedistributingCount' } ],
                output_template => 'Workspace redistributing count: %d',
                perfdatas => [
                    { label => 'redistributing_count', value => 'WorkspaceRedistributingCount_absolute',
                      template => '%d', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '%{status} !~ /Online/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    0 => 'Online',
    1 => 'Offline',
    2 => 'Standby',
    3 => 'Unknown',
);

my $oid_SystemDirectorState = '.1.3.6.1.4.1.526.20.2.1.0';
my $oid_WorkspaceRedistributingCount = '.1.3.6.1.4.1.526.20.2.4.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(oids => [ $oid_SystemDirectorState, $oid_WorkspaceRedistributingCount ], 
                                               nothing_quit => 1);
    
    $self->{global} = {};

    $self->{global} = { 
        SystemDirectorState => $map_status{$results->{$oid_SystemDirectorState}},
        WorkspaceRedistributingCount => $results->{$oid_WorkspaceRedistributingCount},
    };
}

1;

__END__

=head1 MODE

Check System Director state and workspaces redistributing count.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{state}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{state} !~ /Online/i').
Can use special variables like: %{state}

=item B<--warning-redistributing-count>

Threshold warning for number of workspaces redistributing.

=item B<--critical-redistributing-count>

Threshold critical for number of workspaces redistributing.

=back

=cut
