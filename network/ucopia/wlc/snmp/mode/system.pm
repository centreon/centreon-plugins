#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::ucopia::wlc::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_service_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("status is %s", 
        $self->{result_values}->{status},
    );
    return $msg;
}

sub custom_ha_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("high-availablity status is %s", 
        $self->{result_values}->{ha_status},
    );
    return $msg;
}

sub custom_users_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%d connected users (Available licence: %s)", 
        $self->{result_values}->{connected_users},
        $self->{result_values}->{max_users} ne '' ? $self->{result_values}->{max_users} : '-'
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
        { name => 'service', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'users-connected', nlabel => 'system.users.connected.count', set => {
                key_values => [ { name => 'connected_users' }, { name => 'max_users' } ],
                closure_custom_output => $self->can('custom_users_output'),
                perfdatas => [
                    { value => 'connected_users', template => '%s', min => 0, max => 'max_users' },
                ],
            }
        },
        { label => 'users-connected-prct', nlabel => 'system.users.connected.percentage', display_ok => 0, set => {
                key_values => [ { name => 'connected_users_prct' } ],
                output_template => 'users connected: %.2f %%',
                perfdatas => [
                    { value => 'connected_users_prct', template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'ha-status', threshold => 0, set => {
                key_values => [ { name => 'ha_status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_ha_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'disk-temperature', nlabel => 'system.disk.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'disk_temperature', no_value => 0 } ],
                output_template => 'disk temperature: %s C',
                perfdatas => [
                    { value => 'disk_temperature', template => '%s', unit => 'C' },
                ],
            }
        },
        { label => 'cpu-temperature', nlabel => 'system.cpu.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'cpu_temperature', no_value => 0 } ],
                output_template => 'cpu temperature: %s C',
                perfdatas => [
                    { value => 'cpu_temperature', template => '%s', unit => 'C' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{service} = [
         { label => 'service-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_service_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-service-status:s'  => { name => 'warning_service_status', default => '' },
        'critical-service-status:s' => { name => 'critical_service_status', default => '%{status} eq "stopped"' },
        'warning-ha-status:s'       => { name => 'warning_ha_status', default => '' },
        'critical-ha-status:s'      => { name => 'critical_ha_status', default => '%{ha_status} eq "fault"' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_service_status', 'critical_service_status',
        'warning_ha_status', 'critical_ha_status',
    ]);
}

my $map_sc_status = { 1 => 'running', 2 => 'stopped', 3 => 'disabled' };
my $map_ha_status = { 0 => 'standalone', 1 => 'master', 2 => 'active', 3 => 'passive', 4 => 'fault' };

my $mapping = {
    totalConnectedUsers => { oid => '.1.3.6.1.4.1.31218.3.1' },
    cpuTemperature      => { oid => '.1.3.6.1.4.1.31218.3.3' },
    diskTemperature     => { oid => '.1.3.6.1.4.1.31218.3.4' },
    licenseUsers        => { oid => '.1.3.6.1.4.1.31218.3.5' },
    highAvailabilityStatus  => { oid => '.1.3.6.1.4.1.31218.3.7', map => $map_ha_status },
};

my $mapping2 = {
    webServer           => { oid => '.1.3.6.1.4.1.31218.4.1', map => $map_sc_status },
    sqlServer           => { oid => '.1.3.6.1.4.1.31218.4.2', map => $map_sc_status },
    urlSniffer          => { oid => '.1.3.6.1.4.1.31218.4.3', map => $map_sc_status },
    portal              => { oid => '.1.3.6.1.4.1.31218.4.4', map => $map_sc_status },
    webProxy            => { oid => '.1.3.6.1.4.1.31218.4.5', map => $map_sc_status },
    autodisconnect      => { oid => '.1.3.6.1.4.1.31218.4.6', map => $map_sc_status },
    printingServer      => { oid => '.1.3.6.1.4.1.31218.4.7', map => $map_sc_status },
    dhcpServer          => { oid => '.1.3.6.1.4.1.31218.4.8', map => $map_sc_status },
    dnsServer           => { oid => '.1.3.6.1.4.1.31218.4.9', map => $map_sc_status },
    staticIpManager     => { oid => '.1.3.6.1.4.1.31218.4.10', map => $map_sc_status },
    highAvailability    => { oid => '.1.3.6.1.4.1.31218.4.11', map => $map_sc_status },
    ldapDirectory           => { oid => '.1.3.6.1.4.1.31218.4.12', map => $map_sc_status },
    ldapReplicationManager  => { oid => '.1.3.6.1.4.1.31218.4.13', map => $map_sc_status },
    timeServer          => { oid => '.1.3.6.1.4.1.31218.4.14', map => $map_sc_status },
    radiusServer        => { oid => '.1.3.6.1.4.1.31218.4.15', map => $map_sc_status },
    samba               => { oid => '.1.3.6.1.4.1.31218.4.16', map => $map_sc_status },
    ssh                 => { oid => '.1.3.6.1.4.1.31218.4.17', map => $map_sc_status },
    syslog              => { oid => '.1.3.6.1.4.1.31218.4.18', map => $map_sc_status },
    usersLog            => { oid => '.1.3.6.1.4.1.31218.4.19', map => $map_sc_status },
    pmsClient           => { oid => '.1.3.6.1.4.1.31218.4.20', map => $map_sc_status },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)), map($_->{oid} . '.0', values(%$mapping2)) ], nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->{global} = {
        ha_status => $result->{highAvailabilityStatus},
        disk_temperature => $result->{diskTemperature},
        cpu_temperature => $result->{cpuTemperature},
        connected_users => $result->{totalConnectedUsers},
        max_users => defined($result->{licenseUsers}) ? $result->{licenseUsers} : '',
        connected_users_prct => defined($result->{licenseUsers}) && $result->{licenseUsers} != 0 ? $result->{totalConnectedUsers} * 100 / $result->{licenseUsers} : undef
    };

    $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => '0');
    $self->{service} = {};
    foreach (keys %$result) {
        $self->{service}->{$_} = { display => $_, status => $result->{$_} };
    }
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='service-status'

=item B<--warning-service-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-service-status>

Set critical threshold for status (Default: '%{status} eq "stopped"').
Can used special variables like:  %{status}, %{display}

=item B<--warning-ha-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{ha_status}

=item B<--critical-ha-status>

Set critical threshold for status (Default: '%{ha_status} eq "fault"').
Can used special variables like:  %{ha_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'users-connected', 'users-connected-prct', 
'disk-temperature', 'cpu-temperature'.

=back

=cut
