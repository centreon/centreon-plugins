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

package storage::emc::DataDomain::snmp::mode::process;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_vtl_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "VTL process state: %s [admin state: %s]",
        $self->{result_values}->{vtlProcessState},
        $self->{result_values}->{vtlAdminState}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'nfs-status', type => 2, set => {
                key_values => [
                    { name => 'nfsStatus' }
                ],
                output_template => 'NFS status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cifs-status', type => 2, critical_default => '%{cifsStatus} =~ /enabledNotRunning/', set => {
                key_values => [
                    { name => 'cifsStatus' }
                ],
                output_template => 'CIFS status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'ddboost-status', type => 2, set => {
                key_values => [
                    { name => 'ddboostStatus' }
                ],
                output_template => 'DDBoost status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'vtl-status', type => 2, critical_default => '%{vtlAdminState} =~ /failed/', set => {
                key_values => [
                    { name => 'vtlAdminState' }, { name => 'vtlProcessState' }
                ],
                closure_custom_output => $self->can('custom_vtl_status_output'),
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
    });

    return $self;
}

my $map_nfs_status = { 1 => 'enabled', 2 => 'disabled' };
my $map_ddboost_status = { 1 => 'enabled', 2 => 'disabled' };
my $map_vtl_admin_state = {
    0 => 'unknown',
    1 => 'enabled',
    2 => 'disabled',
    3 => 'failed'
};
my $map_vtl_process_state = {
    0 => 'unknown', 
    1 => 'stopped',
    2 => 'starting',
    3 => 'running',
    4 => 'timingout',
    5 => 'stopping',
    6 => 'stuck'
};
my $map_cifs_status = {
    1 => 'enabled',
    2 => 'enabledRunning',
    3 => 'enabledNotRunning',
    4 => 'enabledWindbindNotRun',
    5 => 'disabled'
};

my $mapping = {
    nfsStatus       => { oid => '.1.3.6.1.4.1.19746.1.9.1.1', map => $map_nfs_status },
    cifsStatus      => { oid => '.1.3.6.1.4.1.19746.1.10.1.1', map => $map_cifs_status },
    vtlAdminState   => { oid => '.1.3.6.1.4.1.19746.1.11.1.1', map => $map_vtl_admin_state },
    vtlProcessState => { oid => '.1.3.6.1.4.1.19746.1.11.1.2', map => $map_vtl_process_state },
    ddboostStatus   => { oid => '.1.3.6.1.4.1.19746.1.12.1.1', map => $map_ddboost_status }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
}

1;

__END__

=head1 MODE

Check process status

=over 8

=item B<--unknown-cifs-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{cifsStatus}

=item B<--warning-cifs-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{cifsStatus}

=item B<--critical-cifs-status>

Define the conditions to match for the status to be CRITICAL (default: '%{cifsStatus} =~ /enabledNotRunning/').
You can use the following variables: %{cifsStatus}

=item B<--unknown-ddboost-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{ddboostStatus}

=item B<--warning-ddboost-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{ddboostStatus}

=item B<--critical-ddboost-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{ddboostStatus}

=item B<--unknown-nfs-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{nfsStatus}

=item B<--warning-nfs-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{nfsStatus}

=item B<--critical-nfs-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{nfsStatus}

=item B<--unknown-vtl-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{vtlAdminState}, %{vtlProcessState}

=item B<--warning-vtl-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{vtlAdminState}, %{vtlProcessState}

=item B<--critical-vtl-status>

Define the conditions to match for the status to be CRITICAL (default: '%{vtlAdminState} =~ /failed/').
You can use the following variables: %{vtlAdminState}, %{vtlProcessState}

=back

=cut
