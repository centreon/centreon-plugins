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

package network::forcepoint::sdwan::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'total-connections',
            nlabel => 'connections.total.count',
            set    => {
                key_values      => [ { name => 'fwConnNumber' } ],
                output_template => 'Total connections : %s',
                perfdatas       => [
                    { label => 'total_connections', template => '%s', unit => 'con', min => 0 },
                ],
            }
        },
        {
            label  => 'new-connections-sec',
            nlabel => 'connections.new.persecond',
            set    => {
                key_values      => [ { name => 'fwNewConnectionsS' } ],
                output_template => 'New Connections : %.2f /s',
                perfdatas       => [
                    { label => 'new_connections', template => '%.2f', unit => 'con/s', min => 0 }
                ],
            }
        },
        {
            label  => 'discarded-connections-sec',
            nlabel => 'connections.discarded.persecond',
            set    => {
                key_values      => [ { name => 'fwDiscardedConnectionsS' } ],
                output_template => 'Discarded Connections : %.2f /s',
                perfdatas       => [
                    { label => 'discarded_connections', template => '%.2f', unit => 'con/s', min => 0 }
                ],
            }
        },
        {
            label  => 'refused-connections-sec',
            nlabel => 'connections.refused.persecond',
            set    => {
                key_values      => [ { name => 'fwRefusedConnectionsS' } ],
                output_template => 'Refused Connections : %.2f /s',
                perfdatas       => [
                    { label => 'refused_connections', template => '%.2f', unit => 'con/s', min => 0 }
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_fwConnNumber = '.1.3.6.1.4.1.47565.1.1.1.4.0';
    my $oid_fwNewConnectionsS = '.1.3.6.1.4.1.47565.1.1.1.11.4.0';
    my $oid_fwDiscardedConnectionsS = '.1.3.6.1.4.1.47565.1.1.1.11.5.0';
    my $oid_fwRefusedConnectionsS = '.1.3.6.1.4.1.47565.1.1.1.11.6.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids =>
            [
                $oid_fwConnNumber,
                $oid_fwNewConnectionsS,
                $oid_fwDiscardedConnectionsS,
                $oid_fwRefusedConnectionsS
            ],
        nothing_quit => 1
    );

    $self->{global} = {
        fwConnNumber            => $snmp_result->{$oid_fwConnNumber},
        fwNewConnectionsS       => $snmp_result->{$oid_fwNewConnectionsS},
        fwDiscardedConnectionsS => $snmp_result->{$oid_fwDiscardedConnectionsS},
        fwRefusedConnectionsS   => $snmp_result->{$oid_fwRefusedConnectionsS},
    };
}

1;

__END__

=head1 MODE

Check firewall connections.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Can be : total-connections, new-connections-sec, discarded-connections-sec, refused-connections-sec
Example : --filter-counters='^total-connections$'

=item B<--warning-total-connections>

Threshold in con.

=item B<--critical-total-connections>

Threshold in con.

=item B<--warning-discarded-connections-sec>

Threshold in con/s.

=item B<--critical-discarded-connections-sec>

Threshold in con/s.

=item B<--warning-new-connections-sec>

Threshold in con/s.

=item B<--critical-new-connections-sec>

Threshold in con/s.

=item B<--warning-refused-connections-sec>

Threshold in con/s.

=item B<--critical-refused-connections-sec>

Threshold in con/s

=back

=cut
