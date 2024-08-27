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

package network::cambium::cnpilot::snmp::mode::radios;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub prefix_radio_output {
    my ($self, %options) = @_;

    return "radio interface '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'radios', type => 1, cb_prefix_output => 'prefix_radio_output', message_multiple => 'All raadio interfaces are ok' }
    ];

    $self->{maps_counters}->{radios} = [
        { label => 'clients-connected', nlabel => 'radio.clients.connected.count', set => {
                key_values => [ { name => 'num_clients' }, { name => 'name' } ],
                output_template => 'clients connected: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'status', type => 2, critical_default => '%{state} eq "off"',
            set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'noise-floor', nlabel => 'radio.interface.noise.floor.dbm', set => {
                key_values => [ { name => 'noise_floor' } ],
                output_template => 'noise floor: %s dBm',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'dBm', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'interference', nlabel => 'radio.interface.interference.dbm', set => {
                key_values => [ { name => 'interference' } ],
                output_template => 'interference: %s dBm',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'dBm', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'radio.interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'radio.interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Select relevant oids for radio monitoring
    my $mapping = {
        cambiumRadioMACAddress    => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.2' },
        cambiumRadioNumClients    => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.5' },
        cambiumRadioTxDataBytes   => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.9' },
        cambiumRadioRxDataBytes   => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.10' },
        cambiumRadioState         => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.13' },
        cambiumRadioNoiseFloor    => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.16' },
        cambiumRadioInterference  => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.17' }
    };

    # Point at the begining of the table 
    my $oid_cambiumRadioPointEntry = '.1.3.6.1.4.1.17713.22.1.2.1';

    my $radio_result = $options{snmp}->get_table(
        oid => $oid_cambiumRadioPointEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$radio_result}) {
        next if ($oid !~ /^$mapping->{cambiumRadioMACAddress}->{oid}\.(.*)$/);
        # Catch instance in table
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $radio_result, instance => $instance);

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{cambiumRadioMACAddress} !~ /$self->{option_results}->{filter_name}/);

        $self->{radios}->{$instance} = {
            name => $result->{cambiumRadioMACAddress},
            num_clients => $result->{cambiumRadioNumClients},
            state => lc($result->{cambiumRadioState}),
            traffic_out => $result->{cambiumRadioTxDataBytes} * 8,
            traffic_in => $result->{cambiumRadioRxDataBytes} * 8,
            noise_floor => $result->{cambiumRadioNoiseFloor},
            interference => $result->{cambiumRadioInterference}
        };
    }

    if (scalar(keys %{$self->{radios}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No MACAddress matching with filter found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'cambium_cnpilot_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '')
        );
}

1;

__END__

=head1 MODE

Check radio interfaces.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter interface by MACAdress

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "expired"').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'clients-connected', 'noise-floor', 'interference', 'traffic-in', 'traffic-out'.

=back

=cut
