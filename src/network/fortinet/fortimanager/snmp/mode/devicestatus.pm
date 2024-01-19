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

package network::fortinet::fortimanager::snmp::mode::devicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{output_label} . ': ' . $self->{result_values}->{status};
}

sub device_long_output {
    my ($self, %options) = @_;

    return "checking device '" . $options{instance_value}->{name} . "'";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device '" . $options{instance_value}->{name} . "' ";
}

sub prefix_pp_output {
    my ($self, %options) = @_;

    return "policy package '" . $options{instance_value}->{package_name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'con_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'db_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'config_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'packages', display_long => 1, cb_prefix_output => 'prefix_pp_output', message_multiple => 'policy packages are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{status} = [
        { label => 'device-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{con_status} = [
        { label => 'device-con-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'connection status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{db_status} = [
        { label => 'device-db-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'db status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{config_status} = [
        { label => 'device-config-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'configuration status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{packages} = [
        { label => 'device-policy-package-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'package_name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
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
    connectState       => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.12', map => \%map_connection_state }, # fmDeviceEntConnectState
    dbState            => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.13', map => \%map_db_state }, # fmDeviceEntDbState
    configState        => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.14', map => \%map_config_state }, # fmDeviceEntConfigState
    state              => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.15', map => \%map_device_state }, # fmDeviceEntState
    policyPackageState => { oid => '.1.3.6.1.4.1.12356.103.6.2.1.23' } # fmDeviceEntPolicyPackageState
};
my $oid_fmDeviceEntName = '.1.3.6.1.4.1.12356.103.6.2.1.2';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_fmDeviceEntName,
        nothing_quit => 1
    );

    $self->{devices} = {};
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_fmDeviceEntName\.(.*)$/;
        my $instance = $1;

        my $name = $snmp_result->{$oid};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{devices}->{$instance} = {
            name => $name,
            status => { name => $name },
            con_status => { name => $name },
            db_status => { name => $name },
            config_status => { name => $name },
            packages => {}
        };
    }

    if (scalar(keys %{$self->{devices}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No device found.');
        $self->{output}->option_exit();
    }

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [ map($_, keys(%{$self->{devices}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{devices}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        $self->{devices}->{$_}->{status}->{status} = $result->{state};
        $self->{devices}->{$_}->{con_status}->{status} = $result->{connectState};
        $self->{devices}->{$_}->{config_status}->{status} = $result->{configState};
        $self->{devices}->{$_}->{db_status}->{status} = $result->{dbState};
        if (defined($result->{policyPackageState}) && $result->{policyPackageState}) {
            foreach my $entry (split(/\|/, $result->{policyPackageState})) {
                next if ($entry !~ /\s*(.*?)\[(.*?)\]/);
                $self->{devices}->{$_}->{packages}->{$1} = {
                    package_name => $1,
                    status => $2
                };
            }
        }        
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
You can use the following variables: %{status}, %{name}

=item B<--critical-device-status>

Set critical threshold for device status
You can use the following variables: %{status}, %{name}

=item B<--warning-device-con-status>

Set warning threshold for device connection status.
You can use the following variables: %{status}, %{name}

=item B<--critical-device-con-status>

Set critical threshold for device connection status (default: '%{status} =~ /down/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-device-db-status>

Set warning threshold for device DB status.
You can use the following variables: %{status}, %{name}

=item B<--critical-device-db-status>

Set critical threshold for device DB status.
You can use the following variables: %{status}, %{name}

=item B<--warning-device-config-status>

Set warning threshold for device configuration status.
You can use the following variables: %{status}, %{name}

=item B<--critical-device-config-status>

Set critical threshold for device configuration status.
You can use the following variables: %{status}, %{name}

=item B<--warning-device-policy-package-status>

Set warning threshold for device policy package status.
You can use the following variables: %{status}, %{package_name}

=item B<--critical-device-policy-package-status>

Set critical threshold for device policy package status.
You can use the following variables: %{status}, %{package_name}

=back

=cut
