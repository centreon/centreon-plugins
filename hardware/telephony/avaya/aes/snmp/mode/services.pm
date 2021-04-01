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

package hardware::telephony::avaya::aes::snmp::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_service_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "status: %s [state: '%s'] [license error: '%s']", 
        $self->{result_values}->{status},
        $self->{result_values}->{state},
        $self->{result_values}->{license_error}
    );
    return $msg;
}

sub custom_aep_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "state: %s [link state: '%s']", 
        $self->{result_values}->{session_state},
        $self->{result_values}->{link_state}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'service', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok', skipped_code => { -10 => 1 } },
        { name => 'aep', type => 1, cb_prefix_output => 'prefix_aep_output', message_multiple => 'All AEP connections are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{service} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'state' }, { name => 'license_error' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_service_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'tsapi-clients-connected', nlabel => 'service.tsapi.clients.connected.count', set => {
                key_values => [ { name => 'avAesTsapiClientsConnected' } ],
                output_template => 'client connected: %s',
                perfdatas => [
                    { value => 'avAesTsapiClientsConnected', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'dmcc-memory-usage', nlabel => 'service.dmcc.memory.usage.percentage', set => {
                key_values => [ { name => 'mem_used_prct' } ],
                output_template => 'memory used : %.2f %%',
                perfdatas => [
                    { value => 'mem_used_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{aep} = [
        { label => 'aep-status', threshold => 0, set => {
                key_values => [ { name => 'session_state' }, { name => 'link_state' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_aep_status_output'),
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

sub prefix_aep_output {
    my ($self, %options) = @_;

    return "AEP session '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'         => { name => 'filter_name' },
        'unknown-status:s'      => { name => 'unknown_status', default => '' },
        'warning-status:s'      => { name => 'warning_status', default => '' },
        'critical-status:s'     => { name => 'critical_status', default => '%{state} ne "running" or %{status} ne "online"' },
        'unknown-aep-status:s'  => { name => 'unknown_aep_status', default => '' },
        'warning-aep-status:s'  => { name => 'warning_aep_status', default => '' },
        'critical-aep-status:s' => { name => 'critical_aep_status', default => '%{link_state} ne "online" or %{session_state} ne "online"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'unknown_status', 'warning_status', 'critical_status',
        'unknown_aep_status', 'warning_aep_status', 'critical_aep_status',
    ]);
}

my %map_state = (
    1 => 'ready', 2 => 'running', 3 => 'stopped',
    4 => 'paused', 5 => 'stopping', 6 => 'starting',
    7 => 'unknown', 8 => 'resourceUnavailable',
);
my %map_status = (
    1 => 'resuming', 2 => 'initializing',
    3 => 'online', 4 => 'offline',
    5 => 'pausing', 6 => 'stopping',
    7 => 'down', 8 => 'unknown', 9 => 'resourceUnavailable',
);
my %map_license_error = (
    -1 => 'resourceUnavailable', 0 => 'normal', 1 => 'productNotFound',
    2 => 'featureNotFound', 3 => 'serverConnection', 4 => 'invalidResponse',
    5 => 'invalidRequest', 6 => 'internalError', 7 => 'invalidParameters',
    8 => 'licenseExpired', 9 => 'noLicenseFound', 10 => 'unknownHost',
    11 => 'tryAgain', 12 => 'noRecovery', 13 => 'noData', 14 => 'connectionRefused',
    15 => 'noRouteToHost', 16 => 'authenticationError', 17 => 'incompatibleVersion',
    18 => 'timeout', 19 => 'notLicenseServer', 20 => 'multiSiteInvalid',
    21 => 'serverRestarting', 22 => 'sslConnection', 23 => 'invalidUrl',
    24 => 'invalidProtocol', 99 => 'unknownError', 100 => 'gracePeriodExpired',
    101 => 'invalidLicense', 102 => 'tooManyLicenses', 103 => 'dateTimeError',
);
my %map_aep_link_state = (
    1 => 'offline', 2 => 'online', 3 => 'resourceUnavailable',
);
my $mapping = {
    avAesTransportName      => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.1.1' },
    avAesTransportState     => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.1.2', map => \%map_state },
    avAesTransportStatus    => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.1.3', map => \%map_status },
    avAesCvlanName          => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.2.1' },
    avAesCvlanState         => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.2.2', map => \%map_state },
    avAesCvlanStatus        => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.2.3', map => \%map_status },
    avAesCvlanLicenseError  => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.2.12', map => \%map_license_error },
    avAesTsapiName              => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.3.1' },
    avAesTsapiState             => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.3.2', map => \%map_state },
    avAesTsapiStatus            => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.3.3', map => \%map_status },
    avAesTsapiClientsConnected  => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.3.8' },
    avAesTsapiLicenseError  => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.3.21', map => \%map_license_error },
    avAesDlgName            => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.4.1' },
    avAesDlgState           => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.4.2', map => \%map_state },
    avAesDlgStatus          => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.4.3', map => \%map_status },
    avAesDlgLicenseError    => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.4.10', map => \%map_license_error },
    avAesDmccName           => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.5.1' },
    avAesDmccState          => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.5.2', map => \%map_state },
    avAesDmccStatus         => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.5.3', map => \%map_status },
    avAesDmccUsedMemory     => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.5.6' },
    avAesDmccFreeMemory     => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.5.7' },
    avAesDmccLicenseError   => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.5.20', map => \%map_license_error },
};

my $mapping2 = {
    avAesAepLinkSessSwName  => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.1.6.1.3' },
    avAesAepLinkState       => { oid => '.1.3.6.1.4.1.6889.2.27.2.1.1.6.1.5', map => \%map_aep_link_state },
};
my $oid_avAesAepLinkEntry = '.1.3.6.1.4.1.6889.2.27.2.1.1.6.1';
my $oid_avAesAepSessionState = '.1.3.6.1.4.1.6889.2.27.2.1.1.7.1.4';

sub manage_aep {
    my ($self, %options) = @_;

    $self->{aep} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_avAesAepLinkEntry, start => $mapping2->{avAesAepLinkSessSwName}->{oid}, end => $mapping2->{avAesAepLinkState}->{oid} },
            { oid => $oid_avAesAepSessionState },
        ],
    );

    foreach my $oid (keys %{$snmp_result->{$oid_avAesAepLinkEntry}}) {
        next if ($oid !~ /^$mapping2->{avAesAepLinkSessSwName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_avAesAepLinkEntry}, instance => $instance);
        $self->{aep}->{$result->{avAesAepLinkSessSwName}} = {
            display => $result->{avAesAepLinkSessSwName},
            link_state => $result->{avAesAepLinkState},
        };

        $instance = length($result->{avAesAepLinkSessSwName}) . '.' . join('.', map(ord($_), split('', $result->{avAesAepLinkSessSwName})));
        $self->{aep}->{$result->{avAesAepLinkSessSwName}}->{session_state} = 
            $map_aep_link_state{ $snmp_result->{$oid_avAesAepSessionState}->{$oid_avAesAepSessionState . '.' . $instance} };
    }
}

sub add_service {
    my ($self, %options) = @_;

    return if (!defined($options{display}));
    return if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
        $options{display} !~ /$self->{option_results}->{filter_name}/);
    $self->{service}->{$options{display}} = { %options };
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{service} = {};
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ], nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->add_service(
        display => $result->{avAesTransportName},
        state => $result->{avAesTransportState},
        status => $result->{avAesTransportStatus},
        license_error => 'normal',
    );
    $self->add_service(
        display => $result->{avAesCvlanName},
        state => $result->{avAesCvlanState},
        status => $result->{avAesCvlanStatus},
        license_error => $result->{avAesCvlanLicenseError},
    );
    $self->add_service(
        display => $result->{avAesTsapiName},
        state => $result->{avAesTsapiState},
        status => $result->{avAesTsapiStatus},
        license_error => $result->{avAesTsapiLicenseError},
        avAesTsapiClientsConnected => 
            defined($result->{avAesTsapiClientsConnected}) && $result->{avAesTsapiClientsConnected} != -1 ? $result->{avAesTsapiClientsConnected} : undef,
    );
    $self->add_service(
        display => $result->{avAesDlgName},
        state => $result->{avAesDlgState},
        status => $result->{avAesDlgStatus},
        license_error => $result->{avAesDlgLicenseError},
    );
    $self->add_service(
        display => $result->{avAesDmccName},
        state => $result->{avAesDmccState},
        status => $result->{avAesDmccStatus},
        license_error => $result->{avAesDmccLicenseError},
        mem_used_prct => 
            defined($result->{avAesDmccFreeMemory}) ? (($result->{avAesDmccUsedMemory} * 100) / ($result->{avAesDmccUsedMemory} + $result->{avAesDmccFreeMemory})) : undef
    );

    $self->manage_aep(%options);
}

1;

__END__

=head1 MODE

Check services.

=over 8

=item B<--filter-name>

Filter service name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{state}, %{license_error}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{state}, %{license_error}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} ne "running" or %{status} ne "online"').
Can used special variables like: %{status}, %{state}, %{license_error}, %{display}

=item B<--unknown-aep-status>

Set unknown threshold for status.
Can used special variables like: %{link_state}, %{session_state}, %{display}

=item B<--warning-aep-status>

Set warning threshold for status.
Can used special variables like: %{link_state}, %{session_state}, %{display}

=item B<--critical-aep-status>

Set critical threshold for status (Default: '%{link_state} ne "online" or %{session_state} ne "online"').
Can used special variables like: %{link_state}, %{session_state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tsapi-clients-connected', 'dmcc-memory-usage' (%).

=back

=cut
    
