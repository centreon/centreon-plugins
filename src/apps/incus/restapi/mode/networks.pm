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

package apps::incus::restapi::mode::networks;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters);

# GET /1.0/networks?recursion=1 entry, shortened:
# {"name":"mybr0","type":"bridge","managed":true,"status":"Created",
#  "used_by":["/1.0/profiles/default","/1.0/instances/c1"]}
# Network.status: "The state of the network (for managed network in clusters)", example Created.
# No failure value is documented. StoragePool.status is a different enum.
# On Incus 7.3 the observed values were Created and an empty string.
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml

sub network_status_is_failure {
    my ($status) = @_;

    return 0 if (!defined($status) || $status eq '');
    return 0;
}

sub network_decision {
    my ($networks) = @_;

    my @failures;
    my $used_by = 0;
    foreach my $network (@{$networks // []}) {
        my $status = defined($network->{status}) ? $network->{status} : '';
        if ($status ne '' && network_status_is_failure($status)) {
            push @failures, $network;
        }
        $used_by += scalar(@{$network->{used_by}}) if (ref($network->{used_by}) eq 'ARRAY');
    }

    my $message = 'ok';
    if (@failures) {
        $message = 'network status failed: ' . join(', ', map { defined($_->{name}) ? $_->{name} : '' } @failures);
    }
    return {
        networks => scalar(@{$networks // []}),
        used_by => $used_by,
        failures => \@failures,
        exit => @failures ? 'critical' : 'ok',
        message => $message
    };
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'networks', type => COUNTER_TYPE_GLOBAL, prefix_output => 'networks ' }
    ];

    $self->{maps_counters}->{networks} = [
        { label => 'networks', nlabel => 'incus.networks.count', set => {
                key_values => [ { name => 'networks' } ],
                output_template => 'networks: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'used-by', nlabel => 'incus.networks.used_by.count', set => {
                key_values => [ { name => 'used_by' } ],
                output_template => 'used by: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'status', type => COUNTER_KIND_TEXT, threshold => 0, set => {
                key_values => [ { name => 'exit' }, { name => 'message' } ],
                output_template => '%s',
                output_use => 'message',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold')
            }
        }
    ];
}

sub custom_status_threshold {
    my ($self, %options) = @_;

    return $self->{result_values}->{exit} // 'ok';
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->networks();
    my $networks = $options{custom}->filter_records(records => $metadata, name_key => 'name');
    my $decision = network_decision($networks);
    $self->{networks} = {
        networks => $decision->{networks},
        used_by => $decision->{used_by},
        exit => $decision->{exit},
        message => $decision->{message}
    };
}

1;

__END__

=head1 MODE

Check networks from GET /1.0/networks?recursion=1.

An empty status is ok. The OpenAPI example for Network.status is Created.
The specification does not document a failure value for this field, so no
status string raises an alert. Perfdata are the number of networks and the
number of used_by objects. Thresholds on those counts are empty by default.
There is no --warning-status option: no documented status string is a failure.

=over 8

=item B<--warning-networks>

Warning threshold for the number of networks.

=item B<--critical-networks>

Critical threshold for the number of networks.

=item B<--warning-used-by>

Warning threshold for the number of used_by objects.

=item B<--critical-used-by>

Critical threshold for the number of used_by objects.

=back

=cut
