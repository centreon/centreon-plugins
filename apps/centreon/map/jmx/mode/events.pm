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

package apps::centreon::map::jmx::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

my @map_counters = (
    'OPEN_GATE', 'CLOSE_GATE', 'ADD_RESOURCE', 'POLLER_RESTART', 'UPDATE_RESOURCE',
    'SESSION_EXPIRED', 'UPDATE_ACL_CHILDREN', 'SYNC_CHILDREN', 'REMOVE_CHILD',
    'UPDATE_STATUS_RESOURCE', 'REMOVE_RESOURCE', 'UPDATE_STATUS_INHERITED', 'ADD_CHILD', 'REMOVE_SELF',
    'REMOVE_PARENT', 'ADD_PREFERENCE', 'CREATE_GATE', 'ADD_PARENT', 'UPDATE_ACL', 'REMOVE_PREFERENCE',
    'UPDATE_SELF', 'ADD_SELF', 'DESYNC_CHILDREN', 'UPDATE_PREFERENCE',
);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    foreach my $counter (@map_counters) {
        my $label_perf = lc($counter);
        my $label = lc($counter);
        my $output = lc($counter);
        $label =~ s/_/-/g;
        $output =~ s/_/ /g;
        my $entry = { label => $label . '-rate', set => {
                key_values => [ { name => $counter, per_second => 1 } ],
                output_template => ucfirst($output) . ': %.2f/s',
                perfdatas => [
                    { label => $label_perf . '_rate', template => '%.2f',
                    min => 0, unit => '/s' }
                ]
            }
        };
        push @{$self->{maps_counters}->{global}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $mbean_event = "com.centreon.studio.map:type=event,name=statistics";

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "centreon_map_" . md5_hex($options{custom}->{url}) . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{request} = [
        { mbean => $mbean_event }
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 0);
    
    $self->{global} = {};

    foreach my $counter (keys %{$result->{$mbean_event}->{EventCounter}}) {
        $self->{global}->{$counter} = $result->{$mbean_event}->{EventCounter}->{$counter};
    }
}

1;

__END__

=head1 MODE

Check event types rate.

Example:

perl centreon_plugins.pl --plugin=apps::centreon::map::jmx::plugin --custommode=jolokia
--url=http://10.30.2.22:8080/jolokia-war --mode=events

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='session')

=item B<--warning-*>

Threshold warning.
Can be: 'open-gate-rate', 'close-gate-rate', 'add-resource-rate', 'poller-restart-rate', 'update-resource-rate',
'session-expired-rate', 'update-acl-children-rate', 'sync-children-rate', 'remove-child-rate',
'update-status-resource-rate', 'remove-resource-rate', 'update-status-inherited-rate', 'add-child-rate',
'remove-self-rate',' remove-parent-rate','add-preference-rate', 'create-gate-rate', 'add-parent-rate',
'update-acl-rate', 'remove-preference-rate', 'update-self-rate', 'add-self-rate', 'desync-children-rate',
'update-preference-rate'.

=item B<--critical-*>

Threshold critical.
Can be: 'open-gate-rate', 'close-gate-rate', 'add-resource-rate', 'poller-restart-rate', 'update-resource-rate',
'session-expired-rate', 'update-acl-children-rate', 'sync-children-rate', 'remove-child-rate',
'update-status-resource-rate', 'remove-resource-rate', 'update-status-inherited-rate', 'add-child-rate',
'remove-self-rate',' remove-parent-rate','add-preference-rate', 'create-gate-rate', 'add-parent-rate',
'update-acl-rate', 'remove-preference-rate', 'update-self-rate', 'add-self-rate', 'desync-children-rate',
'update-preference-rate'.

=back

=cut

