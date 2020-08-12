#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package hardware::devices::polycom::dma::snmp::mode::conferencemanager;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok', skipped_code => { -10 => 1 } }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-conferences', nlabel => 'manager.conferences.active.count', set => {
                key_values => [ { name => 'useConfMgrUsageCount' } ],
                output_template => 'Current conferences (total): %s',
                perfdatas => [
                    { label => 'conferences', value => 'useConfMgrUsageCount', template => '%d', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-conferences', nlabel => 'cluster.conferences.active.count', set => {
                key_values => [ { name => 'useCMUsageActiveConfs' }, { name => 'display'} ],
                output_template => 'current conferences : %s',
                perfdatas => [
                    { label => 'conferences_active', value => 'useCMUsageActiveConfs', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'cluster-participants', nlabel => 'cluster.conferences.active.count', set => {
                key_values => [ { name => 'useCMUsageActiveParts' }, { name => 'display'} ],
                output_template => 'current participants : %s',
                perfdatas => [
                    { label => 'participants', value => 'useCMUsageActiveParts', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'cluster-local-users', nlabel => 'cluster.local.database.users.count', set => {
                key_values => [ { name => 'useCMUsageLocalUsers' }, { name => 'display'} ],
                output_template => 'local users : %s',
                perfdatas => [
                    { label => 'local_users', value => 'useCMUsageLocalUsers', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'cluster-custom-rooms', nlabel => 'cluster.custom.conference.rooms.count', set => {
                key_values => [ { name => 'useCMUsageCustomConfRooms' }, { name => 'display'} ],
                output_template => 'custom conference rooms : %s',
                perfdatas => [
                    { label => 'custom_rooms', value => 'useCMUsageCustomConfRooms', template => '%d', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });
    return $self;
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    useCMUsageClusterName       => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.2' },
    useCMUsageActiveConfs       => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.3' },
    useCMUsageActiveParts       => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.4' },
    useCMUsageTotalVideoPorts   => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.5' },
    useCMUsageUsedVideoPorts    => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.6' },
    useCMUsageTotalVoicePorts   => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.7' },
    useCMUsageUsedVoicePorts    => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.8' },
    useCMUsageLocalUsers        => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.9' },
    useCMUsageCustomConfRooms   => { oid => '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1.10' },
};

my $oid_useConfMgrUsageEntry = '.1.3.6.1.4.1.13885.13.2.3.2.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;



    my $oid_useConfMgrUsageCount = '.1.3.6.1.4.1.13885.13.2.3.2.1.1.0';
    my $global_result = $options{snmp}->get_leef(oids => [$oid_useConfMgrUsageCount], nothing_quit => 1);

    $self->{global} = { useConfMgrUsageCount => $global_result->{$oid_useConfMgrUsageCount} };

    $self->{cluster} = {};
    my $cluster_result = $options{snmp}->get_table(
        oid => $oid_useConfMgrUsageEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$cluster_result}) {
        next if ($oid !~ /^$mapping->{useCMUsageClusterName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $cluster_result, instance => $instance);

        $result->{useCMUsageClusterName} = centreon::plugins::misc::trim($result->{useCMUsageClusterName});
        if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '' &&
            $result->{useCMUsageClusterName} !~ /$self->{option_results}->{filter_cluster}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{useCMUsageClusterName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{cluster}->{$instance} = {
            display => $result->{useCMUsageClusterName}, 
            %$result,
        };
    }

}

1;

__END__

=head1 MODE

Check Global and per-cluster conference manager metrics usage.

=over 8

=item B<--warning-TODO>

Threshold warning.

=item B<--critical-TODO>

Threshold critical.

=back

=cut
