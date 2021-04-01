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

package network::citrix::netscaler::snmp::mode::hastate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_peer_status_output { 
    my ($self, %options) = @_;

    my $msg = sprintf("Peer status is '%s'", $self->{result_values}->{peer_status});
    return $msg;
}

sub custom_ha_status_output { 
    my ($self, %options) = @_;

    my $msg = sprintf(
        "High availibility status is '%s', mode is '%s'", 
        $self->{result_values}->{ha_status},
        $self->{result_values}->{ha_mode},
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'ha-status', set => {
                key_values => [ { name => 'ha_status' }, { name => 'ha_mode' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_ha_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'peer-status', set => {
                key_values => [ { name => 'peer_status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_peer_status_output'),
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
        'unknown-ha-status:s'       => { name => 'unknown_ha_status', default => '%{ha_status} =~ /unknown/i' },
        'warning-ha-status:s'       => { name => 'warning_ha_status', default => '' },
        'critical-ha-status:s'      => { name => 'critical_ha_status', default => '%{ha_status} =~ /down|partialFail|monitorFail|completeFail|partialFailSsl|routemonitorFail/i' },
        'unknown-peer-status:s'     => { name => 'unknown_peer_status', default => '%{peer_status} =~ /unknown/i' },
        'warning-peer-status:s'     => { name => 'warning_peer_status', default => '' },
        'critical-peer-status:s'    => { name => 'critical_peer_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'unknown_peer_status', 'warning_peer_status', 'critical_peer_status',
        'unknown_ha_status', 'warning_ha_status', 'critical_ha_status',
    ]);
}

my $map_ha_status = {
    0 => 'unknown', 1 => 'init', 
    2 => 'down', 3 => 'up', 
    4 => 'partialFail', 5 => 'monitorFail', 
    6 => 'monitorOk', 7 => 'completeFail', 
    8 => 'dumb', 9 => 'disabled', 
    10 => 'partialFailSsl', 11 => 'routemonitorFail',
};

my $map_peer_status = {
    0 => 'standalone', 1 => 'primary', 
    2 => 'secondary', 3 => 'unknown', 
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_sysHighAvailabilityMode = '.1.3.6.1.4.1.5951.4.1.1.6.0';
    my $oid_haPeerState = '.1.3.6.1.4.1.5951.4.1.1.23.3.0';
    my $oid_haCurState = '.1.3.6.1.4.1.5951.4.1.1.23.24.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_sysHighAvailabilityMode, $oid_haPeerState, $oid_haCurState], nothing_quit => 1);

    $self->{global} = {
        peer_status => $map_peer_status->{$snmp_result->{$oid_haPeerState}},
        ha_mode => $map_peer_status->{$snmp_result->{$oid_sysHighAvailabilityMode}},
        ha_status => $map_ha_status->{$snmp_result->{$oid_haCurState}},
    };
}

1;

__END__

=head1 MODE

Check high availability status.

=over 8

=item B<--unknown-ha-status>

Set unknown threshold for status. (Default: '%{ha_status} =~ /unknown/i').
Can use special variables like: %{ha_status}

=item B<--warning-ha-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{ha_status}, %{ha_mode}

=item B<--critical-ha-status>

Set critical threshold for status. (Default: '%{ha_status} =~ /down|partialFail|monitorFail|completeFail|partialFailSsl|routemonitorFail/i').
Can use special variables like: %{ha_status}, %{ha_mode}

=item B<--unknown-peer-status>

Set unknown threshold for status. (Default: '%{peer_status} =~ /unknown/i').
Can use special variables like: %{peer_status}, %{ha_mode}

=item B<--warning-peer-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{peer_status}

=item B<--critical-peer-status>

Set critical threshold for status. (Default: '').
Can use special variables like: %{peer_status}

=back

=cut
    
