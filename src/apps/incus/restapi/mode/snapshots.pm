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

package apps::incus::restapi::mode::snapshots;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use apps::incus::restapi::custom::api;
use centreon::plugins::constants qw(:counters :values);

# GET /1.0/instances?recursion=2 snapshot entry, shortened:
# {"name":"snap0","created_at":"2021-03-23T17:38:37.753398689-04:00"}
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml

sub instance_id {
    my ($instance) = @_;

    return join('/', map { defined($_) ? $_ : '' } ($instance->{project}, $instance->{name}, $instance->{location}));
}

sub snapshot_summary {
    my ($snapshots, $now) = @_;

    my $count = scalar(@{$snapshots // []});
    my $newest;
    foreach my $snapshot (@{$snapshots // []}) {
        my $epoch = apps::incus::restapi::custom::api::rfc3339_epoch($snapshot->{created_at});
        next if (!defined($epoch));
        my $age = $now - $epoch;
        $newest = $age if (!defined($newest) || $age < $newest);
    }
    return { count => $count, newest_age => $newest };
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
        { name => 'instance', type => COUNTER_TYPE_INSTANCE, prefix_output => "instance '%{display}' ", message_multiple => 'all instance snapshots are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{instance} = [
        { label => 'snapshots', nlabel => 'incus.snapshots.count', set => {
                key_values => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'snapshots: %s',
                perfdatas => [ { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'newest-age', nlabel => 'incus.snapshots.newest.age.seconds', set => {
                key_values => [ { name => 'newest_age' }, { name => 'display' } ],
                output_template => 'newest age: %s s',
                output_use => 'newest_age',
                perfdatas => [ { value => 'newest_age', template => '%d', min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->instances(recursion => 2);
    my $instances = $options{custom}->filter_records(records => $metadata, name_key => 'name');
    my $now = time();
    $self->{instance} = {};
    foreach my $instance (@$instances) {
        my $snapshots = (ref($instance->{snapshots}) eq 'ARRAY') ? $instance->{snapshots} : [];
        my $summary = snapshot_summary($snapshots, $now);
        my %entry = (
            display => defined($instance->{name}) ? $instance->{name} : '',
            count => $summary->{count}
        );
        $entry{newest_age} = $summary->{newest_age} if (defined($summary->{newest_age}));
        $self->{instance}->{instance_id($instance)} = \%entry;
    }
}

1;

__END__

=head1 MODE

Count snapshots and the age of the newest one per instance, from
GET /1.0/instances?recursion=2. Thresholds are empty by default.
The newest age is omitted when no snapshot has a parseable created_at.

=over 8

=item B<--warning-snapshots>

Warning threshold for the number of snapshots of an instance.

=item B<--critical-snapshots>

Critical threshold for the number of snapshots of an instance.

=item B<--warning-newest-age>

Warning threshold for the age of the newest snapshot of an instance, in seconds.

=item B<--critical-newest-age>

Critical threshold for the age of the newest snapshot of an instance, in seconds.

=back

=cut
