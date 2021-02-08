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

package network::athonet::epc::snmp::mode::interfacesgtpc;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "Gtp control interface source '%s' destination '%s' [type: %s] ",
        $options{instance_value}->{source_address},
        $options{instance_value}->{destination_address},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All Gtp control interfaces are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'gtpc.interfaces.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total interfaces: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'status', type => 2, critical_default => '%{status} =~ /down/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'source_address' }, { name => 'destination_address' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-source-address:s'      => { name => 'filter_source_address' },
        'filter-destination-address:s' => { name => 'filter_destination_address' }
    });

    return $self;
}

my $map_status = { 0 => 'down', 1 => 'up' };
my $map_type = { 1 => 'gTPv1', 2 => 'gTPv2', 11 => 'gTPPrime' };

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_status = '.1.3.6.1.4.1.35805.10.2.12.9.1.6'; # gTPcState
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_status,
        nothing_quit => 1
    );

    $self->{interfaces} = {};
    foreach (keys %$snmp_result) {
        /^$oid_status\.(.*)$/;
        my $instance = $1;
        my @indexes = split(/\./, $instance);

        my $source_address = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)) )));
        my $destination_address = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)) )));
        my $type = $map_type->{ $indexes[0] };

        if (defined($self->{option_results}->{filter_source_address}) && $self->{option_results}->{filter_source_address} ne '' &&
            $source_address !~ /$self->{option_results}->{filter_source_address}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $source_address . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_destination_address}) && $self->{option_results}->{filter_destination_address} ne '' &&
            $destination_address !~ /$self->{option_results}->{filter_destination_address}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $destination_address . "': no matching filter.", debug => 1);
            next;
        }

        $self->{interfaces}->{$instance} = {
            source_address => $source_address,
            destination_address => $destination_address,
            type => $type,
            status => $map_status->{ $snmp_result->{$_} }
        };
    }

    $self->{global} = { total => scalar(keys %{$self->{interfaces}}) };
}

1;

__END__

=head1 MODE

Check GTP control interfaces.

=over 8

=item B<--filter-source-address>

Filter interfaces by source address (can be a regexp).

=item B<--filter-destination-address>

Filter interfaces by destination address (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{source_address}, %{destination_address}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{source_address}, %{destination_address}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down/i').
Can used special variables like: %{status}, %{source_address}, %{destination_address}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total'.

=back

=cut
