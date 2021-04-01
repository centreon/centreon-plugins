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

package apps::backup::tsm::local::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'associated', set => {
                key_values => [ { name => 'associated' } ],
                output_template => 'Total Associated Nodes : %s',
                perfdatas => [
                    { label => 'associated', value => 'associated', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'non-associated', set => {
                key_values => [ { name => 'non_associated' } ],
                output_template => 'Total Non Associated Nodes : %s',
                perfdatas => [
                    { label => 'non_associated', value => 'non_associated', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'locked', set => {
                key_values => [ { name => 'locked' } ],
                output_template => 'Total Locked Nodes : %s',
                perfdatas => [
                    { label => 'locked', value => 'locked', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $response = $options{custom}->execute_command(
        query => "SELECT node_name, 'non_associated' FROM nodes WHERE node_name NOT IN (SELECT node_name FROM associations) UNION SELECT node_name, 'associated' FROM nodes WHERE node_name IN (SELECT node_name FROM associations) UNION SELECT node_name, 'locked' FROM nodes WHERE locked='YES'"
    );
    $self->{global} = { associated => 0, non_associated => 0, locked => 0 };

    while ($response =~ /^(.*?),(non_associated|associated|locked)$/mg) {
        my ($node_name, $type) = ($1, $2);
        
        $self->{global}->{$type}++;
        $self->{output}->output_add(long_msg => "node '$node_name' is $type");
    }
}

1;

__END__

=head1 MODE

Check node status.

=over 8

=item B<--warning-*>

Set warning threshold. Can be : 'associated', 'non-associated', 'locked'.

=item B<--critical-*>

Set critical threshold. Can be : Can be : 'associated', 'non-associated', 'locked'.

=back

=cut

