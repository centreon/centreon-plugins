#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::hp::athonet::nodeexporter::api::mode::mme;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_gtpc_tun_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{localIP}, $self->{result_values}->{remoteIP}],
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}


sub prefix_gtpc_output {
    my ($self, %options) = @_;

    return sprintf(
        "GTP-C local IP '%s' remote IP '%s' ",
        $options{instance_value}->{localIP},
        $options{instance_value}->{remoteIP}
    );
}

sub prefix_diameter_output {
    my ($self, %options) = @_;

    return sprintf(
        "diameter stack '%s' origin host '%s' ",
        $options{instance_value}->{stack},
        $options{instance_value}->{originHost}
    );
}

sub custom_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub prefix_license_ue_output {
    my ($self, %options) = @_;

    return sprintf(
        "license UE ",
    );
}

sub prefix_license_enb_output {
    my ($self, %options) = @_;

    return sprintf(
        "license eNB ",
    );
}

sub prefix_s1_enb_output {
    my ($self, %options) = @_;

    return sprintf(
        "s1-eNB '%s' interface ",
        $options{instance_value}->{enbId}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 's1_enb', type => 1, cb_prefix_output => 'prefix_s1_enb_output', message_multiple => 'All s1-eNB interfaces are ok', skipped_code => { -10 => 1 } },
        { name => 'license_ue', type => 0, cb_prefix_output => 'prefix_license_ue_output', skipped_code => { -10 => 1 } },
        { name => 'license_enb', type => 0, cb_prefix_output => 'prefix_license_enb_output', skipped_code => { -10 => 1 } },
        { name => 'diameters', type => 1, cb_prefix_output => 'prefix_diameter_output', message_multiple => 'All diameter connections are ok', skipped_code => { -10 => 1 } },
        { name => 'gtpc', type => 1, cb_prefix_output => 'prefix_gtpc_output', message_multiple => 'All GTP-C connections are ok', skipped_code => { -10 => 1 } }

    ];

    $self->{maps_counters}->{global} = [
        { label => 'imsi-tracked', nlabel => 'mme.imsi.tracked.count', set => {
                key_values => [ { name => 'imsi_tracked' } ],
                output_template => 'IMSI tracked: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'ue-registered', nlabel => 'mme.ue.registered.count', set => {
                key_values => [ { name => 'imsi_tracked' } ],
                output_template => 'UE in EMM registered state: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'enb-connections-active', nlabel => 'mme.enb.connections.active.count', set => {
                key_values => [ { name => 's1_enb' } ],
                output_template => 'active eNB connections: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'ue-connections-active', nlabel => 'mme.ue.connections.active.count', set => {
                key_values => [ { name => 'ue_active' } ],
                output_template => 'active UE connections: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'enb-cells', nlabel => 'mme.enb.cells.count', set => {
                key_values => [ { name => 'enb_cells' } ],
                output_template => 'cells on the eNB: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{s1_enb} = [
        { label => 'interface-s1enb-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'enbId' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{license_ue} = [
        { label => 'license-ue-usage', nlabel => 'mme.license.ue.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'license-ue-usage-free', display_ok => 0, nlabel => 'mme.license.ue.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'license-ue-usage-prct', display_ok => 0, nlabel => 'mme.license.ue.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{license_enb} = [
        { label => 'license-enb-usage', nlabel => 'mme.license.enb.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'license-enb-usage-free', display_ok => 0, nlabel => 'mme.license.enb.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'license-enb-usage-prct', display_ok => 0, nlabel => 'mme.license.enb.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{diameters} = [
        { label => 'diameter-connection-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'originHost' }, { name => 'stack' } ],
                output_template => 'connection status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{gtpc} = [
        { label => 'gtpc-connection-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'localIP' }, { name => 'remoteIP' } ],
                output_template => 'connection status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'gtpc-allocated-tunnels', nlabel => 'mme.gtpc.connection.tunnels.allocated.count', set => {
                key_values => [ { name => 'allocated_tun' }, { name => 'localIP' }, { name => 'remoteIP' } ],
                output_template => 'allocated tunnels: %s',
                closure_custom_perfdata => $self->can('custom_gtpc_tun_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $response = $options{custom}->query(queries => ['mme_ue_imsi']);
    $self->{global}->{imsi_tracked} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['mme_ue_registered']);
    $self->{global}->{ue_registered} = $response->[0]->{value}->[1];
    
    $response = $options{custom}->query(queries => ['mme_s1_enb']);
    $self->{global}->{s1_enb} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['sum(mme_s1_enb_active_ue)']);
    $self->{global}->{ue_active} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['sum(mme_s1_enb_ecgi)']);
    $self->{global}->{enb_cells} = $response->[0]->{value}->[1];

    my $map_interface_status = { 1 => 'up', 0 => 'down' };
    $response = $options{custom}->query(queries => ['mme_s1_enb_status']);

    $self->{s1_enb} = {};
    foreach (@$response) {
        $self->{s1_enb}->{ $_->{metric}->{enb_id} } = {
            enbId => $_->{metric}->{enb_id},
            status => $map_interface_status->{ $_->{value}->[1] }
        };
    }

    $response = $options{custom}->query(queries => ['license_constraint']);
    $self->{license_enb} = { used => $self->{global}->{s1_enb} };
    $self->{license_ue} = { used => $self->{global}->{ue_registered} };
    foreach (@$response) {
        next if ($_->{metric}->{target_type} ne 'mme');
        if ($_->{metric}->{param} eq 'max_registered_ues') {
            $self->{license_ue}->{total} = $_->{value}->[1];
            $self->{license_ue}->{free} = $self->{license_ue}->{total} - $self->{license_ue}->{used};
            $self->{license_ue}->{prct_used} = $self->{license_ue}->{used} * 100 / $self->{license_ue}->{total};
            $self->{license_ue}->{prct_free} = 100 - $self->{license_ue}->{prct_used};
        }
        if ($_->{metric}->{param} eq 'max_connected_ran_nodes') {
            $self->{license_enb}->{total} = $_->{value}->[1];
            $self->{license_enb}->{free} = $self->{license_enb}->{total} - $self->{license_enb}->{used};
            $self->{license_enb}->{prct_used} = $self->{license_enb}->{used} * 100 / $self->{license_enb}->{total};
            $self->{license_enb}->{prct_free} = 100 - $self->{license_enb}->{prct_used};
        }
    }

    $response = $options{custom}->query(queries => ['diameter_peer_status{target_type="mme"}']);
    $self->{diameters} = {};
    my $id = 0;
    foreach (@$response) {
        $self->{diameters}->{$id} = {
            originHost => $_->{metric}->{orig_host},
            stack => $_->{metric}->{stack},
            status => $map_interface_status->{ $_->{value}->[1] }
        };
        
        $id++;
    }

    $response = $options{custom}->query(queries => ['gtpc_peer_status{target_type="mme"}']);
    $self->{gtpc} = {};
    foreach (@$response) {
        $self->{gtpc}->{ $_->{metric}->{local_ip} . ':' . $_->{metric}->{remote_ip} } = {
            localIP => $_->{metric}->{local_ip},
            remoteIP => $_->{metric}->{remote_ip},
            status => $map_interface_status->{ $_->{value}->[1] },
            allocated_tun => 0
        };
    }

    $response = $options{custom}->query(queries => ['gtpc_peer_tun{target_type="mme"}']);
    foreach (@$response) {
        next if (!defined($self->{gtpc}->{ $_->{metric}->{local_ip} . ':' . $_->{metric}->{remote_ip} }));

        $self->{gtpc}->{ $_->{metric}->{local_ip} . ':' . $_->{metric}->{remote_ip} }->{allocated_tun} = $_->{value}->[1];
    }
}

1;

__END__

=head1 MODE

Check mobility management entity.

=over 8

=item B<--unknown-interface-s1enb-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{enbId}>.

=item B<--warning-interface-s1enb-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{enbId}>.

=item B<--critical-interface-s1enb-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{enbId}>.

=item B<--unknown-diameter-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--warning-diameter-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--critical-diameter-connection-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--unknown-gtpc-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--warning-gtpc-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--critical-gtpc-connection-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--warning-imsi-tracked>

Thresholds.

=item B<--critical-imsi-tracked>

Thresholds.

=item B<--warning-ue-registered>

Thresholds.

=item B<--critical-ue-registered>

Thresholds.

=item B<--warning-enb-connections-active>

Thresholds.

=item B<--critical-enb-connections-active>

Thresholds.

=item B<--warning-ue-connections-active>

Thresholds.

=item B<--critical-ue-connections-active>

Thresholds.

=item B<--warning-enb-cells>

Thresholds.

=item B<--critical-enb-cells>

Thresholds.

=item B<--warning-license-ue-usage>

Thresholds.

=item B<--critical-license-ue-usage>

Thresholds.

=item B<--warning-license-ue-usage-free>

Thresholds.

=item B<--critical-license-ue-usage-free>

Thresholds.

=item B<--warning-license-ue-usage-prct>

Thresholds.

=item B<--critical-license-ue-usage-prct>

Thresholds.

=item B<--warning-license-enb-usage>

Thresholds.

=item B<--critical-license-enb-usage>

Thresholds.

=item B<--warning-license-enb-usage-free>

Thresholds.

=item B<--critical-license-enb-usage-free>

Thresholds.

=item B<--warning-license-enb-usage-prct>

Thresholds.

=item B<--critical-license-enb-usage-prct>

Thresholds.

=item B<--warning-gtpc-allocated-tunnels>

Thresholds.

=item B<--critical-gtpc-allocated-tunnels>

Thresholds.

=back

=cut
