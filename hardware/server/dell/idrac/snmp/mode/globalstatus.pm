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

package hardware::server::dell::idrac::snmp::mode::globalstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("global status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub custom_storage_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("storage status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_storage_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_storage_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ', ', cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];

     $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'storage-status', threshold => 0, set => {
                key_values => [ { name => 'storage_status' } ],
                closure_custom_calc => $self->can('custom_storage_status_calc'),
                closure_custom_output => $self->can('custom_storage_status_output'),
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
        "unknown-status:s"          => { name => 'unknown_status', default => '%{status} =~ /unknown/' },
        "warning-status:s"          => { name => 'warning_status', default => '%{status} =~ /nonCritical|other/' },
        "critical-status:s"         => { name => 'critical_status', default => '%{status} =~ /critical|nonRecoverable/' },
        "unknown-storage-status:s"  => { name => 'unknown_storage_status', default => '%{status} =~ /unknown/' },
        "warning-storage-status:s"  => { name => 'warning_storage_status', default => '%{status} =~ /nonCritical|other/' },
        "critical-storage-status:s" => { name => 'critical_storage_status', default => '%{status} =~ /critical|nonRecoverable/' },
    });

    return $self;
}


sub prefix_global_output {
    my ($self, %options) = @_;

    return "'" . $self->{global}->{display} . "' : ";
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'unknown_storage_status', 'warning_storage_status', 'critical_storage_status',
         'unknown_status', 'warning_status', 'critical_status',
    ]);
}

my %states = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_racShortName = '.1.3.6.1.4.1.674.10892.5.1.1.2.0';
    my $oid_racVersion = '.1.3.6.1.4.1.674.10892.5.1.1.5.0';
    my $oid_systemModelName = '.1.3.6.1.4.1.674.10892.5.1.3.12.0';
    my $oid_drsGlobalSystemStatus = '.1.3.6.1.4.1.674.10892.2.2.1.0';
    my $oid_globalSystemStatus = '.1.3.6.1.4.1.674.10892.5.2.1.0';
    my $oid_globalStorageStatus = '.1.3.6.1.4.1.674.10892.5.2.3.0';
    my $result = $options{snmp}->get_leef(oids => [
        $oid_racShortName, $oid_racVersion, $oid_systemModelName, $oid_drsGlobalSystemStatus, $oid_globalSystemStatus, $oid_globalStorageStatus
    ], nothing_quit => 1);
    
    my ($global_status, $storage_status);
    if (defined($result->{$oid_globalSystemStatus})) {
        $global_status = $states{$result->{$oid_globalSystemStatus}};
        $storage_status = defined($result->{$oid_globalStorageStatus}) ? $states{$result->{$oid_globalStorageStatus}} : undef;
    } else {
        $global_status = $states{$result->{$oid_drsGlobalSystemStatus}};
    }
    
    my $display = 'unknown';
    $display = $result->{$oid_racShortName}
        if (defined($result->{$oid_racShortName}));
    $display .= '.' . $result->{$oid_racVersion}
        if (defined($result->{$oid_racVersion}));
    $display .= '@' . $result->{$oid_systemModelName}
        if (defined($result->{$oid_systemModelName}));
    $self->{global} = {
        display => $display,
        status => $global_status,
        storage_status => $storage_status,
    };
}

1;

__END__

=head1 MODE

Check the overall status of iDrac card.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /nonCritical|other/').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /critical|nonRecoverable/').
Can used special variables like: %{status}

=item B<--unknown-storage-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/').
Can used special variables like: %{status}

=item B<--warning-storage-status>

Set warning threshold for status (Default: '%{status} =~ /nonCritical|other/').
Can used special variables like: %{status}

=item B<--critical-storage-status>

Set critical threshold for status (Default: '%{status} =~ /critical|nonRecoverable/').
Can used special variables like: %{status}

=back

=cut
    
