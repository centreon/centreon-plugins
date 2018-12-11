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

package network::mikrotik::snmp::mode::signal;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'signalstrength', type => 1, cb_prefix_output => 'prefix_mac_output', message_multiple => 'All signals are ok' },
        { name => 'signalnoise', type => 1, cb_prefix_output => 'prefix_mac_output', message_multiple => 'All signals are ok' }
    ];
    
    $self->{maps_counters}->{signalstrength} = [
        { label => 'rx-strength', set => {
                key_values => [ { name => 'rx' }, { name => 'display' } ],
                output_template => 'Signal Strength Rx : %s',
                perfdatas => [
                    { label => 'signal_rx', value => 'rx_absolute', template => '%s', 
                      min => -90, max => -20, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'tx-strength', set => {
                key_values => [ { name => 'tx' }, { name => 'display' } ],
                output_template => 'Signal Strength Tx : %s',
                perfdatas => [
                    { label => 'signal_tx', value => 'tx_absolute', template => '%s', 
                      min => -90, max => -20, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        }
    ];

    $self->{maps_counters}->{signalnoise} = [
        { label => 'signal2noise', set => {
                key_values => [ { name => 'regs2n' }, { name => 'display' } ],
                output_template => 'Signal To Noise : %s',
                perfdatas => [
                    { label => 'signal_noise', value => 'regs2n_absolute', template => '%s', 
                      min => 20, max => 80, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "strength"  =>  { name => "strength" },
                                    "noise"     =>  { name => "noise" }
                                });
    
    return $self;
}

sub prefix_mac_output {
    my ($self, %options) = @_;
    
    return "MAC '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    regmac => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.1' },
    rx => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.3' },
    tx => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.19' },
    regs2n => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.12' },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $oids = [ $mapping->{regmac} ];
    
    if(defined($self->{option_results}->{strength})){
        push @{$oids}, ($mapping->{rx}, $mapping->{tx});
    }

    if(defined($self->{option_results}->{noise})){
        push @{$oids}, $mapping->{regs2n};
    }

    $self->{snmp} = $options{snmp};

    $self->{signalstrength} = {};
    my $interfaceTables = $self->{snmp}->get_multiple_table(oids => $oids);

    my @KeyMac = $self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $mapping->{regmac}->{oid} }});
    my (@KeysRx, @KeysTx, @Keys2n);

    if (defined($self->{option_results}->{strength})) {
        @KeysRx = $self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $mapping->{rx}->{oid} }});
        @KeysTx = $self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $mapping->{tx}->{oid} }});

    } elsif (defined($self->{option_results}->{noise})){
        @Keys2n = $self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $mapping->{regs2n}->{oid} }});
    }

    foreach my $index (0 .. $#KeyMac) {
        next if ($KeyMac[$index] !~ /^$mapping->{regmac}->{oid}\.(.*)$/); 
        next if (defined($self->{option_results}->{strength}) && 
                 $KeysRx[$index] !~ /^$mapping->{rx}->{oid}\.(.*)$/ && 
                 $KeysTx[$index] !~ /^$mapping->{tx}->{oid}\.(.*)$/); 
        next if (defined($self->{option_results}->{noise}) && $Keys2n[$index] !~ /^$mapping->{regs2n}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, 
                                                  results => $interfaceTables,  
                                                  instance => $instance);
        my $mac = unpack('H*', $interfaceTables->{$mapping->{regmac}->{oid}}->{$KeyMac[$index]});
        $mac =~ s/..\K\B/:/g;
        
        if(defined($self->{option_results}->{strength})) {
            $self->{signalstrength}->{$instance} = { display => $mac, 
                %$result
            };
        }

        if(defined($self->{option_results}->{noise})) {
            $self->{signalnoise}->{$instance} = { display => $mac, 
                %$result
            };
        }
    }
    
    if (scalar(keys %{$self->{signalstrength}}) <= 0 && scalar(keys %{$self->{signalnoise}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No signal found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "mikrotik_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port();
}

1;

__END__

=head1 MODE

Check signal strength and signal to noise.

=over 8

=item B<--noise>

Gets values for signal to noise

=item B<--strength>

Gets values for signal strength

=item B<--warning-*>

Can be rx-strength, tx-strength or signal2noise

=item B<--critical-*>

Can be rx-strength, tx-strength or signal2noise

=back

=cut
