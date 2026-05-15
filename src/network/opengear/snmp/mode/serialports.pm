#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::opengear::snmp::mode::serialports;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc qw/is_excluded/;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/bitspersecond/bits/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => 'b',
            instances => $self->{result_values}->{name},
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => $self->{result_values}->{name},
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_counter}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        'traffic %s: %s/s (%s)',
        $self->{result_values}->{label}, $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    my $diff_traffic = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} } - $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} });
    $self->{result_values}->{traffic_per_seconds} = $diff_traffic / $options{delta_time};
    $self->{result_values}->{traffic_counter} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };
    if (defined($options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}}) && 
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} > 0) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{name} = $options{new_datas}->{ $self->{instance} . '_name' };
    return 0;
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "Serial port '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All interfaces are ok', cb_init_counters => 'skip_counters', skipped_code => { NO_VALUE() => 1 } },
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'traffic-in', nlabel => 'serial_port.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'speed_in' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic in: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'traffic-out', nlabel => 'serial_port.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'speed_out' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic out: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'   => { redirect => 'include_name' },
        'include-name:s'  => { name => 'include_name', default => ''},
        'exclude-name:s'  => { name => 'exclude_name', default => ''},
        'units-traffic:s' => { name => 'units_traffic', default => 'percent_delta' },
        'speed:s'         => { name => 'speed' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
        if ($self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
            $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also).");
            $self->{output}->option_exit();
        } else {
            $self->{option_results}->{speed} *= 1000000;
        }
    }

    $self->{option_results}->{units_traffic} = 'percent_delta'
        if (!defined($self->{option_results}->{units_traffic}) ||
            $self->{option_results}->{units_traffic} eq '' ||
            $self->{option_results}->{units_traffic} eq '%');
    if ($self->{option_results}->{units_traffic} !~ /^(?:percent|percent_delta|bps|counter)$/) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --units-traffic.');
        $self->{output}->option_exit();
    }
}

our @mapping_list = (
    {
        oid => '.1.3.6.1.4.1.25049.16.1.1.11', # ogSerialPortStatusLabel
        data => { rxBytes => { oid => '.1.3.6.1.4.1.25049.16.1.1.3' }, # ogSerialPortStatusRxBytes
                  txBytes => { oid => '.1.3.6.1.4.1.25049.16.1.1.4' }, # ogSerialPortStatusTxBytes
                  speed   => { oid => '.1.3.6.1.4.1.25049.16.1.1.5' }  # ogSerialPortStatusSpeed
                }
    },
    {
        oid => '.1.3.6.1.4.1.25049.10.19.2.2.1.2', # ogOmSerialPortLabel
        data => { rxBytes => { oid => '.1.3.6.1.4.1.25049.10.19.2.2.1.11' }, # ogOmSerialPortRxBytes
                  txBytes => { oid => '.1.3.6.1.4.1.25049.10.19.2.2.1.12' }, # ogOmSerialPortTxBytes
                  speed   => { oid => '.1.3.6.1.4.1.25049.10.19.2.2.1.3' }  # ogOmSerialPortSpeed
                }
    }
);

sub manage_selection {
    my ($self, %options) = @_;

    $self->{interfaces} = {};
    my $is_disco = $self->{output}->is_disco_show();

    $self->{output}->option_exit(short_msg => 'Need to use SNMP v2c or v3.')
        if $options{snmp}->is_snmpv1() && !$is_disco;

    my $snmp_result;
    my $mapping;

    foreach (@mapping_list) {
        $snmp_result = $options{snmp}->get_table( oid => $_->{oid} );
        if (ref $snmp_result eq 'HASH' && keys %$snmp_result) {
          $mapping = $_;
          last
        }
    }

    if (ref $snmp_result eq 'HASH' && keys %$snmp_result) {
        foreach (keys %$snmp_result) {
            /\.(\d+)$/;
            my $instance = $1;
            next if is_excluded($snmp_result->{$_}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name});
            $self->{interfaces}->{$instance} = { name => $snmp_result->{$_} };
        }
    } elsif (!$is_disco) {
        $self->{output}->option_exit(short_msg => 'No Opengear serial port SNMP entries found')
    }

    return if $is_disco;

    $self->{output}->option_exit(short_msg => 'No maching Opengear serial port SNMP entries')
        unless keys %{$self->{interfaces}};

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%{$mapping->{data}}))
        ],
        instances => [ map($_, keys %{$self->{interfaces}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{interfaces}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{data}, results => $snmp_result, instance => $_);

        $self->{interfaces}->{$_}->{in} = $result->{rxBytes};
        $self->{interfaces}->{$_}->{out} = $result->{txBytes};
        $self->{interfaces}->{$_}->{speed_in} = $self->{option_results}->{speed} // $result->{speed};
        $self->{interfaces}->{$_}->{speed_out} = $self->{option_results}->{speed} // $result->{speed};
    }

    $self->{cache_name} = 'opengear_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        sha256_hex(
            ($self->{option_results}->{filter_counters} // 'all') . '_' .
            ($self->{option_results}->{include_name} ne '' ? $self->{option_results}->{include_name} : 'all') . '_' .
            ($self->{option_results}->{exclude_name} ne '' ? $self->{option_results}->{exclude_name} : 'all')
        );
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    $self->{output}->add_disco_entry( name => $_->{name} )
        foreach sort { $a->{name} cmp $b->{name} }
                values %{$self->{interfaces}};
}

1;

__END__

=head1 MODE

Check serial ports.

=over 8

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--include-name>

Filter serial port name (regexp can be used).

=item B<--exclude-name>

Exclude serial port name (regexp can be used).

=item B<--speed>

Set serial port speed (in Mb).

=item B<--warning-traffic-in>

Threshold.

=item B<--critical-traffic-in>

Threshold.

=item B<--warning-traffic-out>

Threshold.

=item B<--critical-traffic-out>

Threshold.

=back

=cut
