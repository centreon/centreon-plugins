#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package cloud::outscale::mode::routetables;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_table_output {
    my ($self, %options) = @_;

    return sprintf(
        "route table '%s' ",
        $options{instance}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of route tables ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'tables', type => 1, cb_prefix_output => 'prefix_table_output', message_multiple => 'All route tables are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'route-tables-detected', display_ok => 0, nlabel => 'route_tables.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tables} = [
        { label => 'route-tables-routes', nlabel => 'route_tables.routes.count', set => {
                key_values => [ { name => 'num_routes' } ],
                output_template => 'number of routes: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-route-table-id:s' => { name => 'filter_route_table_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $tables = $options{custom}->read_route_tables();

    $self->{global} = { detected => 0 };
    $self->{tables} = {};

    foreach (@$tables) {
        next if (defined($self->{option_results}->{filter_route_table_id}) && $self->{option_results}->{filter_route_table_id} ne '' &&
            $_->{RouteTableId} !~ /$self->{option_results}->{filter_route_table_id}/);

        $self->{tables}->{ $_->{RouteTableId} } = {
            num_routes => scalar(@{$_->{Routes}}),
        };

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check route tables.

=over 8

=item B<--filter-route-table-id>

Filter route tables by id.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'route-tables-detected', 'route-tables-routes'.

=back

=cut
