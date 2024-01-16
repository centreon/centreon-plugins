#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package network::vectra::restapi::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "interface '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', cb_prefix_output => 'prefix_interface_output', message_multiple => 'All interfaces are ok', type => 1, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'interface-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'interface-peak-traffic', nlabel => 'interface.traffic.peak.bitspersecond', set => {
                key_values => [ { name => 'peakTraffic' }, { name => 'name' } ],
                output_template => 'peak traffic: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => $self->{result_values}->{name},
                        value => $self->{result_values}->{peakTraffic},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

     $options{options}->add_options(arguments => {
        'filter-interface-name:s' => { name => 'filter_interface_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/health/network');

    $self->{interfaces} = {};
    foreach my $interface_name (keys %{$result->{network}->{interfaces}->{brain}}) {
        next if (defined($self->{option_results}->{filter_interface_name}) && $self->{option_results}->{filter_interface_name} ne '' &&
            $interface_name !~ /$self->{option_results}->{filter_interface_name}/);

        $self->{interfaces}->{$interface_name} = {
            name => $interface_name,
            status => lc($result->{network}->{interfaces}->{brain}->{$interface_name}->{link})
        };

        if (defined($result->{network}->{traffic}->{brain}->{interface_peak_traffic}->{$interface_name})) {
            $self->{interfaces}->{$interface_name}->{peakTraffic} =
                $result->{network}->{traffic}->{brain}->{interface_peak_traffic}->{$interface_name}->{peak_traffic_mbps} * 1000 * 1000;
        }
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--filter-interface-name>

Filter interfaces by name (can be a regexp).

=item B<--unknown-interface-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--warning-interface-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-interface-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /down/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds. Can be:
'interface-peak-traffic'.

=back

=cut
