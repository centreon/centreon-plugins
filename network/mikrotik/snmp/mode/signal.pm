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

package network::mikrotik::snmp::mode::signal;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'wreg', type => 1, cb_prefix_output => 'prefix_wreg_output', message_multiple => 'All wireless registrations are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{wreg} = [
        { label => 'rx-strength', set => {
                key_values => [ { name => 'mtxrWlRtabStrength' }, { name => 'display' } ],
                output_template => 'signal strength Rx: %s dBm',
                perfdatas => [
                    { label => 'signal_rx', value => 'mtxrWlRtabStrength', template => '%s', unit => 'dBm',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'tx-strength', set => {
                key_values => [ { name => 'mtxrWlRtabTxStrength' }, { name => 'display' } ],
                output_template => 'signal strength Tx: %s dBm',
                perfdatas => [
                    { label => 'signal_tx', value => 'mtxrWlRtabTxStrength', template => '%s', unit => 'dBm',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'signal2noise', set => {
                key_values => [ { name => 'mtxrWlRtabSignalToNoise', no_value => 0 }, { name => 'display' } ],
                output_template => 'signal to noise: %s dB',
                perfdatas => [
                    { label => 'signal_noise', value => 'mtxrWlRtabSignalToNoise', template => '%s', unit => 'dB',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub prefix_wreg_output {
    my ($self, %options) = @_;
    
    return "MAC '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    mtxrWlRtabAddr          => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.1' },
    mtxrWlRtabStrength      => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.3' }, # dBm
    mtxrWlRtabSignalToNoise => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.12' }, # dB
    mtxrWlRtabTxStrength    => { oid => '.1.3.6.1.4.1.14988.1.1.1.2.1.19' }, # dBm
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            map({ oid => $_->{oid} }, values(%$mapping))
        ], 
        return_type => 1,
        nothing_quit => 1
    );

    $self->{wreg} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{mtxrWlRtabAddr}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        my $macaddress = unpack('H*', $result->{mtxrWlRtabAddr});
        $macaddress =~ s/(..)(?=.)/$1:/g;

        $self->{wreg}->{$instance} = {
            display => $macaddress,
            %$result
        };
    }
}

1;

__END__

=head1 MODE

Check wireless registration signals.

=over 8

=item B<--warning-*> B<--critical-*>

Can be: 'rx-strength', 'tx-strength', 'signal2noise'

=back

=cut
