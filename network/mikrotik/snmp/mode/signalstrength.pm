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

package network::mikrotik::snmp::mode::signalstrength;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'signalstrength', type => 1, cb_prefix_output => 'prefix_mac_output', message_multiple => 'All signals are ok' }
    ];
    
    $self->{maps_counters}->{signalstrength} = [
        { label => 'rx-strength', set => {
                key_values => [ { name => 'rx' }, { name => 'display' } ],
                output_template => 'Signal Strngth Rx : %s',
                perfdatas => [
                    { label => 'signal-rx', value => 'rx_absolute', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'tx-strength', set => {
                key_values => [ { name => 'tx' }, { name => 'display' } ],
                output_template => 'Signal Strngth Tx : %s',
                perfdatas => [
                    { label => 'signal-tx', value => 'tx_absolute', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
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
                                });
    
    return $self;
}

sub prefix_mac_output {
    my ($self, %options) = @_;
    
    return "MAC '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    regmac      => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.1' },
    rx          => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.3' },
    tx          => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.19' }
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $oids = [$mapping->{'regmac'}, $mapping->{'tx'},  $mapping->{'rx'}];
    $self->{snmp} = $options{snmp};

    $self->{signalstrength} = {};
    my $interfaceTables = $self->{snmp}->get_multiple_table(oids => $oids);
    my @KeyMac = $self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $mapping->{'regmac'}->{'oid'} }});
    my @KeysRx = $self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $mapping->{'rx'}->{'oid'} }});
    my @KeysTx = $self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $mapping->{'tx'}->{'oid'} }});
    foreach my $index (0 .. $#KeyMac) {
        next if ($KeyMac[$index] !~ /^$mapping->{'regmac'}->{'oid'}\.(.*)$/);
        next if ($KeysRx[$index] !~ /^$mapping->{'rx'}->{'oid'}\.(.*)$/);
        next if ($KeysTx[$index] !~ /^$mapping->{'tx'}->{'oid'}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, 
                                                  results => $interfaceTables,  
                                                  instance => $instance);
        my $mac = unpack('H*', $interfaceTables->{$mapping->{'regmac'}->{'oid'}}->{$KeyMac[$index]});
        $mac =~ s/..\K\B/:/g;
        
        $self->{signalstrength}->{$instance} = { display => $mac, 
            %$result
        };
    }
    
    if (scalar(keys %{$self->{signalstrength}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No signal to noise found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "mikrotik_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port();
}

1;

__END__

=head1 MODE

Check signal strength.

=over 8


=item B<--warning-*>

=item B<--critical-*>


=back

=cut
