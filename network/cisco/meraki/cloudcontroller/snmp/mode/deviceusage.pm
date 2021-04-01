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

package network::cisco::meraki::cloudcontroller::snmp::mode::deviceusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{status};
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
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
        label => 'traffic_' . $self->{result_values}->{label}, unit => 'b/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
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
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
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

    my $msg = sprintf("Traffic %s : %s/s (%s on %s)",
                      ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-',
                      defined($total_value) ? $total_value . $total_unit : '-');
    return $msg;
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_traffic = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}} - $options{old_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}};
    $self->{result_values}->{traffic} = $diff_traffic / $options{delta_time};
    if (defined($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}}) && $self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} =~ /[0-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / ($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000);
        $self->{result_values}->{speed} = $self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000;
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global' },
        { name => 'device', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok' },
        { name => 'interface', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All device interfaces are ok', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-devices', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total devices : %s',
                perfdatas => [
                    { label => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{device} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'clients', set => {
                key_values => [ { name => 'clients' }, { name => 'display' } ],
                output_template => 'Clients : %s',
                perfdatas => [
                    { label => 'clients', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{interface} = [
        { label => 'in', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
        { label => 'out', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'      => { name => 'filter_name' },
        'filter-interface:s' => { name => 'filter_interface' },
        'filter-network:s'   => { name => 'filter_network' },
        'filter-product:s'   => { name => 'filter_product' },
        'warning-status:s'   => { name => 'warning_status', default => '' },
        'critical-status:s'  => { name => 'critical_status', default => '%{status} =~ /offline/' },
        'speed-in:s'         => { name => 'speed_in' },
        'speed-out:s'        => { name => 'speed_out' },
        'units-traffic:s'    => { name => 'units_traffic', default => '%' },
        'cache-expires-on:s' => { name => 'cache_expires_on' },
    });

    $self->{cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    $self->{cache}->check_options(option_results => $self->{option_results});
    if (defined($self->{option_results}->{cache_expires_on}) && $self->{option_results}->{cache_expires_on} =~ /(\d+)/) {
        $self->{cache_expires_on} = $1; 
    }
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{device}}) > 1 ? return(0) : return(1);
}

sub prefix_device_output {
    my ($self, %options) = @_;
    
    return "Device '" . $options{instance_value}->{display} . "' [network: " . $options{instance_value}->{network} . "]" .
        " [product: " . $options{instance_value}->{product} . "] ";
}

sub prefix_interface_output {
    my ($self, %options) = @_;
    
    return "Interface '" . $options{instance_value}->{display} . "' ";
}

my %map_status = (
    0 => 'offline',
    1 => 'online',
);
my $mapping = {
    devName         => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.2' },
    devStatus       => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.3', map => \%map_status },
    devClientCount  => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.5' },
    devProductCode  => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.9' },
    devNetworkName  => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.11' },
};
my $mapping2 = {
    devInterfaceName        => { oid => '.1.3.6.1.4.1.29671.1.1.5.1.3' },
    devInterfaceSentBytes   => { oid => '.1.3.6.1.4.1.29671.1.1.5.1.6' },
    devInterfaceRecvBytes   => { oid => '.1.3.6.1.4.1.29671.1.1.5.1.7' },
};

sub get_devices_infos_snmp {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{devName}->{oid} },
            { oid => $mapping2->{devInterfaceName}->{oid} },
            { oid => $mapping->{devProductCode}->{oid} },
            { oid => $mapping->{devNetworkName}->{oid} }
        ], 
        nothing_quit => 1
    );

    return $snmp_result;
}

sub get_devices_infos {
    my ($self, %options) = @_;

    my $snmp_result;
    if (defined($self->{cache_expires_on})) {
        my $has_cache_file = $self->{cache}->read(statefile => 'meraki_' . $self->{mode} . '_' . md5_hex($options{snmp}->get_hostname()));
        my $timestamp = $self->{cache}->get(name => 'last_timestamp');
        if ($has_cache_file == 0 || !defined($timestamp) || ((time() - $self->{cache_expires_on}) > $timestamp)) {
            $snmp_result = $self->get_devices_infos_snmp(%options);
            my $datas = { last_timestamp => time(), snmp => $snmp_result };
            $self->{cache}->write(data => $datas);
        } else {
            $snmp_result = $self->{cache}->get(name => 'snmp');
        }
    } else {
        $snmp_result = $self->get_devices_infos_snmp(%options);
    }
    
    return $snmp_result;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{device} = {};
    $self->{interface} = {};
    $self->{global} = { total => 0 };

    my $snmp_result = $self->get_devices_infos(%options);
    foreach my $oid (keys %{$snmp_result->{ $mapping->{devName}->{oid} }}) {
        $oid =~ /^$mapping->{devName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $dev_name = $snmp_result->{$mapping->{devName}->{oid}}->{$oid};
        my $network = defined($snmp_result->{$mapping->{devNetworkName}->{oid}}->{ $mapping->{devNetworkName}->{oid} . '.' . $instance })
            ? $snmp_result->{$mapping->{devNetworkName}->{oid}}->{ $mapping->{devNetworkName}->{oid} . '.' . $instance } : 'n/a';
        my $product = $snmp_result->{$mapping->{devProductCode}->{oid}}->{ $mapping->{devProductCode}->{oid} . '.' . $instance };
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $dev_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $dev_name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_product}) && $self->{option_results}->{filter_product} ne '' &&
            $product !~ /$self->{option_results}->{filter_product}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $dev_name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_network}) && $self->{option_results}->{filter_network} ne '' &&
            $network !~ /$self->{option_results}->{filter_network}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $dev_name . "': no matching filter.", debug => 1);
            next;
        }
        
        foreach (keys %{$snmp_result->{ $mapping2->{devInterfaceName}->{oid} }}) {
            next if (!/^$mapping2->{devInterfaceName}->{oid}\.$instance\.(.*)/);
            
            my $index = $1;
            my $interface_name = $snmp_result->{ $mapping2->{devInterfaceName}->{oid} }->{$_};
            if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
                $interface_name !~ /$self->{option_results}->{filter_interface}/) {
                $self->{output}->output_add(long_msg => "skipping interface '" . $dev_name . '.' . $interface_name . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{interface}->{$instance . '.' . $index} = { display => $dev_name . '.' . $interface_name };
        }
        
        $self->{global}->{total}++;
        $self->{device}->{$instance} = { display => $dev_name, network => $network, product => $product };
    }

    if (scalar(keys %{$self->{interface}}) > 0) {
        $options{snmp}->load(oids => [$mapping2->{devInterfaceSentBytes}->{oid}, $mapping2->{devInterfaceRecvBytes}->{oid}],
            instances => [keys %{$self->{interface}}], instance_regexp => '^(.*)$');
        $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
        foreach (keys %{$self->{interface}}) {
            my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);

            $self->{interface}->{$_}->{in} = $result->{devInterfaceRecvBytes} * 8;
            $self->{interface}->{$_}->{out} = $result->{devInterfaceSentBytes} * 8;
        }
    }
    
    if (scalar(keys %{$self->{device}}) > 0) {
        $options{snmp}->load(oids => [$mapping->{devStatus}->{oid}, $mapping->{devClientCount}->{oid}],
            instances => [keys %{$self->{device}}], instance_regexp => '^(.*)$');
        $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
        foreach (keys %{$self->{device}}) {
            my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

            $self->{device}->{$_}->{status} = $result->{devStatus};
            $self->{device}->{$_}->{clients} = $result->{devClientCount};
        }
    }
    
    $self->{cache_name} = "cisco_meraki_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_interface}) ? md5_hex($self->{option_results}->{filter_interface}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_product}) ? md5_hex($self->{option_results}->{filter_product}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check device usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^clients$'

=item B<--filter-name>

Filter device name (can be a regexp).

=item B<--filter-product>

Filter device product code (can be a regexp).

=item B<--filter-network>

Filter by network name (can be a regexp).

=item B<--filter-interface>

Filter interface name (can be a regexp).

=item B<--cache-expires-on>

Use cache file to speed up mode execution (X seconds before refresh cache file).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /offline/').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-devices', 'clients', 'in', 'out'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-devices', 'clients', 'in', 'out'.

=back

=cut
