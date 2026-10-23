#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package centreon::common::cisco::standard::snmp::mode::cdp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_cdp_run = { 1 => 'enabled', 2 => 'disabled' };
my $oid_cdpGlobalRun = '.1.3.6.1.4.1.9.9.23.1.3.1.0';
my $oid_cdpCacheEntry = '.1.3.6.1.4.1.9.9.23.1.2.1.1';
my $oid_cdpInterfaceName = '.1.3.6.1.4.1.9.9.23.1.1.1.1.6';
my $mapping = {
    name        => { oid => '.1.3.6.1.4.1.9.9.23.1.2.1.1.6' }, # cdpCacheDeviceId
    remote_port => { oid => '.1.3.6.1.4.1.9.9.23.1.2.1.1.7' }  # cdpCacheDevicePort
};

sub custom_status_output {
    my ($self, %options) = @_;

    return 'CDP is ' . $self->{result_values}->{status};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} eq "unknown"',
            critical_default => '%{status} eq "disabled"',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'neighbors-count', nlabel => 'cdp.neighbors.count', set => {
                key_values => [ { name => 'neighbors' } ],
                output_template => '%s neighbor(s)',
                perfdatas => [
                    { template => '%s', min => 0 }
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
        'filter-neighbor:s' => { name => 'filter_neighbor' }
    });

    return $self;
}

# Shared with the list-cdp-neighbors mode.
sub get_neighbors {
    my (%options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cdpCacheEntry, start => $mapping->{name}->{oid}, end => $mapping->{remote_port}->{oid} },
            { oid => $oid_cdpInterfaceName }
        ],
        return_type => 1
    );

    my $neighbors = {};
    foreach (keys %$snmp_result) {
        # cdpCacheTable index is ifIndex.deviceIndex: keep both parts or neighbors overwrite each other
        next if (!/^$mapping->{name}->{oid}\.((\d+)\.\d+)$/);
        my ($instance, $if_index) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        next if (defined($options{filter_neighbor}) && $options{filter_neighbor} ne '' &&
            $result->{name} !~ /$options{filter_neighbor}/);

        my $local_interface = $snmp_result->{ $oid_cdpInterfaceName . '.' . $if_index };
        $neighbors->{$instance} = {
            name => $result->{name},
            remote_port => defined($result->{remote_port}) ? $result->{remote_port} : '',
            local_ifindex => $if_index,
            local_interface => defined($local_interface) && $local_interface ne '' ? $local_interface : $if_index
        };
    }

    return $neighbors;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_cdpGlobalRun ]);
    my $neighbors = get_neighbors(snmp => $options{snmp}, filter_neighbor => $self->{option_results}->{filter_neighbor});

    my $status = 'unknown';
    if (defined($snmp_result->{$oid_cdpGlobalRun}) && defined($map_cdp_run->{ $snmp_result->{$oid_cdpGlobalRun} })) {
        $status = $map_cdp_run->{ $snmp_result->{$oid_cdpGlobalRun} };
    } elsif (scalar(keys %$neighbors) > 0) {
        # some agents do not implement cdpGlobalRun: a filled neighbor cache proves CDP is running
        $status = 'enabled';
    }

    foreach (sort { $neighbors->{$a}->{name} cmp $neighbors->{$b}->{name} } keys %$neighbors) {
        $self->{output}->output_add(long_msg => sprintf(
            "neighbor '%s': remote port '%s', local interface '%s'",
            $neighbors->{$_}->{name},
            $neighbors->{$_}->{remote_port},
            $neighbors->{$_}->{local_interface}
        ));
    }

    $self->{global} = {
        status => $status,
        neighbors => scalar(keys %$neighbors)
    };
}

1;

__END__

=head1 MODE

Check Cisco Discovery Protocol (C<CDP>): global state and number of neighbors (C<CISCO-CDP-MIB>).
Neighbors are listed in the long output (use --verbose).

=over 8

=item B<--filter-neighbor>

Filter neighbors by name (can be a regular expression).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} eq "unknown"').
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "disabled"').
You can use the following variables: %{status}

=item B<--warning-neighbors-count>

Threshold. Use a range to alert under a minimum (example: '2:').

=item B<--critical-neighbors-count>

Threshold. Use a range to alert under a minimum (example: '1:').

=back

=cut
