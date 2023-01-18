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

package network::teltonika::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("connection state is '%s' [pin state: '%s'] [net state: '%s'][sim state: '%s']", 
        $self->{result_values}->{connection_state},
        $self->{result_values}->{pin_state},
        $self->{result_values}->{net_state},
        $self->{result_values}->{sim_state},
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'sim_state' }, { name => 'pin_state' }, { name => 'net_state' }, { name => 'connection_state' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'signal-strength', nlabel => 'system.signal.strength.dbm', display_ok => 0, set => {
                key_values => [ { name => 'signal' } ],
                output_template => 'signal strength: %s Dbm',
                perfdatas => [
                    { template => '%s', min => 0 , unit => 'Dbm' },
                ]
            }
        },
        { label => 'temperature', nlabel => 'system.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'temperature: %s C',
                perfdatas => [
                    { template => '%s', min => 0 , unit => 'C' },
                ],
            }
        },
        { label => 'traffic-in', nlabel => 'system.traffic.in.bitspersecond', display_ok => 0, set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'traffic-out', nlabel => 'system.traffic.out.bitspersecond', display_ok => 0, set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'signal-receive-power', nlabel => 'system.signal.receive.power.dbm', display_ok => 0, set => {
                key_values => [ { name => 'rsrp' } ],
                output_template => 'signal receive power: %s Dbm',
                perfdatas => [
                    { template => '%s', min => 0 , unit => 'Dbm' },
                ],
            }
        },
        { label => 'signal-receive-quality', nlabel => 'system.signal.receive.quality.dbm', display_ok => 0, set => {
                key_values => [ { name => 'rsrq' } ],
                output_template => 'signal receive quality: %s Dbm',
                perfdatas => [
                    { template => '%s', min => 0 , unit => 'Dbm' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{connection_state} !~ /connected/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_SimState = '.1.3.6.1.4.1.48690.2.1.0';
    my $oid_PinState = '.1.3.6.1.4.1.48690.2.2.0';
    my $oid_NetState = '.1.3.6.1.4.1.48690.2.3.0';
    my $oid_Signal = '.1.3.6.1.4.1.48690.2.4.0';
    my $oid_ConnectionState = '.1.3.6.1.4.1.48690.2.7.0';
    my $oid_Temperature = '.1.3.6.1.4.1.48690.2.9.0';
    my $oid_Sent = '.1.3.6.1.4.1.48690.2.19.0';
    my $oid_Received = '.1.3.6.1.4.1.48690.2.20.0';
    my $oid_RSRP = '.1.3.6.1.4.1.48690.2.23.0';
    my $oid_RSRQ = '.1.3.6.1.4.1.48690.2.24.0';
    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_SimState, $oid_PinState, $oid_NetState, $oid_ConnectionState,
            $oid_Signal, $oid_Temperature, $oid_Sent, $oid_Received,
            $oid_RSRP, $oid_RSRQ
        ],
        nothing_quit => 1
    );

    $self->{cache_name} = "teltonika_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{global} = { 
        sim_state => defined($result->{$oid_SimState}) ? $result->{$oid_SimState} : '-',
        pin_state => defined($result->{$oid_PinState}) ? $result->{$oid_PinState} : '-',
        net_state => defined($result->{$oid_NetState}) ? $result->{$oid_NetState} : '-',
        connection_state => $result->{$oid_ConnectionState},
        signal => $result->{$oid_Signal},
        temperature => $result->{$oid_Temperature} / 10,
        traffic_in => $result->{$oid_Received} * 8,
        traffic_out => $result->{$oid_Sent} * 8,
        rsrp => $result->{$oid_RSRP},
        rsrq => $result->{$oid_RSRQ},
    };
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{sim_state}, %{pin_state}, %{net_state}, %{connection_state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{connection_state} !~ /connected/i').
Can used special variables like:  %{sim_state}, %{pin_state}, %{net_state}, %{connection_state}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'signal-strength', 'temperature', 'traffic-in', 'traffic-out'
'signal-receive-power', 'signal-receive-quality'.

=back

=cut
