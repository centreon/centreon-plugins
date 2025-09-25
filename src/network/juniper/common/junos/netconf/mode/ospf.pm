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

package network::juniper::common::junos::netconf::mode::ospf;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_neighbor_status_output {
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
}

sub custom_changed_output {
    my ($self, %options) = @_;

    return 'Neighbors current: ' . $self->{result_values}->{detected} . ' (last: ' . $self->{result_values}->{detectedLast} . ')';
}

sub custom_changed_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{detectedLast} = $options{old_datas}->{$self->{instance} . '_detected'};
    $self->{result_values}->{detected} = $options{new_datas}->{$self->{instance} . '_detected'};
    return 0;
}

sub prefix_neighbor_output {
    my ($self, %options) = @_;

    return sprintf(
        "neighbor address '%s' [interface: %s] ",
        $options{instance_value}->{address},
        $options{instance_value}->{interfaceName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
        { name => 'neighbors', type => 1, cb_prefix_output => 'prefix_neighbor_output', message_multiple => 'All OSPF neighbors are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'neighbors-detected', nlabel => 'ospf.neighbors.detected.count', set => {
            key_values      => [ { name => 'detected' } ],
            output_template => 'Number of OSPF neighbors detected: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'neighbors-changed', type => 2, display_ok => 0, set => {
            key_values                     => [ { name => 'detected', diff => 1 } ],
            closure_custom_calc            => $self->can('custom_changed_calc'),
            closure_custom_output          => $self->can('custom_changed_output'),
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&catalog_status_threshold_ng
        }
        }
    ];

    $self->{maps_counters}->{neighbors} = [
        {
            label            => 'neighbor-status',
            type             => 2,
            critical_default => '%{state} =~ /down/i',
            set              => {
                key_values                     => [ { name => 'state' }, { name => 'address' }, { name => 'interfaceName' } ],
                closure_custom_output          => $self->can('custom_neighbor_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-neighbor-address:s' => { name => 'filter_neighbor_address' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_ospf_infos();

    $self->{global} = { detected => 0 };
    $self->{neighbors} = {};
    foreach (@$result) {
        next if (defined($self->{option_results}->{filter_neighbor_address}) && $self->{option_results}->{filter_neighbor_address} ne '' &&
                 $_->{neighborAddress} !~ /$self->{option_results}->{filter_neighbor_address}/);

        $self->{neighbors}->{ $_->{neighborId} } = {
            address       => $_->{neighborAddress},
            interfaceName => $_->{interfaceName},
            state         => $_->{state}
        };

        $self->{global}->{detected}++;
    }

    $self->{cache_name} = 'juniper_api_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
                          md5_hex(
                              (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
                              (defined($self->{option_results}->{filter_neighbor_address}) ? $self->{option_results}->{filter_neighbor_address} : '')
                          );
}

1;

__END__

=head1 MODE

Check OSPF neighbors.

=over 8

=item B<--filter-neighbor-address>

Filter neighbors by address (can be a regexp).

=item B<--unknown-neighbors-changed>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{detectedLast}, %{detected}

=item B<--warning-neighbor-changed>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{detectedLast}, %{detected}

=item B<--critical-neighbor-changed>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{detectedLast}, %{detected}

=item B<--unknown-neighbor-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{address}, %{interfaceName}

=item B<--warning-neighbor-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{address}, %{interfaceName}

=item B<--critical-neighbor-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /down/i').
You can use the following variables: %{state}, %{address}, %{interfaceName}

=item B<--warning-neighbors-detected>

Warning threshold for number of OSPF neighbors detected.

=item B<--critical-neighbors-detected>

Critical threshold for number of OSPF neighbors detected.

=back

=cut
