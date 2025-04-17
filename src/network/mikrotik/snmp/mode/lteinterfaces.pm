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

package network::mikrotik::snmp::mode::lteinterfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub custom_radio_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{display}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $instances,
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_cast_perfdata {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{display}->{$_};
    }

    if ($self->{instance_mode}->{option_results}->{units_cast} =~ /percent/) {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/percentage/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            instances => $instances,
            value => sprintf('%.2f', $self->{result_values}->{prct}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            unit => '%',
            min => 0,
            max => 100
        );
    } elsif ($self->{instance_mode}->{option_results}->{units_cast} eq 'deltaps') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/persecond/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            instances => $instances,
            value => sprintf('%.2f', $self->{result_values}->{used_ps}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            unit => '/s',
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => $instances,
            value => $self->{result_values}->{used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => $self->{result_values}->{total}
        );
    }
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{display}->{$_};
    }

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
            instances => $instances,
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => $instances,
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_errors_perfdata {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{display}->{$_};
    }

    if ($self->{instance_mode}->{option_results}->{units_errors} =~ /percent/) {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/percentage/;
        $self->{output}->perfdata_add(
            unit => '%',
            nlabel => $nlabel,
            instances => $instances,
            value => sprintf('%.2f', $self->{result_values}->{prct}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => 100
        );
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'deltaps') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/persecond/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => '/s',
            instances => $instances,
            value => sprintf('%.2f', $self->{result_values}->{used_ps}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => $instances,
            value => $self->{result_values}->{used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => $self->{result_values}->{total}
        );
    }
}

sub skip_interface {
    my ($self, %options) = @_;

    return ($self->{checking} =~ /cast|errors|traffic|status|volume|radio/ ? 0 : 1);
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "Interface '%s' [imei: %s]%s ",
        $options{instance_value}->{display}->{display},
        $options{instance_value}->{display}->{imei},
        $options{instance_value}->{extra_display}
    );
}

sub set_counters_errors {
    my ($self, %options) = @_;

     $self->SUPER::set_counters_errors(%options);

    push @{$self->{maps_counters}->{int}},
        { label => 'rsrp', filter => 'add_radio', nlabel => 'interface.signal.rsrp.dbm', set => {
                key_values => [ { name => 'rsrp' }, { name => 'display' } ],
                output_template => 'rsrp: %s dBm',
                closure_custom_perfdata => $self->can('custom_radio_perfdata')
            }
        },
        { label => 'rsrq', filter => 'add_radio', nlabel => 'interface.signal.rsrq.db', set => {
                key_values => [ { name => 'rsrq' }, { name => 'display' } ],
                output_template => 'rsrq: %s dB',
                closure_custom_perfdata => $self->can('custom_radio_perfdata')
            }
        },
        { label => 'rssi', filter => 'add_radio', nlabel => 'interface.signal.rssi.dbm', set => {
                key_values => [ { name => 'rssi' }, { name => 'display' } ],
                output_template => 'rssi: %s dBm',
                closure_custom_perfdata => $self->can('custom_radio_perfdata')
            }
        },
        { label => 'sinr', filter => 'add_radio', nlabel => 'interface.signal.sinr.dbm', set => {
                key_values => [ { name => 'sinr' }, { name => 'display' } ],
                output_template => 'sinr: %s dB',
                closure_custom_perfdata => $self->can('custom_radio_perfdata')
            }
        }
    ;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # force it
    $self->{option_results}->{add_radio} = 1;

    $self->{checking} = '';
    foreach (('add_global', 'add_status', 'add_errors', 'add_traffic', 'add_cast', 'add_speed', 'add_volume', 'add_radio')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(display) %(imei)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { display => 1, cellId => 1, imei => 1, imsi => 1 }
    );
}

sub reload_cache_custom {
    my ($self, %options) = @_;

    # we reset all_ids
    $options{datas}->{all_ids} = [];
    my $oid_mtxrLTEModemSignalRSSI = '.1.3.6.1.4.1.14988.1.1.16.1.1.2';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_mtxrLTEModemSignalRSSI);
    foreach (keys %$snmp_result) {
        next if (! /^$oid_mtxrLTEModemSignalRSSI\.(\d+)$/);
        push @{$options{datas}->{all_ids}}, $1;
    }
}

my $mapping_lte = {
    rssi   => { oid => '.1.3.6.1.4.1.14988.1.1.16.1.1.2'  }, # mtxrLTEModemSignalRSSI
    rsrq   => { oid => '.1.3.6.1.4.1.14988.1.1.16.1.1.3'  }, # mtxrLTEModemSignalRSRQ
    rsrp   => { oid => '.1.3.6.1.4.1.14988.1.1.16.1.1.4'  }, # mtxrLTEModemSignalRSRP
    cellId => { oid => '.1.3.6.1.4.1.14988.1.1.16.1.1.5'  }, # mtxrLTEModemCellId
    sinr   => { oid => '.1.3.6.1.4.1.14988.1.1.16.1.1.7'  }, # mtxrLTEModemSignalSINR
    imei   => { oid => '.1.3.6.1.4.1.14988.1.1.16.1.1.11'  }, # mtxrLTEModemIMEI
    imsi   => { oid => '.1.3.6.1.4.1.14988.1.1.16.1.1.12'  }, # mtxrLTEModemIMSI
};

sub custom_load {
    my ($self, %options) = @_;

    $self->{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_lte)) ],
        instances => $self->{array_interface_selected}
    );
}

sub custom_add_result {
    my ($self, %options) = @_;

    my $result = $self->{snmp}->map_instance(mapping => $mapping_lte, results => $self->{results}, instance => $options{instance});
    $self->{int}->{ $options{instance} }->{rssi} = $result->{rssi};
    $self->{int}->{ $options{instance} }->{rsrp} = $result->{rsrp};
    $self->{int}->{ $options{instance} }->{rsrq} = $result->{rsrq};
    $self->{int}->{ $options{instance} }->{sinr} = $result->{sinr};

    # we add imei and imsi in display value to avoid to overwritte everything
    $self->{int}->{ $options{instance} }->{display} = {
        display => $self->{int}->{ $options{instance} }->{display},
        imei => $result->{imei},
        imsi => $result->{imsi},
        cellId => $result->{cellId}
    };
}

1;

__END__

=head1 MODE

Check LTE interfaces of modems.

=over 8

=item B<--add-global>

Check global port statistics (by default if no --add-* option is set).

=item B<--add-status>

Check interface status.

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-cast>

Check interface cast.

=item B<--add-speed>

Check interface speed.

=item B<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item B<--check-metrics>

If the expression is true, metrics are checked (default: '%{opstatus} eq "up"').

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-errors>

Set warning threshold for all error counters.

=item B<--critical-errors>

Set critical threshold for all error counters.

=item B<--warning-*> B<--critical-*>

Thresholds (will superseed --[warning|critical]-errors).
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast',
'speed' (b/s).

And also: 'rsrp', 'rsrq', 'rssi', 'sinr'.

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--units-cast>

Units of thresholds for communication types (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--interface>

Set the interface (number expected) example: 1,2,... (empty means 'check all interfaces').

=item B<--name>

Allows you to define the interface (in option --interface) by name instead of OID index. The name matching mode supports regular expressions.

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--force-counters32>

Force to use 32 bits counters (even in snmp v2c and v3). Should be used when 64 bits counters are buggy.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Define the OID to be used to filter interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-display>

Define the OID that will be used to name the interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding --display-transform-src='eth' --display-transform-dst='ens'  will replace all occurrences of 'eth' with 'ens'

=item B<--show-cache>

Display cache interface data.

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(display) %(imei)')

=back

=cut
