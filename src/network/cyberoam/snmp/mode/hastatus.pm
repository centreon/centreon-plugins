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

package network::cyberoam::snmp::mode::hastatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "HA is '" . $self->{result_values}->{hastatus} . "' - ";
    $msg .= "Current HA State: '" . $self->{result_values}->{hastate} . "' - ";
    $msg .= "Peer HA State: '" . $self->{result_values}->{peer_hastate} . "' - ";
    $msg .= "HA Port: '" . $self->{result_values}->{ha_port} . "' - ";
    $msg .= "HA IP: '" . $self->{result_values}->{ha_ip} . "' - ";
    $msg .= "Peer IP: '" . $self->{result_values}->{ha_peer_ip} . "'";
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
            { name => 'ha', type => 0 },
    ];

    $self->{maps_counters}->{ha} = [
        {
            label     => 'status',
            type      => 2,
            set       => {
                key_values => [
                    { name => 'hastate' },
                    { name => 'hastatus' },
                    { name => 'peer_hastate' },
                    { name => 'ha_port' },
                    { name => 'ha_ip' },
                    { name => 'ha_peer_ip' }
                ],
                default_critical               => '%{hastatus} =~ /^enabled$/ && %{hastate} =~ /^faulty$/',
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
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
        'no-ha-status:s' => { name => 'no_ha_status', default => 'UNKNOWN' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [ 'warning_status', 'critical_status' ]);
}
# snmptranslate -Td .1.3.6.1.4.1.2604.5.1.4.1.0
# SFOS-FIREWALL-MIB::sfosHAStatus.0
# sfosHAStatus OBJECT-TYPE
#   -- FROM	SFOS-FIREWALL-MIB
#   -- TEXTUAL CONVENTION HaStatusType
#   SYNTAX	INTEGER {disabled(0), enabled(1)}
#   MAX-ACCESS	read-only
#   STATUS	current
#   DESCRIPTION	" "
# ::= { iso(1) org(3) dod(6) internet(1) private(4) enterprises(1) sophosMIB(2604) sfosXGMIB(5) sfosXGMIBObjects(1) sfosXGHAStats(4) sfosHAStatus(1) 0 }

my %map_status = (
    0 => 'disabled',
    1 => 'enabled'
);

# snmptranslate -Td .1.3.6.1.4.1.2604.5.1.4.4.0
# SFOS-FIREWALL-MIB::sfosDeviceCurrentHAState.0
# sfosDeviceCurrentHAState OBJECT-TYPE
#   -- FROM	SFOS-FIREWALL-MIB
#   -- TEXTUAL CONVENTION HaState
#   SYNTAX	INTEGER {notapplicable(0), auxiliary(1), standAlone(2), primary(3), faulty(4), ready(5)}
#   MAX-ACCESS	read-only
#   STATUS	current
#   DESCRIPTION	"HA State of current Device"
# ::= { iso(1) org(3) dod(6) internet(1) private(4) enterprises(1) sophosMIB(2604) sfosXGMIB(5) sfosXGMIBObjects(1) sfosXGHAStats(4) sfosDeviceCurrentHAState(4) 0 }

my %map_state = (
    0 => 'notapplicable',
    1 => 'auxiliary',
    2 => 'standAlone',
    3 => 'primary',
    4 => 'faulty',
    5 => 'ready'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ha_status = '.1.3.6.1.4.1.2604.5.1.4.1.0';
    my $oid_ha_state = '.1.3.6.1.4.1.2604.5.1.4.4.0';
    my $oid_peer_ha_state = '.1.3.6.1.4.1.2604.5.1.4.5.0';
    my $oid_ha_port = '.1.3.6.1.4.1.2604.5.1.4.8.0';
    my $oid_ha_ip = '.1.3.6.1.4.1.2604.5.1.4.9.0';
    my $oid_ha_peer_ip = '.1.3.6.1.4.1.2604.5.1.4.10.0';

    $self->{ha} = {};

    my $result = $options{snmp}->get_leef(
        oids         =>
            [ $oid_ha_status, $oid_ha_state, $oid_peer_ha_state, $oid_ha_port, $oid_ha_ip, $oid_ha_peer_ip ],
        nothing_quit =>
            1
    );

    if ($result->{$oid_ha_status} == 0 or $result->{$oid_ha_state} == 0) {
        $self->{output}->output_add(
            severity  => $self->{option_results}->{no_ha_status},
            short_msg => sprintf("Looks like HA is not enabled, or not applicable .."),
            long_msg  => sprintf(
                "HA Enabled : '%u' HA Status : '%s'",
                $map_status{$result->{$oid_ha_status}}, $map_status{$result->{$oid_ha_state}}
            ),
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    $self->{ha} = {
        hastatus     => $map_status{$result->{$oid_ha_status}},
        hastate      => $map_state{$result->{$oid_ha_state}},
        peer_hastate => $map_state{$result->{$oid_peer_ha_state}},
        ha_port      => $result->{$oid_ha_port},
        ha_ip        => $result->{$oid_ha_ip},
        ha_peer_ip   => $result->{$oid_ha_peer_ip}
    };
}

1;

__END__

=head1 MODE

Check current HA-State.
HA-States: notapplicable, auxiliary, standAlone, primary, faulty, ready

=over 8

=item B<--warning-status>

Trigger warning on %{hastatus} or %{hastate} or %{peer_hastate} values.

=item B<--critical-status>

Trigger critical on %{hastatus} or %{hastate} or %{peer_hastate} values.
(default: '%{hastatus} =~ /^enabled$/ && %{hastate} =~ /^faulty$/').

=item B<--no-ha-status>

Status to return when HA not running or not installed (default: 'UNKNOWN').

=back

=cut
