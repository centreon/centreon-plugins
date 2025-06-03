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

package network::cyberoam::snmp::mode::vpnstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status: ' . $self->{result_values}->{connection_status};
    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'VPN ';
}

sub vpn_long_output {
    my ($self, %options) = @_;

    return "checking vpn '" . $options{instance_value}->{display} . "'";
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    my $output = "VPN '" . $options{instance_value}->{display} . "' ";

    if (defined(($options{instance_value}->{vpn_global}->{description}))
        && ($options{instance_value}->{vpn_global}->{description})) {
        $output .= "($options{instance_value}->{vpn_global}->{description}) ";
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'global',
            type             => 0,
            cb_prefix_output => 'prefix_global_output'
        },
        {
            name               => 'vpn',
            type               => 3,
            cb_prefix_output   => 'prefix_vpn_output',
            cb_long_output     => 'vpn_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All VPNs are ok',
            group              => [
                { name => 'vpn_global', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'total',
            type   => 1,
            nlabel => 'vpn.total.count',
            set    => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { label => 'total', template => '%s', min => 0 }
                ]
            }
        },
        {
            label  => 'total-inactive',
            type   => 1,
            nlabel => 'vpn.inactive.count',
            set    => {
                key_values      => [ { name => 'inactive' } ],
                output_template => 'inactive: %s',
                perfdatas       => [
                    { label => 'total_inactive', template => '%s', min => 0 }
                ]
            }
        },
        {
            label  => 'total-active',
            type   => 1,
            nlabel => 'vpn.active.count',
            set    => {
                key_values      => [ { name => 'active' } ],
                output_template => 'active: %s',
                perfdatas       => [
                    { label => 'total_active', template => '%s', min => 0 }
                ]
            }
        },
        {
            label  => 'total-partially-active',
            type   => 1,
            nlabel => 'vpn.partiallyactive.count',
            set    => {
                key_values      => [ { name => 'partiallyActive' } ],
                output_template => 'partially active: %s',
                perfdatas       => [
                    { label => 'total_partially_active', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vpn_global} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{connection_status} =~ /inactive/',
            warning_default  => '%{connection_status} =~ /partiallyActive/',
            set              => {
                key_values                     => [ { name => 'connection_status' }, { name => 'display' }, { name => 'description' } ],
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
        "filter-name:s"            => { name => 'filter_name' },
        "filter-vpn-activated:s"   => { name => 'filter_vpn_activated' },
        "filter-connection-mode:s" => { name => 'filter_connection_mode' },
        "filter-connection-type:s" => { name => 'filter_connection_type' }
    });

    return $self;
}

# SFOS-FIREWALL-MIB::sfosIPSecVpnConnStatus
# sfosIPSecVpnConnStatus OBJECT-TYPE
#   -- FROM	SFOS-FIREWALL-MIB
#   -- TEXTUAL CONVENTION IPSecVPNConnectionStatus
#   SYNTAX	INTEGER {inactive(0), active(1), partially-active(2)}
#   MAX-ACCESS	read-only
#   STATUS	current
#   DESCRIPTION	"Connection status of IPsec tunnel"
# ::= { iso(1) org(3) dod(6) internet(1) private(4) enterprises(1) sophosMIB(2604) sfosXGMIB(5) sfosXGMIBObjects(1) sfosXGTunnelInfo(6) sfosVPNInfo(1) sfosIPSecVPNConnInfo(1) sfosIPSecVpnTunnelTable(1) sfosIPSecVpnTunnelEntry(1) 9 }
my $map_connection_status = {
    0 => 'inactive',
    1 => 'active',
    2 => 'partiallyActive'
};

# SFOS-FIREWALL-MIB::sfosIPSecVpnActivated
# sfosIPSecVpnActivated OBJECT-TYPE
#   -- FROM	SFOS-FIREWALL-MIB
#   -- TEXTUAL CONVENTION IPSecVPNActivationStatus
#   SYNTAX	INTEGER {inactive(0), active(1)}
#   MAX-ACCESS	read-only
#   STATUS	current
#   DESCRIPTION	"Activation status of IPsec tunnel"
# ::= { iso(1) org(3) dod(6) internet(1) private(4) enterprises(1) sophosMIB(2604) sfosXGMIB(5) sfosXGMIBObjects(1) sfosXGTunnelInfo(6) sfosVPNInfo(1) sfosIPSecVPNConnInfo(1) sfosIPSecVpnTunnelTable(1) sfosIPSecVpnTunnelEntry(1) 10 }
my $map_vpn_activated = {
    0 => 'inactive',
    1 => 'active'
};

# SFOS-FIREWALL-MIB::sfosIPSecVpnConnType
# sfosIPSecVpnConnType OBJECT-TYPE
#   -- FROM	SFOS-FIREWALL-MIB
#   -- TEXTUAL CONVENTION IPSecVPNConnectionType
#   SYNTAX	INTEGER {host-to-host(1), site-to-site(2), tunnel-interface(3)}
#   MAX-ACCESS	read-only
#   STATUS	current
#   DESCRIPTION	"Connection Type of IPsec Tunnel"
# ::= { iso(1) org(3) dod(6) internet(1) private(4) enterprises(1) sophosMIB(2604) sfosXGMIB(5) sfosXGMIBObjects(1) sfosXGTunnelInfo(6) sfosVPNInfo(1) sfosIPSecVPNConnInfo(1) sfosIPSecVpnTunnelTable(1) sfosIPSecVpnTunnelEntry(1) 6 }
my $map_connection_type = {
    1 => 'host-to-host',
    2 => 'site-to-site',
    3 => 'tunnel-interface'
};

my $mapping = {
    name            => { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.2' },# sfosIPSecVpnConnName
    connection_mode => { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.5' },# sfosIPSecVpnConnMode
    connection_type => { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.6', map => $map_connection_type },# sfosIPSecVpnConnType
    activated       => { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.10', map => $map_vpn_activated }# sfosIPSecVpnActivated
};

my $mapping_stat = {
    description       => { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.3' },#  sfosIPSecVpnConnDes
    connection_status =>
        { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.9', map => $map_connection_status }#   sfosIPSecVpnConnStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vpn} = {};
    $self->{global} = {
        inactive        => 0,
        active          => 0,
        partiallyActive => 0
    };

    my $request = [ { oid => $mapping->{name}->{oid} } ];
    push @$request, { oid => $mapping->{activated}->{oid} }
        if (defined($self->{option_results}->{filter_vpn_activated}) && $self->{option_results}->{filter_vpn_activated} ne '');

    push @$request, { oid => $mapping->{connection_mode}->{oid} }
        if (defined($self->{option_results}->{filter_connection_mode}) && $self->{option_results}->{filter_connection_mode} ne '');

    push @$request, { oid => $mapping->{connection_type}->{oid} }
        if (defined($self->{option_results}->{filter_connection_type}) && $self->{option_results}->{filter_connection_type} ne '');

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => $request,
        return_type  => 1,
        nothing_quit => 1
    );

    foreach (keys %$snmp_result) {
        next if (!/^$mapping->{name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': not matching name filter.");
            next;
        }

        if (defined($self->{option_results}->{filter_connection_type}) && $self->{option_results}->{filter_connection_type} ne '' &&
            $result->{connection_type} !~ /$self->{option_results}->{filter_connection_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{connection_type} . "': not matching connection-type filter.");
            next;
        }

        if (defined($self->{option_results}->{filter_connection_mode}) && $self->{option_results}->{filter_connection_mode} ne '' &&
            $result->{connection_mode} !~ /$self->{option_results}->{filter_connection_mode}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{connection_mode} . "': not matching connection-mode filter.");
            next;
        }

        if (defined($self->{option_results}->{filter_vpn_activated}) && $self->{option_results}->{filter_vpn_activated} ne '' &&
            $result->{activated} !~ /$self->{option_results}->{filter_vpn_activated}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{activated} . "': not matching vpn-activated filter " . $self->{option_results}->{filter_vpn_activated} . ".");
            next;
        }

        $self->{vpn}->{ $result->{name} } = {
            instance   => $instance,
            display    => $result->{name},
            vpn_global => { display => $result->{name} } };
    }

    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no VPN associated');
        return;
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping_stat)) ],
        instances       => [ map($_->{instance}, values %{$self->{vpn}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{vpn}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping_stat,
            results  => $snmp_result,
            instance => $self->{vpn}->{$_}->{instance});

        $self->{global}->{total}++;
        $self->{global}->{ $result->{connection_status} }++;
        $self->{vpn}->{$_}->{vpn_global}->{connection_status} = $result->{connection_status};
        $self->{vpn}->{$_}->{vpn_global}->{description} = $result->{description};
    }
}

1;

__END__

=head1 MODE

Check VPN status.
VPN-Connection-Status: inactive, active, partiallyActive

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total$|^total-normal$'

=item B<--filter-name>

Filter VPN name (can be a regexp).

=item B<--filter-vpn-activated>

Filter by the activation status of the VPN (can be a regexp).
Values: active, inactive

=item B<--filter-connection-mode>

Filter by the connection mode of the VPN (can be a regexp).

=item B<--connection-type>

Filter by the connection type of the VPN (can be a regexp).
Values: host-to-host, site-to-site, tunnel-interface

=item B<--warning-status>

Trigger warning on %{connection_status} values.
(default: '%{connection_status} =~ /partiallyActive/').

=item B<--critical-status>

Trigger critical on %{connection_status} values.
(default: '%{connection_status} =~ /inactive/').

=item B<--warning-total>

Thresholds.

=item B<--critical-total>

Thresholds.

=item B<--warning-total-inactive>

Thresholds.

=item B<--critical-total-inactive>

Thresholds.

=item B<--warning-total-partially-active>

Thresholds.

=item B<--critical-total-partially-active>

Thresholds.

=item B<--warning-total-active>

Thresholds.

=item B<--critical-total-active>

Thresholds.

=back

=cut
