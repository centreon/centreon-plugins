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

package apps::centreon::map::jmx::mode::syncstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON::XS;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'centreon', type => 0, cb_prefix_output => 'prefix_output_centreon' },
        { name => 'acl', type => 1, cb_prefix_output => 'prefix_output_acl',
          message_multiple => 'All ACL synchronizations metrics are ok' },
        { name => 'resource', type => 1, cb_prefix_output => 'prefix_output_resource',
          message_multiple => 'All resource synchronizations metrics are ok' },
    ];

    $self->{maps_counters}->{centreon} = [
        { label => 'map-synchronization-centreon-count',
          nlabel => 'map.synchronization.centreon.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Count: %d',
                perfdatas => [
                    { label => 'map.synchronization.centreon.count', value => 'count', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'map-synchronization-centreon-duration-average-milliseconds',
          nlabel => 'map.synchronization.centreon.duration.average.milliseconds', set => {
                key_values => [ { name => 'average' } ],
                output_template => 'Average Duration: %.2f ms',
                perfdatas => [
                    { label => 'map.synchronization.centreon.duration.average.milliseconds', value => 'average',
                      template => '%.2f', min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'map-synchronization-centreon-duration-max-milliseconds',
          nlabel => 'map.synchronization.centreon.duration.max.milliseconds', set => {
                key_values => [ { name => 'max' } ],
                output_template => 'Max Duration: %.2f ms',
                perfdatas => [
                    { label => 'map.synchronization.centreon.duration.max.milliseconds', value => 'max',
                      template => '%.2f', min => 0, unit => 'ms' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{acl} = [
        { label => 'map-synchronization-acl-count',
          nlabel => 'map.synchronization.acl.count', set => {
                key_values => [ { name => 'count' }, { name => 'name' } ],
                output_template => 'Count: %d',
                perfdatas => [
                    { label => 'map.synchronization.acl.count', value => 'count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'map-synchronization-acl-duration-average-milliseconds',
          nlabel => 'map.synchronization.acl.duration.average.milliseconds', set => {
                key_values => [ { name => 'average' }, { name => 'name' } ],
                output_template => 'Average Duration: %.2f ms',
                perfdatas => [
                    { label => 'map.synchronization.acl.duration.average.milliseconds', value => 'average',
                      template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'map-synchronization-acl-duration-max-milliseconds',
          nlabel => 'map.synchronization.acl.duration.max.milliseconds', set => {
                key_values => [ { name => 'max' }, { name => 'name' } ],
                output_template => 'Max Duration: %.2f ms',
                perfdatas => [
                    { label => 'map.synchronization.acl.duration.max.milliseconds', value => 'max',
                      template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{resource} = [
        { label => 'map-synchronization-resource-count',
          nlabel => 'map.synchronization.resource.count', set => {
                key_values => [ { name => 'count' }, { name => 'name' } ],
                output_template => 'Count: %d',
                perfdatas => [
                    { label => 'map.synchronization.resource.count', value => 'count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'map-synchronization-resource-duration-average-milliseconds',
          nlabel => 'map.synchronization.resource.duration.average.milliseconds', set => {
                key_values => [ { name => 'average' }, { name => 'name' } ],
                output_template => 'Average Duration: %.2f ms',
                perfdatas => [
                    { label => 'map.synchronization.resource.duration.average.milliseconds', value => 'average',
                      template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'map-synchronization-resource-duration-max-milliseconds',
          nlabel => 'map.synchronization.resource.duration.max.milliseconds', set => {
                key_values => [ { name => 'max' }, { name => 'name' } ],
                output_template => 'Max Duration: %.2f ms',
                perfdatas => [
                    { label => 'map.synchronization.resource.duration.max.milliseconds', value => 'max',
                      template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
    ];
}

sub prefix_output_centreon {
    my ($self, %options) = @_;

    return "Centreon Synchronization ";
}

sub prefix_output_acl {
    my ($self, %options) = @_;

    return "ACL Synchronization '" . $options{instance_value}->{name} . "' ";
}

sub prefix_output_resource {
    my ($self, %options) = @_;

    return "Resource Synchronization '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $mbean_engine = "com.centreon.studio.map:type=synchronizer,name=statistics";

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
        { mbean => $mbean_engine }
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 0);
    
    $self->{centreon} = {};
    $self->{acl} = {};
    $self->{resource} = {};

    my $decoded_centreon_stats;
    my $decoded_acl_stats;
    my $decoded_resource_stats;
    eval {
        $decoded_centreon_stats = JSON::XS->new->utf8->decode($result->{$mbean_engine}->{CentreonSyncStatistics});
        $decoded_acl_stats = JSON::XS->new->utf8->decode($result->{$mbean_engine}->{AclSyncStatistics});
        $decoded_resource_stats = JSON::XS->new->utf8->decode($result->{$mbean_engine}->{ResourceSyncStatistics});
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $result, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    $self->{centreon} = {
        count => $decoded_centreon_stats->{count},
        average => $decoded_centreon_stats->{average},
        max => ($decoded_centreon_stats->{count} == 0) ? 0 : $decoded_centreon_stats->{max},
    };

    foreach my $name (keys %{$decoded_acl_stats}) {
        $self->{acl}->{$name}= {
            name => $name,
            count => $decoded_acl_stats->{$name}->{count},
            average => $decoded_acl_stats->{$name}->{average},
            max => ($decoded_acl_stats->{$name}->{count} == 0) ? 0 : $decoded_acl_stats->{$name}->{max},
        };
    }

    foreach my $name (keys %{$decoded_resource_stats}) {
        $self->{resource}->{$name}= {
            name => $name,
            count => $decoded_resource_stats->{$name}->{count},
            average => $decoded_resource_stats->{$name}->{average},
            max => ($decoded_resource_stats->{$name}->{count} == 0) ? 0 : $decoded_resource_stats->{$name}->{max},
        };
    }
}

1;

__END__

=head1 MODE

Check synchronizer statistics.

Example:

perl centreon_plugins.pl --plugin=apps::centreon::map::jmx::plugin --custommode=jolokia
--url=http://10.30.2.22:8080/jolokia-war --mode=sync-stats

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='centreon')

=item B<--warning-*>

Threshold warning.
Can be: 'map-synchronization-centreon-count',
'map-synchronization-centreon-duration-average-milliseconds',
'map-synchronization-centreon-duration-max-milliseconds'.

=item B<--critical-*>

Threshold critical.
Can be: 'map-synchronization-centreon-count',
'map-synchronization-centreon-duration-average-milliseconds',
'map-synchronization-centreon-duration-max-milliseconds'.

=item B<--warning-instance-*>

Threshold warning.
Can be: 'map-synchronization-acl-count', 'map-synchronization-acl-duration-average-milliseconds',
'map-synchronization-acl-duration-max-milliseconds', 'map-synchronization-resource-count',
'map-synchronization-resource-duration-average-milliseconds',
'map-synchronization-resource-duration-max-milliseconds'.

=item B<--critical-instance-*>

Threshold critical.
Can be: 'map-synchronization-acl-count', 'map-synchronization-acl-duration-average-milliseconds',
'map-synchronization-acl-duration-max-milliseconds', 'map-synchronization-resource-count',
'map-synchronization-resource-duration-average-milliseconds',
'map-synchronization-resource-duration-max-milliseconds'.

=back

=cut

