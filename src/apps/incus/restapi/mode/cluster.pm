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

package apps::incus::restapi::mode::cluster;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters :values);

# GET /1.0/cluster metadata, shortened: {"enabled":true,"server_name":"server01"}
# GET /1.0/cluster/members?recursion=1 entry, shortened:
# {"server_name":"server01","status":"Online","message":"fully operational"}
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml

sub cluster_plan {
    my ($cluster) = @_;

    if (ref($cluster) ne 'HASH' || !exists($cluster->{enabled})) {
        return { exit => 'unknown', fetch_members => 0, message => 'cluster enabled flag missing' };
    }
    if (!$cluster->{enabled}) {
        return { exit => 'ok', fetch_members => 0, message => 'clustering disabled' };
    }
    return { exit => 'ok', fetch_members => 1, message => '' };
}

sub cluster_members_exit {
    my ($members) = @_;

    my $offline = 0;
    foreach my $member (@{$members // []}) {
        my $status = defined($member->{status}) ? $member->{status} : '';
        $offline++ if ($status ne 'Online');
    }
    if ($offline > 0) {
        return { exit => 'critical', offline => $offline, message => 'cluster member not Online' };
    }
    return { exit => 'ok', offline => 0, message => 'all cluster members are Online' };
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
        { name => 'cluster', type => COUNTER_TYPE_GLOBAL, prefix_output => 'cluster ', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'offline', nlabel => 'incus.cluster.members.offline.count', set => {
                key_values => [ { name => 'offline' } ],
                output_template => 'offline: %s',
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

    my $cluster = $options{custom}->cluster();
    my $plan = cluster_plan($cluster);
    if ($plan->{exit} eq 'unknown') {
        $self->{output}->option_exit(short_msg => $plan->{message});
    }

    my $decision;
    if (!$plan->{fetch_members}) {
        $decision = { exit => 'ok', message => $plan->{message} };
    } else {
        my $members = $options{custom}->cluster_members();
        my $kept = $options{custom}->filter_records(records => $members, name_key => 'server_name');
        $decision = cluster_members_exit($kept);
    }

    $self->{cluster} = {
        exit => $decision->{exit},
        message => $decision->{message}
    };
    $self->{cluster}->{offline} = $decision->{offline} if (defined($decision->{offline}));
}

1;

__END__

=head1 MODE

Check clustering from GET /1.0/cluster.

When enabled is false the state is OK, "clustering disabled", and
GET /1.0/cluster/members is not called. Otherwise a member whose status is
not Online is critical. The spec example for that status is Online.
There is no --warning-status option: the exit is decided from the member
status, not from a threshold expression.

=over 8

=item B<--warning-offline>

Warning threshold for the number of members that are not Online. Empty by default.
Published only when clustering is enabled.

=item B<--critical-offline>

Critical threshold for the number of members that are not Online. Empty by default.
Published only when clustering is enabled.

=back

=cut
