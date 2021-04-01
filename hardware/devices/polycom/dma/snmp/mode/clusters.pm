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

package hardware::devices::polycom::dma::snmp::mode::clusters;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'dma-total-clusters', nlabel => 'dma.clusters.total.count', set => {
                key_values => [ { name => 'clusters_count' } ],
                output_template => 'Total clusters : %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
    ];

    $self->{maps_counters}->{cluster} = [
        {
            label => 'cluster-status',
            type => 2,
            critical_default => '%{cluster_status} =~ /outOfService/i',
            display_ok => 0,
            set => {
                key_values => [ { name => 'cluster_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_cluster_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'license-status',
            type => 2,
            critical_default => '%{license_status} =~ /invalid/i',
            display_ok => 0,
            set => {
                key_values => [ { name => 'license_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_license_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'cluster-active-calls', nlabel => 'dma.cluster.activecalls.count', set => {
                key_values => [ { name => 'active_calls' }, { name => 'licenses_total' }, { name => 'display' } ],
                output_template => 'Active calls : %s',
                perfdatas => [
                    { template => '%s', max => 'licenses_total', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-license-usage-free', nlabel => 'dma.cluster.licenses.free.count', set => {
                key_values => [ { name => 'licenses_free' }, { name => 'display' } ],
                output_template => 'Free licenses : %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-license-usage-prct', nlabel => 'dma.cluster.licenses.usage.percentage', set => {
                key_values => [ { name => 'licenses_used_prct' }, { name => 'display' } ],
                output_template => 'Licenses percentage usage : %.2f%%',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' ";
}

sub custom_cluster_status_output {
    my ($self, %options) = @_;

    return sprintf('Cluster status: %s',  $self->{result_values}->{cluster_status});
}

sub custom_license_status_output {
    my ($self, %options) = @_;

    return sprintf('License status: %s', $self->{result_values}->{license_status});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-cluster:s'          => { name => 'filter_cluster' }
    });

    return $self;
}

my %map_cluster_status   = (1 => 'inService', 2 => 'busyOut', 3 => 'outOfService');
my %map_licensing_status = (1 => 'valid', 2 => 'invalid', 3 => 'notInstalled');

my $mapping_status = {
    stClClusterName   => { oid => '.1.3.6.1.4.1.13885.13.2.2.3.2.1.2' },
    stClClusterStatus => { oid => '.1.3.6.1.4.1.13885.13.2.2.3.2.1.3', map => \%map_cluster_status }
};

my $mapping_licenses = {
    stLicClusterName           => { oid => '.1.3.6.1.4.1.13885.13.2.2.3.3.1.2' },
    stLicLicenseStatus         => { oid => '.1.3.6.1.4.1.13885.13.2.2.3.3.1.3', map => \%map_licensing_status},
    stLicLicensedCalls         => { oid => '.1.3.6.1.4.1.13885.13.2.2.3.3.1.4' },
    stLicCallserverActiveCalls => { oid => '.1.3.6.1.4.1.13885.13.2.2.3.3.1.5' }
};

my $oid_stClustersEntry = '.1.3.6.1.4.1.13885.13.2.2.3.2.1';
my $oid_stLicensesEntry = '.1.3.6.1.4.1.13885.13.2.2.3.3.1';

my $oid_stClustersCount = '.1.3.6.1.4.1.13885.13.2.2.3.1.0'; #global

sub manage_selection {
    my ($self, %options) = @_;

    my $global_result = $options{snmp}->get_leef(
        oids => [ $oid_stClustersCount ],
        nothing_quit => 1
    );

    $self->{global} = { clusters_count => $global_result->{$oid_stClustersCount} };

    $self->{clusters_result} = {};
    $self->{clusters_result} = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_stClustersEntry },
            { oid => $oid_stLicensesEntry }
        ],
        nothing_quit => 1
    );

    foreach my $oid (keys %{$self->{clusters_result}->{$oid_stClustersEntry}}) {
        next if ($oid !~ /^$mapping_status->{stClClusterName}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result_status   = $options{snmp}->map_instance(mapping => $mapping_status, results => $self->{clusters_result}->{$oid_stClustersEntry}, instance => $instance);
        my $result_licenses = $options{snmp}->map_instance(mapping => $mapping_licenses, results => $self->{clusters_result}->{$oid_stLicensesEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '' &&
            $result_status->{stClClusterName} !~ /$self->{option_results}->{filter_cluster}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result_status->{stClClusterName} . "': no matching filter.", debug => 1);
            next;
        }

        my ($licenses_used, $licenses_total) = ($result_licenses->{stLicCallserverActiveCalls}, $result_licenses->{stLicLicensedCalls});
        my $licenses_free = $licenses_total - $licenses_used;

        $self->{cluster}->{$instance} = {
            display => $result_status->{stClClusterName},
            cluster_status => $result_status->{stClClusterStatus},
            active_calls  => $result_licenses->{stLicCallserverActiveCalls},
            license_status => $result_licenses->{stLicLicenseStatus},
            licenses_total => $licenses_total,
            licenses_free => $licenses_free,
            licenses_used_prct => ( $licenses_used * 100 ) / $licenses_total
        };
    }
}

1;

__END__

=head1 MODE

Check information about clusters in the Polycom DMA supercluster.

=over 8

=item B<--filter-cluster>

Filter on one or several cluster (POSIX regexp)

=item B<--warning-cluster-status>

Custom Warning threshold of the cluster state (Default: none)
Syntax: --warning-cluster-status='%{cluster_status} =~ /busyOut/i'


=item B<--critical-cluster-status>

Custom Critical threshold of the cluster state
(Default: '%{cluster_status} =~ /outOfService/i' )
Syntax: --critical-cluster-status='%{cluster_status} =~ /busyOut/i'


=item B<--warning-license-status>

Custom Warning threshold of the cluster license state (Default: none)
Syntax: --warning-license-status='%{license_status} =~ /notinstalled/i'


=item B<--critical-license-status>

Custom Critical threshold of the cluster license state
(Default: '%{license_status} =~ /invalid/i')
Syntax: --critical-license-status='%{license_status} =~ /notinstalled/i'

=item B<--warning-* --critical-*>

Warning & Critical Thresholds for the collected metrics. Possible values:

[PER-CLUSTER] cluster-active-calls cluster-license-usage-free cluster-license-usage-prct

[GLOBAL] dma-total-clusters

=back

=cut


