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

package apps::vmware::connector::mode::nethost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status ' . $self->{result_values}->{status};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub custom_linkstatus_output {
    my ($self, %options) = @_;

    return 'status ' . $self->{result_values}->{link_status};
}

sub custom_linkstatus_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{link_status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic}, network => 1);
    return sprintf(
        "traffic %s : %s/s (%.2f %%)",
        $self->{result_values}->{label_ref}, $value . $unit, $self->{result_values}->{traffic_prct}
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed'};
    $self->{result_values}->{traffic} = $options{new_datas}->{$self->{instance} . '_traffic_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{label_ref} = $options{extra_options}->{label_ref};
    $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / $self->{result_values}->{speed};

    return 0;
}

sub custom_dropped_output {
    my ($self, %options) = @_;

    return sprintf(
        'packets %s dropped : %.2f %% (%d/%d packets)',
        $self->{result_values}->{label_ref}, 
        $self->{result_values}->{dropped_prct},
        $self->{result_values}->{dropped}, $self->{result_values}->{packets}
    );
}

sub custom_dropped_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{dropped} = $options{new_datas}->{$self->{instance} . '_dropped_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{packets} = $options{new_datas}->{$self->{instance} . '_packets_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{label_ref} = $options{extra_options}->{label_ref};
    $self->{result_values}->{dropped_prct} = 0;
    if ($self->{result_values}->{packets} > 0) {
        $self->{result_values}->{dropped_prct} = $self->{result_values}->{dropped} * 100 / $self->{result_values}->{packets};
    }
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All ESX hosts are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_host', type => 0, skipped_code => { -10 => 1 } },
                { name => 'pnic', cb_prefix_output => 'prefix_pnic_output',  message_multiple => 'All physical interfaces are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'vswitch', cb_prefix_output => 'prefix_vswitch_output',  message_multiple => 'All vswitchs are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{status} !~ /^connected$/i',
            set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global_host} = [
        { label => 'host-traffic-in', nlabel => 'host.traffic.in.bitsperseconds', set => {
                key_values => [ { name => 'traffic_in' } ],
                output_template => 'host traffic in : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'host_traffic_in', template => '%s',
                      unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'host-traffic-out', nlabel => 'host.traffic.out.bitsperseconds', set => {
                key_values => [ { name => 'traffic_out' } ],
                output_template => 'host traffic out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'host_traffic_out', template => '%s',
                      unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vswitch} = [
        { label => 'vswitch-traffic-in', nlabel => 'host.vswitch.traffic.in.bitsperseconds', set => {
                key_values => [ { name => 'traffic_in' } ],
                output_template => 'traffic in : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'vswitch_traffic_in', template => '%s',
                      unit => 'b/s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'vswitch-traffic-out', nlabel => 'host.vswitch.traffic.out.bitsperseconds', set => {
                key_values => [ { name => 'traffic_out' } ],
                output_template => 'traffic out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'vswitch_traffic_out', template => '%s',
                      unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{pnic} = [
        {
            label => 'link-status', type => 2, critical_default => '%{link_status} !~ /up/',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_linkstatus_calc'),
                closure_custom_output => $self->can('custom_linkstatus_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'link-traffic-in', nlabel => 'host.traffic.in.bitsperseconds', set => {
                key_values => [ { name => 'display' }, { name => 'traffic_in' }, { name => 'speed' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                threshold_use => 'traffic_prct',
                perfdatas => [
                    { label => 'traffic_in', value => 'traffic', template => '%s', unit => 'b/s', 
                      min => 0, max => 'speed', threshold_total => 'speed', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'link-traffic-out', nlabel => 'host.traffic.out.bitsperseconds', set => {
                key_values => [ { name => 'display' }, { name => 'traffic_out' }, { name => 'speed' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                threshold_use => 'traffic_prct',
                perfdatas => [
                    { label => 'traffic_out', value => 'traffic', template => '%s', unit => 'b/s', 
                      min => 0, max => 'speed', threshold_total => 'speed', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'link-dropped-in', nlabel => 'host.packets.in.dropped.percentage', set => {
                key_values => [ { name => 'display' }, { name => 'packets_in' }, { name => 'dropped_in' } ],
                closure_custom_calc => $self->can('custom_dropped_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_dropped_output'),
                threshold_use => 'dropped_prct',
                perfdatas => [
                    { label => 'packets_dropped_in', value => 'dropped_prct', template => '%s', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'link-dropped-out', nlabel => 'host.packets.out.dropped.percentage', set => {
                key_values => [ { name => 'display' }, { name => 'packets_out' }, { name => 'dropped_out' } ],
                closure_custom_calc => $self->can('custom_dropped_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_dropped_output'),
                threshold_use => 'dropped_prct',
                perfdatas => [
                    { label => 'packets_dropped_out', value => 'dropped_prct', template => '%s', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' : ";
}

sub host_long_output {
    my ($self, %options) = @_;

    return "checking host '" . $options{instance_value}->{display} . "'";
}

sub prefix_pnic_output {
    my ($self, %options) = @_;

    return "physical interface '" . $options{instance_value}->{display} . "' ";
}

sub prefix_vswitch_output {
    my ($self, %options) = @_;

    return "vswitch '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'esx-hostname:s'     => { name => 'esx_hostname' },
        'nic-name:s'         => { name => 'nic_name' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'scope-cluster:s'    => { name => 'scope_cluster' },
        'no-proxyswitch'     => { name => 'no_proxyswitch' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'nethost'
    );

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = { display => $host_name, 
            global => {
                state => $response->{data}->{$host_id}->{state},    
            },
            global_host => {
                traffic_in => 0,
                traffic_out => 0
            }
        };
        
        foreach my $pnic_name (sort keys %{$response->{data}->{$host_id}->{pnic}}) {
            $self->{host}->{$host_name}->{pnic} = {} if (!defined($self->{host}->{$host_name}->{pnic}));
            next if (defined($self->{option_results}->{nic_name}) && $self->{option_results}->{nic_name} ne '' &&
                $pnic_name !~ /$self->{option_results}->{nic_name}/);
            
            $self->{host}->{$host_name}->{pnic}->{$pnic_name} = { 
                display     => $pnic_name,
                status      => $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{status} ,
                traffic_in  => $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.received.average'},
                traffic_out => $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.transmitted.average'},
                speed       => defined($response->{data}->{$host_id}->{pnic}->{$pnic_name}->{speed}) ? $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{speed} * 1024 * 1024 : undef, ,
                packets_in  => $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.packetsRx.summation'},
                packets_out => $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.packetsTx.summation'},
                dropped_in  => $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.droppedRx.summation'},
                dropped_out => $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.droppedTx.summation'}
            };
            
            next if (!defined($response->{data}->{$host_id}->{pnic}->{$pnic_name}->{speed}));
            
            foreach my $vswitch_name (keys %{$response->{data}->{$host_id}->{vswitch}}) {
                next if (!defined($response->{data}->{$host_id}->{vswitch}->{$vswitch_name}->{pnic}));
                foreach (@{$response->{data}->{$host_id}->{vswitch}->{$vswitch_name}->{pnic}}) {
                    if ($_ eq $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{key}) {
                        $self->{host}->{$host_name}->{vswitch} = {} 
                            if (!defined($self->{host}->{$host_name}->{vswitch}));
                        $self->{host}->{$host_name}->{vswitch}->{$vswitch_name} = { display => $vswitch_name, traffic_in => 0, traffic_out => 0 }
                            if (!defined($self->{host}->{$host_name}->{vswitch}->{$vswitch_name}));
                        $self->{host}->{$host_name}->{vswitch}->{$vswitch_name}->{traffic_in} += $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.received.average'};
                        $self->{host}->{$host_name}->{vswitch}->{$vswitch_name}->{traffic_out} += $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.transmitted.average'};
                    }
                }
            }
            
            $self->{host}->{$host_name}->{global_host}->{traffic_in} += $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.received.average'}
                if (defined($response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.received.average'}));
            $self->{host}->{$host_name}->{global_host}->{traffic_out} += $response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.transmitted.average'}
                if (defined($response->{data}->{$host_id}->{pnic}->{$pnic_name}->{'net.transmitted.average'}));
        }
    }
}

1;

__END__

=head1 MODE

Check ESX net usage.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--nic-name>

ESX nic to check.
If not set, we check all nics.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} !~ /^connected$/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--unknown-link-status>

Set warning threshold for status.
Can used special variables like: %{link_status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status.
Can used special variables like: %{link_status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{link_status} !~ /up/').
Can used special variables like: %{link_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'host-traffic-in' (b/s), 'host-traffic-out' (b/s), 'vswitch-traffic-in' (b/s), 'vswitch-traffic-out' (b/s),
'link-traffic-in' (%), 'link-traffic-out' (%), 'link-dropped-in', 'link-dropped-out'.

=item B<--no-proxyswitch>

Use the following option if you are checking an ESX 3.x version (it's mandatory).

=back

=cut
