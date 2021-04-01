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

package centreon::common::cisco::standard::snmp::mode::vpc;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_keepalive_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{keepalive_status}
    );
}

sub custom_peer_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'role: %s',
        $self->{result_values}->{role}
    );
}

sub custom_peer_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{role_last} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub custom_link_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'operational status: %s',
        $self->{result_values}->{link_status}
    );
}

sub domain_long_output {
    my ($self, %options) = @_;

    return "checking vPC domain '" . $options{instance_value}->{domain_id} . "'";
}

sub prefix_domain_output {
    my ($self, %options) = @_;

    return "vPC domain '" . $options{instance_value}->{domain_id} . "' ";
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "host link '" . $options{instance_value}->{display} . "' ";
}

sub prefix_peer_output {
    my ($self, %options) = @_;

    return "peer '" . $options{instance_value}->{macaddress} . "' ";
}

sub prefix_keepalive_output {
    my ($self, %options) = @_;

    return 'keepalive ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'domains', type => 3, cb_prefix_output => 'prefix_domain_output', cb_long_output => 'domain_long_output', indent_long_output => '    ', message_multiple => 'All vPC domains are ok',
            group => [
                { name => 'peer', type => 0, cb_prefix_output => 'prefix_peer_output', skipped_code => { -10 => 1 } },
                { name => 'keepalive', type => 0, cb_prefix_output => 'prefix_keepalive_output', skipped_code => { -10 => 1 } },
                { name => 'hosts', display_long => 1, cb_prefix_output => 'prefix_host_output',  message_multiple => 'All host links are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{peer} = [
        {
            label => 'peer-status',
            type => 2,
            critical_default => '%{role} ne %{role_last}',
            set => {
                key_values => [ { name => 'role' }, { name => 'domain_id' } ],
                closure_custom_calc => $self->can('custom_peer_status_calc'),
                closure_custom_output => $self->can('custom_peer_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'host-links-up', nlabel => 'vpc.host.links.up.count', display_ok => 0, set => {
                key_values => [ { name => 'links_up' }, { name => 'links_total' } ],
                output_template => 'host links up: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'links_total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'host-links-down', nlabel => 'vpc.host.links.down.count', display_ok => 0, set => {
                key_values => [ { name => 'links_down' }, { name => 'links_total' } ],
                output_template => 'host links down: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'links_total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'host-links-downstar', nlabel => 'vpc.host.links.downstar.count', display_ok => 0, set => {
                key_values => [ { name => 'links_downstar' }, { name => 'links_total' } ],
                output_template => 'host links downstar: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'links_total', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{keepalive} = [
        {
            label => 'keepalive-status',
            type => 2,
            critical_default => '%{keepalive_status} ne "alive"',
            set => {
                key_values => [ { name => 'keepalive_status' }, { name => 'domain_id' } ],
                closure_custom_calc => $self->can('custom_keepalive_status_calc'),
                closure_custom_output => $self->can('custom_keepalive_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'keepalive-messages-sent', nlabel => 'vpc.keepalive.messages.sent.count', display_ok => 0, set => {
                key_values => [ { name => 'keepalive_sent', diff => 1 } ],
                output_template => 'messages sent: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'keepalive-messages-received', nlabel => 'vpc.keepalive.messages.received.count', display_ok => 0, set => {
                key_values => [ { name => 'keepalive_received', diff => 1 } ],
                output_template => 'messages received: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{hosts} = [
        {
            label => 'link-status',
            type => 2,
            warning_default => '%{link_status} =~ /downStar/i',
            critical_default => '%{link_status} eq "down"',
            set => {
                key_values => [ { name => 'link_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping_role = {
    1 => 'primarySecondary', 2 => 'primary',
    3 => 'secondaryPrimary', 4 => 'secondary',
    5 => 'noneEstablished'
};
my $mapping_keepalive_status = {
    1 => 'disabled', 2 => 'alive',
    3 => 'peerUnreachable', 4 => 'aliveButDomainIdDismatch',
    5 => 'suspendedAsISSU', 6 => 'suspendedAsDestIPUnreachable',
    7 => 'suspendedAsVRFUnusable', 8 => 'misconfigured'
};
my $mapping_link_status = {
    1 => 'down', 2 => 'downStar', 3 => 'up'
};

my $mapping = {
    role       => { oid => '.1.3.6.1.4.1.9.9.807.1.2.1.1.2', map => $mapping_role }, # cVpcRoleStatus
    macaddress => { oid => '.1.3.6.1.4.1.9.9.807.1.2.1.1.5' } # cVpcSystemOperMacAddress
};
my $mapping2 = {
    keepalive_status   => { oid => '.1.3.6.1.4.1.9.9.807.1.1.2.1.2', map => $mapping_keepalive_status }, # cVpcPeerKeepAliveStatus
    keepalive_sent     => { oid => '.1.3.6.1.4.1.9.9.807.1.3.1.1.2' }, # cVpcStatsPeerKeepAliveMsgsSent
    keepalive_received => { oid => '.1.3.6.1.4.1.9.9.807.1.3.1.1.3' }  # cVpcStatsPeerKeepAliveMsgsRcved
};
my $mapping3 = {
    if_index    => { oid => '.1.3.6.1.4.1.9.9.807.1.4.2.1.3' }, # cVpcStatusHostLinkIfIndex
    link_status => { oid => '.1.3.6.1.4.1.9.9.807.1.4.2.1.4', map => $mapping_link_status } # cVpcStatusHostLinkStatus
};
my $oid_cVpcRoleEntry = '.1.3.6.1.4.1.9.9.807.1.2.1.1';
my $oid_cVpcStatsPeerKeepAliveEntry = '.1.3.6.1.4.1.9.9.807.1.3.1.1';
my $oid_cVpcStatusHostLinkEntry = '.1.3.6.1.4.1.9.9.807.1.4.2.1';
my $oid_ifName = '.1.3.6.1.2.1.31.1.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cVpcRoleEntry, start => $mapping->{role}->{oid}, end => $mapping->{macaddress}->{oid} },
            { oid => $oid_cVpcStatusHostLinkEntry, start => $mapping3->{if_index}->{oid}, end => $mapping3->{link_status}->{oid} }
        ],
        nothing_quit => 1
    );

    $self->{domains} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_cVpcRoleEntry}}) {
        next if ($oid !~ /^$mapping->{role}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_cVpcRoleEntry}, instance => $1);
        my $domain_id = $1;

        $self->{domains}->{$domain_id} = {
            domain_id => $domain_id,
            peer => {
                domain_id => $domain_id,
                role => $result->{role},
                macaddress => $result->{macaddress},
                links_up => 0,
                links_down => 0,
                links_downstar => 0,
                links_total => 0
            },
            keepalive => {},
            hosts => {}
        };
    }

    my $if_indexes = {};
    foreach (keys %{$snmp_result->{$oid_cVpcStatusHostLinkEntry}}) {
        next if (!/^$mapping3->{link_status}->{oid}\.(\d+)\.(\d+)/);
        my ($domain_id, $vpc_id) = ($1, $2);
        next if (!defined($self->{domains}->{$domain_id}));

        my $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_cVpcStatusHostLinkEntry}, instance => $domain_id . '.' . $vpc_id);

        $if_indexes->{ $result->{if_index} } = 1;
        $self->{domains}->{$domain_id}->{hosts}->{ $result->{if_index} } = {
            display => $result->{if_index},
            link_status => $result->{link_status}
        };
        $self->{domains}->{$domain_id}->{peer}->{links_total}++;
        $self->{domains}->{$domain_id}->{peer}->{'links_' . lc($result->{link_status})}++;
    }

    # get interface name
    $options{snmp}->load(
        oids => [ $oid_ifName ],
        instances => [keys %$if_indexes],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach my $domain_id (keys %{$self->{domains}}) {
        foreach my $if_index (keys %{$self->{domains}->{$domain_id}->{hosts}}) {
            next if (
                !defined($snmp_result->{ $oid_ifName . '.' . $if_index }) ||
                $snmp_result->{ $oid_ifName . '.' . $if_index } eq ''
            );
            $self->{domains}->{$domain_id}->{hosts}->{$if_index}->{display} = $snmp_result->{ $oid_ifName . '.' . $if_index };
        }
    }

    # Keepalive part
    $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cVpcStatsPeerKeepAliveEntry, start => $mapping2->{keepalive_sent}->{oid}, end => $mapping2->{keepalive_received}->{oid} },
            { oid => $mapping2->{keepalive_status}->{oid} }
        ],
        return_type => 1
    );
    foreach (keys %$snmp_result) {
        next if (!/^$mapping2->{keepalive_status}->{oid}\.(\d+)/);
        my $domain_id = $1;
        next if (!defined($self->{domains}->{$domain_id}));

        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $domain_id);

        $self->{domains}->{$domain_id}->{keepalive} = {
            domain_id => $domain_id,
            %$result
        };
    }

    $self->{cache_name} = 'cisco_standard_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual port-channel (vPC).

=over 8

=item B<--unknown-peer-status>

Set unknown threshold for status.
Can used special variables like: %{role}, %{role_last}, %{domain_id}

=item B<--warning-peer-status>

Set warning threshold for status.
Can used special variables like: %{role}, %{role_last}, %{domain_id}

=item B<--critical-peer-status>

Set critical threshold for status (Default: '%{role} ne %{role_last}').
Can used special variables like: %{role}, %{role_last}, %{domain_id}

=item B<--unknown-keepalive-status>

Set unknown threshold for status.
Can used special variables like: %{keepalive_status}, %{domain_id}

=item B<--warning-keepalive-status>

Set warning threshold for status.
Can used special variables like: %{keepalive_status}, %{domain_id}

=item B<--critical-keepalive-status>

Set critical threshold for status (Default: '%{keepalive_status} ne "alive"').
Can used special variables like: %{keepalive_status}, %{domain_id}

=item B<--unknown-link-status>

Set unknown threshold for status.
Can used special variables like: %{link_status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status (Default: '%{link_status} =~ /downStar/i')
Can used special variables like: %{link_status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{link_status} eq "down"').
Can used special variables like: %{link_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'host-links-up', 'host-links-down', 'host-links-downstar',
'keepalive-messages-sent', 'keepalive-messages-received'. 

=back

=cut
