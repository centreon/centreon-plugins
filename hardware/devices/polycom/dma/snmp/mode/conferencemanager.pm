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

package hardware::devices::polycom::dma::snmp::mode::conferencemanager;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_video_port_output {
    my ($self, %options) = @_;

    return sprintf(
        'video ports [total: %s used: %s (%.2f%%) free: %s (%.2f%%)]',
        $self->{result_values}->{vp_total},
        $self->{result_values}->{vp_used},
        $self->{result_values}->{vp_prct_used},
        $self->{result_values}->{vp_free},
        $self->{result_values}->{vp_prct_free}
    );
}

sub custom_voice_port_output {
    my ($self, %options) = @_;

    return sprintf(
        'voice ports [total: %s used: %s (%.2f%%) free: %s (%.2f%%)]',
        $self->{result_values}->{vop_total},
        $self->{result_values}->{vop_used},
        $self->{result_values}->{vop_prct_used},
        $self->{result_values}->{vop_free},
        $self->{result_values}->{vop_prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'dma-total-conferences', nlabel => 'dma.conferences.active.count', set => {
                key_values => [ { name => 'useConfMgrUsageCount' } ],
                output_template => 'Total conferences : %s',
                perfdatas => [
                    { template => '%d', min => 0, instance_use => 'display', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-conferences', nlabel => 'dma.cluster.conferences.active.count', set => {
                key_values => [ { name => 'useCMUsageActiveConfs' }, { name => 'display' } ],
                output_template => 'current conferences : %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-participants', nlabel => 'dma.cluster.participants.active.count', set => {
                key_values => [ { name => 'useCMUsageActiveParts' }, { name => 'display' } ],
                output_template => 'current participants : %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-local-users', nlabel => 'dma.cluster.local.database.users.count', set => {
                key_values => [ { name => 'useCMUsageLocalUsers' }, { name => 'display' } ],
                output_template => 'local users : %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-custom-rooms', nlabel => 'dma.cluster.custom.conference.rooms.count', set => {
                key_values => [ { name => 'useCMUsageCustomConfRooms' }, { name => 'display' } ],
                output_template => 'custom conference rooms : %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-video-ports-usage', nlabel => 'dma.cluster.video.port.usage.count', set => {
                key_values => [
                    { name => 'vp_used' }, { name => 'vp_free' }, { name => 'vp_prct_used' }, 
                    { name => 'vp_prct_free' }, { name => 'vp_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_video_port_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-video-ports-free', display_ok => 0, nlabel => 'dma.cluster.video.port.free.count', set => {
                key_values => [
                    { name => 'vp_free' }, { name => 'vp_used' }, { name => 'vp_prct_used' },
                    { name => 'vp_prct_free' }, { name => 'vp_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_video_port_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-video-ports-prct', display_ok => 0, nlabel => 'dma.cluster.video.port.percentage', set => {
                key_values => [ { name => 'vp_prct_used' }, { name => 'display' } ],
                output_template => 'video ports used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-voice-ports-usage', nlabel => 'dma.cluster.voice.port.usage.count', set => {
                key_values => [
                    { name => 'vop_used' }, { name => 'vop_free' }, { name => 'vop_prct_used' },
                    { name => 'vop_prct_free' }, { name => 'vop_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_voice_port_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-voice-ports-free', display_ok => 0, nlabel => 'dma.cluster.voice.port.free.count', set => {
                key_values => [
                    { name => 'vop_free' }, { name => 'vop_used' }, { name => 'vop_prct_used' },
                    { name => 'vop_prct_free' }, { name => 'vop_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_voice_port_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-voice-ports-prct', display_ok => 0, nlabel => 'dma.cluster.voice.port.percentage', set => {
                key_values => [ { name => 'vop_prct_used' }, { name => 'display' } ],
                output_template => 'voice ports used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
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
        'filter-cluster:s' => { name => 'filter_cluster' }
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

        my ($video_port_used, $video_port_total) = ($result->{useCMUsageUsedVideoPorts},$result->{useCMUsageTotalVideoPorts});
        my ($voice_port_used, $voice_port_total) = ($result->{useCMUsageUsedVoicePorts},$result->{useCMUsageTotalVoicePorts});

        $self->{cluster}->{$instance} = {
            display => $result->{useCMUsageClusterName},
            vp_free => $video_port_total - $video_port_used,
            vp_prct_free => ($video_port_total != 0) ? 100 - ($video_port_used * 100 / $video_port_total) : '0',
            vp_prct_used => ($video_port_total != 0) ? $video_port_used * 100 / $video_port_total : '0',
            vp_total => $video_port_total,
            vp_used => $video_port_used,
            vop_free => $voice_port_total - $voice_port_used,
            vop_prct_free => ($voice_port_total != 0) ? 100 - ($voice_port_used * 100 / $voice_port_total) : '0',
            vop_prct_used => ($voice_port_total != 0) ? $voice_port_used * 100 / $voice_port_total : '0',
            vop_total => $voice_port_total,
            vop_used => $voice_port_used,
            %$result,
        };
    }

}

1;

__END__

=head1 MODE

Check conferences metrics.

=over 8

=item B<--filter-cluster>

Filter on one or several cluster (POSIX regexp)

=item B<--warning-* --critical-*>

TWarning & Critical Thresholds. Possible values:
[PER-CLUSTER] cluster-conferences, cluster-participants, cluster-local-users, cluster-custom-rooms,
cluster-video-ports-usage, cluster-video-ports-free, cluster-video-ports-prct,
cluster-voice-ports-usage, cluster-voice-ports-free, cluster-voice-ports-prct

[GLOBAL] dma-total-conferences

=back

=cut
