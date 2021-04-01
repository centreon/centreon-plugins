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

package apps::vmware::connector::mode::netvm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return '[connection state ' . $self->{result_values}->{connection_state} . '][power state ' . $self->{result_values}->{power_state} . ']';
}


sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    $self->{output}->perfdata_add(
        unit => 'b/s',
        nlabel => $self->{nlabel},
        instances => $self->{instance},
        value => sprintf("%.2f", $self->{result_values}->{traffic}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $self->{result_values}->{speed}
    );
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{traffic_prct}, threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
                { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
            ]
        );
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{traffic},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
                { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
            ]
        );
    }
    return $exit;
}


sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic}, network => 1);
    my ($total_value, $total_unit);
    if (defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} =~ /[0-9]/) {
        ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{speed}, network => 1);
    }

    return sprintf(
        'traffic %s : %s/s (%s on %s)',
        $self->{result_values}->{label}, $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-',
        defined($total_value) ? $total_value . $total_unit : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic} = $options{new_datas}->{$self->{instance} . '_traffic_' . $self->{result_values}->{label}};
    if (defined($self->{instance_mode}->{option_results}->{ 'speed_' . $self->{result_values}->{label} }) && $self->{instance_mode}->{option_results}->{ 'speed_' . $self->{result_values}->{label} } =~ /[0-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / ($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000);
        $self->{result_values}->{speed} = $self->{instance_mode}->{option_results}->{ 'speed_' . $self->{result_values}->{label} } * 1000 * 1000;
    }
    return 0;
}

sub vm_long_output {
    my ($self, %options) = @_;

    return "checking virtual machine '" . $options{instance_value}->{display} . "'";
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    my $msg = "Virtual machine '" . $options{instance_value}->{display} . "'";
    if (defined($options{instance_value}->{config_annotation})) {
        $msg .= ' [annotation: ' . $options{instance_value}->{config_annotation} . ']';
    }
    $msg .= ': ';

    return $msg;
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "interface '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        { name => 'vm', type => 3, cb_prefix_output => 'prefix_vm_output', cb_long_output => 'vm_long_output', indent_long_output => '    ', message_multiple => 'All virtual machines are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_vm', type => 0, skipped_code => { -10 => 1 } },
                { name => 'interfaces', cb_prefix_output => 'prefix_interface_output',  message_multiple => 'All interfaces are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i',
            set => {
                key_values => [ { name => 'connection_state' }, { name => 'power_state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global_vm} = [
        { label => 'vm-traffic-in', nlabel => 'vm.traffic.in.bitsperseconds', set => {
                key_values => [ { name => 'traffic_in' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'vm-traffic-out', nlabel => 'vm.traffic.out.bitsperseconds', set => {
                key_values => [ { name => 'traffic_out' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'interface-traffic-in', nlabel => 'vm.interface.traffic.in.bitsperseconds', set => {
                key_values => [ { name => 'display' }, { name => 'traffic_in' }, { name => 'speed_in' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'interface-traffic-out', nlabel => 'vm.interface.traffic.out.bitsperseconds', set => {
                key_values => [ { name => 'display' }, { name => 'traffic_out' }, { name => 'speed_out' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'vm-hostname:s'           => { name => 'vm_hostname' },
        'filter'                  => { name => 'filter' },
        'scope-datacenter:s'      => { name => 'scope_datacenter' },
        'scope-cluster:s'         => { name => 'scope_cluster' },
        'scope-host:s'            => { name => 'scope_host' },
        'filter-description:s'    => { name => 'filter_description' },
        'filter-os:s'             => { name => 'filter_os' },
        'filter-uuid:s'           => { name => 'filter_uuid' },
        'display-description'     => { name => 'display_description' },,
        'filter-interface-name:s' => { name => 'filter_interface_name' },
        'speed-in:s'              => { name => 'speed_in' },
        'speed-out:s'             => { name => 'speed_out' },
        'units-traffic:s'         => { name => 'units_traffic', default => '%' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'netvm'
    );

    $self->{vm} = {};
    foreach my $vm_id (keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};

        $self->{vm}->{$vm_name} = {
            display => $vm_name,
            global => {
                connection_state => $response->{data}->{$vm_id}->{connection_state},
                power_state => $response->{data}->{$vm_id}->{power_state}, 
            },
            global_vm => {
                traffic_in => 0,
                traffic_out => 0
            }
        };
        if (defined($self->{option_results}->{display_description})) {
            $self->{vm}->{$vm_name}->{config_annotation} = $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'});
        }

        foreach my $interface_name (sort keys %{$response->{data}->{$vm_id}->{interfaces}}) {
            next if (defined($self->{option_results}->{filter_interface_name}) && $self->{option_results}->{filter_interface_name} ne '' &&
                $interface_name !~ /$self->{option_results}->{filter_interface_name}/);

            $self->{vm}->{$vm_name}->{interfaces} = {} if (!defined($self->{vm}->{$vm_name}->{interfaces}));

            $self->{vm}->{$vm_name}->{interfaces}->{$interface_name} = { 
                display     => $interface_name,
                traffic_in  => $response->{data}->{$vm_id}->{interfaces}->{$interface_name}->{'net.received.average'},
                traffic_out => $response->{data}->{$vm_id}->{interfaces}->{$interface_name}->{'net.transmitted.average'},
                speed_in    => defined($self->{option_results}->{speed_in}) ? $self->{option_results}->{speed_in} : '',
                speed_out   => defined($self->{option_results}->{speed_in}) ? $self->{option_results}->{speed_out} : ''
            };

            $self->{vm}->{$vm_name}->{global_vm}->{traffic_in} += $response->{data}->{$vm_id}->{interfaces}->{$interface_name}->{'net.received.average'};
            $self->{vm}->{$vm_name}->{global_vm}->{traffic_out} += $response->{data}->{$vm_id}->{interfaces}->{$interface_name}->{'net.transmitted.average'};
        }
    }
}

1;

__END__

=head1 MODE

Check virtual machine interfaces.

=over 8

=item B<--vm-hostname>

VM hostname to check.
If not set, we check all VMs.

=item B<--filter>

VM hostname is a regexp.

=item B<--filter-description>

Filter also virtual machines description (can be a regexp).

=item B<--filter-os>

Filter also virtual machines OS name (can be a regexp).

=item B<--filter-interface-name>

Virtual machine interface to check.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--scope-host>

Search in following host(s) (can be a regexp).

=item B<--display-description>

Display virtual machine description.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--warning-*>

Threshold warning.
Can be: 'swap-in', 'swap-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'swap-in', 'swap-out'.

=back

=cut
