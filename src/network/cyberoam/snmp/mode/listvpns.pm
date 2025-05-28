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

package network::cyberoam::snmp::mode::listvpns;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s"              => { name => 'filter_name' },
        "filter-connection-status:s" => { name => 'filter_connection_status' },
        "filter-vpn-activated:s"     => { name => 'filter_vpn_activated' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_connection_status = {
        0 => 'inactive',
        1 => 'active',
        2 => 'partially-active'
    };

    my $map_vpn_activated = {
        0 => 'inactive',
        1 => 'active'
    };

    my $map_connection_type = {
        1 => 'host-to-host',
        2 => 'site-to-site',
        3 => 'tunnel-interface'
    };

    my $mapping = {
        name              =>
            { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.2' },# sfosIPSecVpnConnName
        policy            =>
            { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.4' },# sfosIPSecVpnPolicyUsed
        description       =>
            { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.3' },# sfosIPSecVpnConnDes
        connection_mode   =>
            { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.5' },# sfosIPSecVpnConnMode
        connection_type   =>
            { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.6', map => $map_connection_type },# sfosIPSecVpnConnType
        connection_status =>
            { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.9', map => $map_connection_status },# sfosIPSecVpnConnStatus
        activated         =>
            { oid => '.1.3.6.1.4.1.2604.5.1.6.1.1.1.1.10', map => $map_vpn_activated }# sfosIPSecVpnActivated
    };
    # parent oid for all the mapping usage
    my $oid_bsnAPEntry = '.1.3.6.1.4.1.2604.5.1.6.1.1.1';

    my $snmp_result = $options{snmp}->get_table(
        oid   => $oid_bsnAPEntry,
        start => $mapping->{name}->{oid},# First oid of the mapping => here : 2
        end   => $mapping->{activated}->{oid}# Last oid of the mapping => here : 23
    );

    my $results = {};
    # Iterate for all oids catch in snmp result above
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $oid_path = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $oid_path);

        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(long_msg =>
                "skipping VPN '$oid_path': cannot get a name. please set it.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{name} . "': no matching name filter.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_connection_status}) && $self->{option_results}->{filter_connection_status} ne '' &&
            $result->{connection_status} !~ /$self->{option_results}->{filter_connection_status}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{connection_status} . "': no matching connection_status filter.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_vpn_activated}) && $self->{option_results}->{filter_vpn_activated} ne '' &&
            $result->{activated} !~ /$self->{option_results}->{filter_vpn_activated}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{activated} . "': no matching activated filter.",
                debug                            =>
                    1);
            next;
        }

        $results->{$oid_path} = {
            name              => $result->{name},
            policy            => $result->{policy},
            description       => $result->{description},
            connection_mode   => $result->{connection_mode},
            connection_type   => $result->{connection_type},
            connection_status => $result->{connection_status},
            activated         => $result->{activated}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[oid_path: %s] [name: %s] [policy: %s] [description: %s] [connection_mode: %s] [connection_type: %s] [connection_status: %s] [activated: %s]',
                $oid_path,
                $results->{$oid_path}->{name},
                $results->{$oid_path}->{policy},
                $results->{$oid_path}->{description},
                $results->{$oid_path}->{connection_mode},
                $results->{$oid_path}->{connection_type},
                $results->{$oid_path}->{connection_status},
                $results->{$oid_path}->{activated}
            )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List vpn'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements =>
        [ 'name', 'policy', 'description', 'connection_mode', 'connection_type', 'connection_status', 'activated' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name              =>
                $results->{$oid_path}->{name},
            policy            =>
                $results->{$oid_path}->{policy},
            description       =>
                $results->{$oid_path}->{description},
            connection_mode   =>
                $results->{$oid_path}->{connection_mode},
            connection_type   =>
                $results->{$oid_path}->{connection_type},
            connection_status =>
                $results->{$oid_path}->{connection_status},
            activated         =>
                $results->{$oid_path}->{activated}
        );
    }
}

1;

__END__

=head1 MODE

List VPN.

=over 8

=item B<--filter-name>

Display VPN matching the filter.

=item B<--filter-connection-status>

Display VPN matching the filter.

=item B<--filter-vpn-activated>

Display VPN matching the filter.

=back

=cut
