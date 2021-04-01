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

package network::fortinet::fortimanager::snmp::mode::devicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'device', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok' }
    ];
    
    $self->{maps_counters}->{device} = [
        { label => 'device-status', threshold => 0, set => {
                key_values => [ { name => 'fmDeviceEntState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), 
                closure_custom_calc_extra_options => { output_label => 'Status', name_status => 'fmDeviceEntState' },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'device-con-status', threshold => 0, set => {
                key_values => [ { name => 'fmDeviceEntConnectState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), 
                closure_custom_calc_extra_options => { output_label => 'Connection Status', name_status => 'fmDeviceEntConnectState' },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'device-db-status', threshold => 0, set => {
                key_values => [ { name => 'fmDeviceEntDbState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), 
                closure_custom_calc_extra_options => { output_label => 'DB Status', name_status => 'fmDeviceEntDbState' },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'device-config-status', threshold => 0, set => {
                key_values => [ { name => 'fmDeviceEntConfigState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), 
                closure_custom_calc_extra_options => { output_label => 'Configuration Status', name_status => 'fmDeviceEntConfigState' },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{output_label} . ' : ' . $self->{result_values}->{status};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{output_label} = $options{extra_options}->{output_label};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{name_status}};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'                   => { name => 'filter_name' },
        'warning-device-status:s'         => { name => 'warning_device_status', default => '' },
        'critical-device-status:s'        => { name => 'critical_device_status', default => '' },
        'warning-device-con-status:s'     => { name => 'warning_device_con_status', default => '' },
        'critical-device-con-status:s'    => { name => 'critical_device_con_status', default => '%{status} =~ /down/i' },
        'warning-device-db-status:s'      => { name => 'warning_device_db_status', default => '' },
        'critical-device-db-status:s'     => { name => 'critical_device_db_status', default => '' },
        'warning-device-config-status:s'  => { name => 'warning_device_config_status', default => '' },
        'critical-device-config-status:s' => { name => 'critical_device_config_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => [
        'warning_device_status', 'critical_device_status', 'warning_device_con_status', 'critical_device_con_status',
        'warning_device_db_status', 'critical_device_db_status', 'warning_device_config_status', 'critical_device_config_status'
    ]);
}

sub prefix_device_output {
    my ($self, %options) = @_;
    
    return "Device '" . $options{instance_value}->{display} . "' ";
}

my %map_connection_state = (0 => 'unknown', 1 => 'up', 2 => 'down');
my %map_db_state = (0 => 'unknown', 1 => 'not-modified', 2 => 'modified');
my %map_config_state = (0 =>  'unknown', 1 => 'in-sync', 2 => 'out-of-sync');
my %map_device_state = (
    0 => 'none', 1 => 'unknown', 2 => 'checked-in', 3 => 'in-progress',
    4 => 'installed', 5 => 'aborted', 6 => 'sched', 7 => 'retry', 8 => 'canceled',
    9 => 'pending', 10 => 'retrieved', 11 => 'changed-conf', 12 => 'sync-fail',
    13 => 'timeout', 14 => 'rev-reverted', 15 => 'auto-updated'
);

my $mapping = {
    fmDeviceEntConnectState     => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.12', map => \%map_connection_state },
    fmDeviceEntDbState          => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.13', map => \%map_db_state },
    fmDeviceEntConfigState      => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.14', map => \%map_config_state },
    fmDeviceEntState            => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.15', map => \%map_device_state },
};

my $oid_fmDeviceEntName = '.1.3.6.1.4.1.12356.103.6.2.1.2';
my $oid_fmDeviceEntry = '.1.3.6.1.4.1.12356.103.6.2.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fmDeviceEntName },
            { oid => $oid_fmDeviceEntry, start => $mapping->{fmDeviceEntConnectState}->{oid}, end => $mapping->{fmDeviceEntState}->{oid} },
        ],
        nothing_quit => 1
    );

    $self->{device} = {};
    foreach my $oid (keys %{$snmp_result->{ $oid_fmDeviceEntName }}) {
        $oid =~ /^$oid_fmDeviceEntName\.(.*)$/;
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{ $oid_fmDeviceEntry }, instance => $instance);

        my $name = $snmp_result->{ $oid_fmDeviceEntName }->{$oid};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{device}->{$instance} = { 
            display => $name, %$result
        };
    }

    if (scalar(keys %{$self->{device}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No device found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check device status.

=over 8

=item B<--filter-name>

Filter by device name (can be a regexp).

=item B<--warning-device-status>

Set warning threshold for device status.
Can used special variables like: %{status}, %{display}

=item B<--critical-device-status>

Set critical threshold for device status
Can used special variables like: %{status}, %{display}

=item B<--warning-device-con-status>

Set warning threshold for device connection status.
Can used special variables like: %{status}, %{display}

=item B<--critical-device-con-status>

Set critical threshold for device connection status (Default: '%{status} =~ /down/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-device-db-status>

Set warning threshold for device DB status.
Can used special variables like: %{status}, %{display}

=item B<--critical-device-db-status>

Set critical threshold for device DB status.
Can used special variables like: %{status}, %{display}

=item B<--warning-device-config-status>

Set warning threshold for device configuration status.
Can used special variables like: %{status}, %{display}

=item B<--critical-device-config-status>

Set critical threshold for device configuration status.
Can used special variables like: %{status}, %{display}

=back

=cut
