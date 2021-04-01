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

package network::stonesoft::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'connections', nlabel => 'connections.total.count', set => {
                key_values => [ { name => 'fwConnNumber', diff => 1 } ],
                output_template => 'Connections : %s',
                perfdatas => [
                    { label => 'connections', template => '%s', unit => 'con', min => 0 },
                ],
            }
        },
        { label => 'rate-connections', nlabel => 'connections.total.persecond', set => {
                key_values => [ { name => 'fwConnNumber', per_second => 1 } ],
                output_template => 'Rate Connections : %.2f /s',
                perfdatas => [
                    { label => 'rate_connections', template => '%.2f', unit => 'con/s', min => 0 }
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_fwConnNumber = '.1.3.6.1.4.1.1369.5.2.1.4.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_fwConnNumber],
        nothing_quit => 1
    );
    $self->{global} = { fwConnNumber => $snmp_result->{$oid_fwConnNumber} };
    
    $self->{cache_name} = "stonesoft_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check firewall connections.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'connections', 'rate-connections'.

=item B<--critical-*>

Threshold critical.
Can be: 'connections', 'rate-connections'.

=back

=cut
