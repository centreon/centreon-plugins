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

package apps::nginx::serverstatus::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Connections ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 }
    ];

    $self->{maps_counters}->{global} = [];
    foreach (('active', 'reading', 'writing', 'waiting')) {
        push @{$self->{maps_counters}->{global}},
            { label => 'connections-' . $_, nlabel => 'server.connections.' . $_ . '.count', set => {
                    key_values => [ { name => $_ }, { name => 'total' } ],
                    output_template => $_ . ': %d',
                    perfdatas => [
                        { template => '%d', min => 0, max => 'total' }
                    ]
                }
            };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $content = $options{custom}->get_status();
    $self->{global} = {};
    $self->{global}->{active} = $1 if ($content =~ /Active connections:\s*(\d+)/msi);
    $self->{global}->{reading} = $1 if ($content =~ /Reading:\s*(\d+)/msi);
    $self->{global}->{writing} = $1 if ($content =~ /Writing:\s*(\d+)/msi);
    $self->{global}->{waiting} = $1 if ($content =~ /Waiting:\s*(\d+)/msi);
    if (!defined($self->{global}->{active})) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find connection informations.');
        $self->{output}->option_exit();
    }
    my $total = 0;
    $total += $self->{global}->{$_} foreach (keys %{$self->{global}});
    $self->{global}->{total} = $total;
}

1;

__END__

=head1 MODE

Check current connections.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections-active', 'connections-waiting', 'connections-writing', 'connections-reading'.

=back

=cut
