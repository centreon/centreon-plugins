#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::teltonika::snmp::mode::modem;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "connection state is '%s' [pin state: '%s'] [net state: '%s'][sim state: '%s']", 
        $self->{result_values}->{connectionState},
        $self->{result_values}->{pinState},
        $self->{result_values}->{netState},
        $self->{result_values}->{simState}
    );
}

sub prefix_modem_output {
    my ($self, %options) = @_;

    return sprintf(
        "modem imsi '%s' [operator: %s] ",
        $options{instance_value}->{imsi},
        $options{instance_value}->{operator}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'modems', type => 1, cb_prefix_output => 'prefix_modem_output', message_multiple => 'All modems are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];

    $self->{maps_counters}->{modems} = [
         { label => 'status', type => 2, critical_default => '%{connectionState} !~ /connected/i', set => {
                key_values => [ { name => 'simState' }, { name => 'pinState' }, { name => 'netState' }, { name => 'connectionState' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'signal-strength', nlabel => 'modem.signal.strength.dbm', display_ok => 0, set => {
                key_values => [ { name => 'signal' }, { name => 'imsi' }, { name => 'operator' } ],
                output_template => 'signal strength: %s dBm',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'dBm',
                        instances => [$self->{result_values}->{imsi}, $self->{result_values}->{operator}],
                        value => sprintf('%s', $self->{result_values}->{signal}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        },
        { label => 'temperature', nlabel => 'modem.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'temperature' }, { name => 'imsi' }, { name => 'operator' } ],
                output_template => 'temperature: %s C',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'C',
                        instances => [$self->{result_values}->{imsi}, $self->{result_values}->{operator}],
                        value => sprintf('%s', $self->{result_values}->{temperature}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                    );
                }
            }
        },
        { label => 'traffic-in', nlabel => 'modem.traffic.in.bitspersecond', display_ok => 0, set => {
                key_values => [ { name => 'received', per_second => 1 }, { name => 'imsi' }, { name => 'operator' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{imsi}, $self->{result_values}->{operator}],
                        value => sprintf('%s', $self->{result_values}->{received}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'traffic-out', nlabel => 'modem.traffic.out.bitspersecond', display_ok => 0, set => {
                key_values => [ { name => 'sent', per_second => 1 }, { name => 'imsi' }, { name => 'operator' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{imsi}, $self->{result_values}->{operator}],
                        value => sprintf('%s', $self->{result_values}->{sent}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'signal-receive-power', nlabel => 'modem.signal.receive.power.dbm', display_ok => 0, set => {
                key_values => [ { name => 'rsrp' }, { name => 'imsi' }, { name => 'operator' } ],
                output_template => 'signal receive power: %s dBm',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'dBm',
                        instances => [$self->{result_values}->{imsi}, $self->{result_values}->{operator}],
                        value => sprintf('%s', $self->{result_values}->{rsrp}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        },
        { label => 'signal-receive-quality', nlabel => 'modem.signal.receive.quality.dbm', display_ok => 0, set => {
                key_values => [ { name => 'rsrq' }, { name => 'imsi' }, { name => 'operator' } ],
                output_template => 'signal receive quality: %s dBm',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'dBm',
                        instances => [$self->{result_values}->{imsi}, $self->{result_values}->{operator}],
                        value => sprintf('%s', $self->{result_values}->{rsrq}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

sub teltonika_legacy {
    my ($self, %options) = @_;

    my $mapping = {
        imsi => { oid => '.1.3.6.1.4.1.48690.1.6' },
        simState => { oid => '.1.3.6.1.4.1.48690.2.1' },
        pinState => { oid => '.1.3.6.1.4.1.48690.2.2' },
        netState => { oid => '.1.3.6.1.4.1.48690.2.3' },
        signal => { oid => '.1.3.6.1.4.1.48690.2.4' },
        operator => { oid => '.1.3.6.1.4.1.48690.2.5' },
        connectionState => { oid => '.1.3.6.1.4.1.48690.2.7' },
        temperature => { oid => '.1.3.6.1.4.1.48690.2.9' },
        sent => { oid => '.1.3.6.1.4.1.48690.2.19' },
        received => { oid => '.1.3.6.1.4.1.48690.2.20' },
        rsrp => { oid => '.1.3.6.1.4.1.48690.2.23' },
        rsrq => { oid => '.1.3.6.1.4.1.48690.2.24' }
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    $result->{simState} = defined($result->{simState}) ? $result->{simState} : '-';
    $result->{pinState} = defined($result->{pinState}) ? $result->{pinState} : '-';
    $result->{netState} = defined($result->{netState}) ? $result->{netState} : '-';
    $result->{temperature} = $result->{temperature} / 10;
    $result->{sent} = $result->{sent} * 8;
    $result->{received} = $result->{received} * 8;

    $self->{modems} = { 0 => $result };
}

sub teltonika_trb14x {
    my ($self, %options) = @_;

    my $mapping = {
        imsi => { oid => '.1.3.6.1.4.1.48690.2.2.1.8' },
        simState => { oid => '.1.3.6.1.4.1.48690.2.2.1.9' },
        pinState => { oid => '.1.3.6.1.4.1.48690.2.2.1.10' },
        netState => { oid => '.1.3.6.1.4.1.48690.2.2.1.11' },
        signal => { oid => '.1.3.6.1.4.1.48690.2.2.1.12' },
        operator => { oid => '.1.3.6.1.4.1.48690.2.2.1.13' },
        connectionState => { oid => '.1.3.6.1.4.1.48690.2.2.1.15' },
        temperature => { oid => '.1.3.6.1.4.1.48690.2.2.1.17' },
        rsrp => { oid => '.1.3.6.1.4.1.48690.2.2.1.20' },
        rsrq => { oid => '.1.3.6.1.4.1.48690.2.2.1.21' },
        sent => { oid => '.1.3.6.1.4.1.48690.2.2.1.22' },
        received => { oid => '.1.3.6.1.4.1.48690.2.2.1.23' }
    };

    my $oid_modemEntry = '.1.3.6.1.4.1.48690.2.2.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_modemEntry,
        nothing_quit => 1
    );

    $self->{modems} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{imsi}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $result->{simState} = defined($result->{simState}) ? $result->{simState} : '-';
        $result->{pinState} = defined($result->{pinState}) ? $result->{pinState} : '-';
        $result->{netState} = defined($result->{netState}) ? $result->{netState} : '-';
        $result->{temperature} = $result->{temperature} / 10;
        $result->{sent} = $result->{sent} * 8;
        $result->{received} = $result->{received} * 8;

        $self->{modems}->{$instance} = $result;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_hardwareRevision = '.1.3.6.1.4.1.48690.1.10.0'; # legacy
    my $oid_fwVersion = '.1.3.6.1.4.1.48690.1.6.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_hardwareRevision, $oid_fwVersion ],
        nothing_quit => 1
    );

    if (defined($snmp_result->{$oid_hardwareRevision})) {
        $self->teltonika_legacy(snmp => $options{snmp});
    } else {
        $self->teltonika_trb14x(snmp => $options{snmp});
    }

    $self->{cache_name} = 'teltonika_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check modem.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{simState}, %{pinState}, %{netState}, %{connectionState}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{connectionState} !~ /connected/i').
You can use the following variables:  %{simState}, %{pinState}, %{netState}, %{connectionState}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'signal-strength', 'temperature', 'traffic-in', 'traffic-out'
'signal-receive-power', 'signal-receive-quality'.

=back

=cut
