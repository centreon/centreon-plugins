#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

sub prefix_radios_output {
    my ($self, %options) = @_;

    return "RADIOS '" . $options{instance_value}->{name} . " ";
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'Transmit power : %s',
        $self->{result_values}->{transmit_power}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'radios', type => 1, cb_prefix_output => 'prefix_radios_output', message_multiple => 'All Radios are ok' }
    ];

    $self->{maps_counters}->{radios} = [
        { label => 'clients', nlabel => 'number.of.clients.connected', set => {
                key_values => [ { name => 'num_clients' }, { name => 'name' } ],
                output_template => '- Number of clients connected :%s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name'}
                ]
            }
        },
        { label => 'status',type => 2, critical_default => '%{OFF} eq "down"',
            set => {
                key_values => [ { name => 'transmit_power' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'noise_floor', nlabel => 'radio.interface.noise.floor.dbm', set => {
                key_values => [ { name => 'noise_floor' } ],
                output_template => 'noise floor: %s dBm',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'dBm', label_extra_instance => 1, instance_use => 'name'}
                ]
            }
        },
        { label => 'interference', nlabel => 'radio.interface.interference.dbm', set => {
                key_values => [ { name => 'interference' } ],
                output_template => 'interference: %s dBm',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'dBm', label_extra_instance => 1, instance_use => 'name'}
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'radio.interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in'}],
                output_template => 'in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name'}
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'radio.interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out'}],
                output_template => 'out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name'}
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Mac adress
    # Num Client
    # RadioState  
    # Radio TxtDataBytes => Traffic => convert in Mb
    # Radio RXDataBytes => Traffic => convert in Mb
    # Noise floor (dBm)
    # Interference (unit ?)

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

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{cambiumRadioMACAddress} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{cambiumRadioMACAddress} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{radios}->{$instance} = {
            name => $result->{cambiumRadioMACAddress},
            num_clients => $result->{cambiumRadioNumClients},
            transmit_power => $result->{cambiumRadioState},
            traffic_out => $result->{cambiumRadioTxDataBytes},
            traffic_in => $result->{cambiumRadioRxDataBytes},
            noise_floor => $result->{cambiumRadioNoiseFloor},
            interference => $result->{cambiumRadioInterference}

        };
    }

    if (scalar(keys %{$self->{radios}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No MACAddress matching with filter found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check radio interfaces.

=over 8

=item B<--filter-name>

Filter interface by MACAdress

=back

=cut
