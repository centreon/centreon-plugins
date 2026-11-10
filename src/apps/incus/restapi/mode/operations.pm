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

package apps::incus::restapi::mode::operations;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use apps::incus::restapi::custom::api;
use centreon::plugins::constants qw(:counters :values);

# GET /1.0/operations?recursion=1 is grouped by status class, shortened:
# {"running":[{"id":"6916c8a6-9b7d-4abd-90b3-aedfec7ec7da","status":"Running",
#   "created_at":"2021-03-23T17:38:37.753398689-04:00"}],"success":[],"failure":[]}
# Operation.status example: Running. created_at is the operation creation time.
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml

sub operations_summary {
    my ($operations, $now) = @_;

    my $count = 0;
    my $oldest;
    foreach my $operation (@{$operations // []}) {
        next if (!defined($operation->{status}) || $operation->{status} ne 'Running');
        $count++;
        my $epoch = apps::incus::restapi::custom::api::rfc3339_epoch($operation->{created_at});
        next if (!defined($epoch));
        my $age = $now - $epoch;
        $oldest = $age if (!defined($oldest) || $age > $oldest);
    }
    return { count => $count, oldest_age => $oldest };
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
        { name => 'operations', type => COUNTER_TYPE_GLOBAL, prefix_output => 'operations ', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{operations} = [
        { label => 'running', nlabel => 'incus.operations.running.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'running: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'oldest-age', nlabel => 'incus.operations.oldest.age.seconds', set => {
                key_values => [ { name => 'oldest_age' } ],
                output_template => 'oldest age: %s s',
                output_use => 'oldest_age',
                perfdatas => [ { value => 'oldest_age', template => '%d', min => 0, unit => 's' } ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->operations();
    my $operations = $options{custom}->filter_records(records => $metadata, name_key => 'id');
    my $summary = operations_summary($operations, time());
    my %entry = (count => $summary->{count});
    $entry{oldest_age} = $summary->{oldest_age} if (defined($summary->{oldest_age}));
    $self->{operations} = \%entry;
}

1;

__END__

=head1 MODE

Count operations whose status is Running, and the age of the oldest one,
from GET /1.0/operations?recursion=1. The spec example for that status is
Running. Thresholds are empty by default. The oldest age is omitted when no
running operation has a parseable created_at.

=over 8

=item B<--warning-running>

Warning threshold for the number of running operations.

=item B<--critical-running>

Critical threshold for the number of running operations.

=item B<--warning-oldest-age>

Warning threshold for the age of the oldest running operation, in seconds.

=item B<--critical-oldest-age>

Critical threshold for the age of the oldest running operation, in seconds.

=back

=cut
