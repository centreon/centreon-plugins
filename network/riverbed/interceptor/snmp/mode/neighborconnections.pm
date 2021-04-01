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

package network::riverbed::interceptor::snmp::mode::neighborconnections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'neighbor', type => 1, cb_prefix_output => 'prefix_neighbor_output',
          message_multiple => 'All neighbor connections count are ok' },
    ];
    
    $self->{maps_counters}->{neighbor} = [
        { label => 'connection', set => {
                key_values => [ { name => 'neighborConnectionCount' }, { name => 'display' } ],
                output_template => 'Optimized Connections Count: %d',
                perfdatas => [
                    { label => 'connections', value => 'neighborConnectionCount', template => '%d', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_neighbor_output {
    my ($self, %options) = @_;
    
    return "Neighbor '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });
    return $self;
}

my $mappings = {
    int => {
        neighborName => { oid => '.1.3.6.1.4.1.17163.1.3.2.6.1.3' },
        neighborConnectionCount => { oid => '.1.3.6.1.4.1.17163.1.3.2.6.1.4' },
    },
};

my $oids = {
    int => '.1.3.6.1.4.1.17163.1.3.2.6',
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{int},
              start => $mappings->{int}->{neighborName}->{oid},
              end => $mappings->{int}->{neighborConnectionCount}->{oid} }
        ]
    );
    
    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});
        foreach my $oid (keys %{$results->{$oids->{$equipment}}}) {
            next if ($oid !~ /^$mappings->{$equipment}->{neighborName}->{oid}\.(\d+)/);
            my $instance = $1;

            my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment},
                results => $results->{$oids->{$equipment}}, instance => $instance);
                
            $self->{neighbor}->{$result->{neighborName}} = {
                display => $result->{neighborName},
                neighborConnectionCount => $result->{neighborConnectionCount}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check neighbor optimized connections count.

=over 8

=item B<--warning-connection>

Threshold warning.

=item B<--critical-connection>

Threshold critical.

=back

=cut
