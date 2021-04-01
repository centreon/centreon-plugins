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

package hardware::devices::polycom::dma::snmp::mode::deviceregistrations;

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
        { label => 'dma-total-registrations', nlabel => 'dma.registrations.count', set => {
                key_values => [ { name => 'useDevRegistrationsCount' } ],
                output_template => 'Total registrations : %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-endpoint-active-registration', nlabel => 'dma.cluster.endpoint.registrations.active.count', set => {
                key_values => [ { name => 'useDevRegActiveEndpointReg' }, { name => 'display'} ],
                output_template => 'endpoint active registrations: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cluster-endpoint-inactive-registration', nlabel => 'dma.cluster.endpoint.registrations.inactive.count', set => {
                key_values => [ { name => 'useDevRegInactiveEndpointReg' }, { name => 'display'} ],
                output_template => 'endpoint inactive registrations: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
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
        'filter-cluster:s' => { name => 'filter_cluster' },
    });
    return $self;
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    useDevRegClusterName            => { oid => '.1.3.6.1.4.1.13885.13.2.3.3.1.2.1.2' },
    useDevRegActiveEndpointReg      => { oid => '.1.3.6.1.4.1.13885.13.2.3.3.1.2.1.3' },
    useDevRegInactiveEndpointReg    => { oid => '.1.3.6.1.4.1.13885.13.2.3.3.1.2.1.4' },
};

my $oid_useDevRegistrationsEntry = '.1.3.6.1.4.1.13885.13.2.3.3.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_useDevRegistrationsCount = '.1.3.6.1.4.1.13885.13.2.3.3.1.1.0';
    my $global_result = $options{snmp}->get_leef(
        oids => [$oid_useDevRegistrationsCount],
        nothing_quit => 1
    );

    $self->{global} = { useDevRegistrationsCount => $global_result->{$oid_useDevRegistrationsCount} };

    $self->{cluster} = {};
    my $cluster_result = $options{snmp}->get_table(
        oid => $oid_useDevRegistrationsEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$cluster_result}) {
        next if ($oid !~ /^$mapping->{useDevRegClusterName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $cluster_result, instance => $instance);

        $result->{useDevRegClusterName} = centreon::plugins::misc::trim($result->{useDevRegClusterName});
        if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '' &&
            $result->{useDevRegClusterName} !~ /$self->{option_results}->{filter_cluster}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{useDevRegClusterName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{cluster}->{$instance} = {
            display => $result->{useDevRegClusterName},
            %$result
        };
    }
}

1;

__END__

=head1 MODE

Check global and per-cluster devices registrations metrics.

=over 8

=item B<--filter-cluster>

Filter on one or several cluster (POSIX regexp)

=item B<--warning-* --critical-*>

Warning & Critical Thresholds. Possible values:

[PER-CLUSTER] cluster-endpoint-active-registration cluster-endpoint-inactive-registration

[GLOBAL] dma-total-registrations

=back

=cut
