#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package network::barracuda::cloudgen::snmp::mode::bgppeerstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
}

sub prefix_neighbor_output {
    my ($self, %options) = @_;

    return sprintf("BGP neighbor '%s' ", $options{instance_value}->{display});
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'BGP neighbors ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'neighbors', type => 1, cb_prefix_output => 'prefix_neighbor_output',
          message_multiple => 'All BGP neighbors are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'neighbors-total', nlabel => 'bgp.neighbors.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'neighbors-established', nlabel => 'bgp.neighbors.established.count', set => {
                key_values => [ { name => 'established' }, { name => 'total' } ],
                output_template => 'established: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'neighbors-notestablished', nlabel => 'bgp.neighbors.notestablished.count', set => {
                key_values => [ { name => 'notestablished' }, { name => 'total' } ],
                output_template => 'not established: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{neighbors} = [
        { label => 'status', type => 2, critical_default => '%{state} !~ /established/i', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, statefile => 0, force_new_perfdata => 1, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-neighbor:s' => { name => 'filter_neighbor' }
    });

    return $self;
}

my $map_neighbor_state = {
    0 => 'unknown', 1 => 'idle', 2 => 'connect', 3 => 'active',
    4 => 'opensent', 5 => 'openconfirm', 6 => 'established'
};

my $mapping = {
    bgpNeighborAddress => { oid => '.1.3.6.1.4.1.10704.1.7.1.1' },
    bgpNeighborState   => { oid => '.1.3.6.1.4.1.10704.1.7.1.2' }
};

my $oid_bgpNeighborsEntry = '.1.3.6.1.4.1.10704.1.7.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_bgpNeighborsEntry,
        start => $mapping->{bgpNeighborAddress}->{oid},
        end => $mapping->{bgpNeighborState}->{oid}
    );

    $self->{global} = { total => 0, established => 0, notestablished => 0 };
    $self->{neighbors} = {};

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{bgpNeighborAddress}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        my $name = defined($result->{bgpNeighborAddress}) && $result->{bgpNeighborAddress} ne ''
            ? $result->{bgpNeighborAddress}
            : $self->decode_instance(instance => $instance);

        if (defined($self->{option_results}->{filter_neighbor}) && $self->{option_results}->{filter_neighbor} ne '' &&
            $name !~ /$self->{option_results}->{filter_neighbor}/) {
            $self->{output}->output_add(long_msg => "skipping neighbor '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        # the phion agent may return the state either as an integer (as declared
        # in PHION-MIB) or already as a display string (e.g. 'Established')
        my $state = $result->{bgpNeighborState};
        $state = defined($state) ? $state : 'unknown';
        $state = defined($map_neighbor_state->{$state}) ? $map_neighbor_state->{$state} : $state
            if ($state =~ /^\d+$/);
        $state = lc($state);

        $self->{neighbors}->{$name} = {
            display => $name,
            state => $state
        };

        $self->{global}->{total}++;
        if ($state =~ /established/) {
            $self->{global}->{established}++;
        } else {
            $self->{global}->{notestablished}++;
        }
    }

    if (scalar(keys %{$self->{neighbors}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No BGP neighbors found (is the BGP service enabled on the box?).');
        $self->{output}->option_exit();
    }
}

# the table is indexed by a DisplayString (length prefixed ascii codes)
sub decode_instance {
    my ($self, %options) = @_;

    my @indexes = split(/\./, $options{instance});
    shift(@indexes);
    return join('', map { chr($_) } @indexes);
}

1;

__END__

=head1 MODE

Check BGP neighbors state of a Barracuda CloudGen Firewall (PHION-MIB, bgpNeighbors table).

=over 8

=item B<--filter-neighbor>

Filter neighbors by address (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL
(default: '%{state} !~ /established/i').
You can use the following variables: %{state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'neighbors-total', 'neighbors-established', 'neighbors-notestablished'.

=back

=cut
