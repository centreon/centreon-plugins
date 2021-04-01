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

package storage::netapp::ontap::snmp::mode::failover;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_cluster_output {
    my ($self, %options) = @_;

    return sprintf(
        "cluster status is '%s' [partner status: %s][reason cannot takeover: %s]",
        $self->{result_values}->{cluster_status},
        $self->{result_values}->{partner_status},
        $self->{result_values}->{reason_cannot_takeover}
    );
}

sub custom_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [partner status: %s][reason cannot takeover: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{partner_status},
        $self->{result_values}->{reason_cannot_takeover}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All high-availability nodes are OK' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cluster-status', set => {
                key_values => [ { name => 'cluster_status' }, { name => 'reason_cannot_takeover' }, { name => 'partner_status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_cluster_output'),
                closure_custom_threshold_check => \&catalog_status_threshold,
                closure_custom_perfdata => sub { return 0; },
            }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'node-status', threshold => 0,  set => {
                key_values => [ { name => 'status' }, { name => 'reason_cannot_takeover' }, { name => 'partner_status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_node_output'),
                closure_custom_threshold_check => \&catalog_status_threshold,
                closure_custom_perfdata => sub { return 0; },
            }
        }
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-node:s'             => { name => 'filter_node' },
        'unknown-cluster-status:s'  => { name => 'unknown_cluster_status', default => '' },
        'warning-cluster-status:s'  => { name => 'warning_cluster_status', default => '%{cluster_status} =~ /^takeover|partialGiveback/i' },
        'critical-cluster-status:s' => { name => 'critical_cluster_status', default => '%{cluster_status} =~ /dead|cannotTakeover/i' },
        'unknown-node-status:s'     => { name => 'unknown_node_status', default => '' },
        'warning-node-status:s'     => { name => 'warning_node_status', default => '%{status} =~ /^takeover|partialGiveback/i' },
        'critical-node-status:s'    => { name => 'critical_node_status', default => '%{status} =~ /dead|cannotTakeover/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'unknown_cluster_status', 'warning_cluster_status', 'critical_cluster_status',
        'unknown_node_status', 'warning_node_status', 'critical_node_status'
    ]);
}

my $map_cannot_takeover = {
    1 => 'ok', 2 => 'unknownReason',
    3 => 'disabledByOperator', 4 => 'interconnectOffline',
    5 => 'disabledByPartner', 6 => 'takeoverFailed',
    7 => 'mailboxIsInDegradedState', 8 => 'partnermailboxIsInUninitialisedState',
    9 => 'mailboxVersionMismatch', 10 => 'nvramSizeMismatch',
    11 => 'kernelVersionMismatch', 12 => 'partnerIsInBootingStage',
    13 => 'diskshelfIsTooHot', 14 => 'partnerIsPerformingRevert',
    15 => 'nodeIsPerformingRevert', 16 => 'sametimePartnerIsAlsoTryingToTakeUsOver',
    17 => 'alreadyInTakenoverMode', 18 => 'nvramLogUnsynchronized',
    19 => 'stateofBackupMailboxIsDoubtful', 19 => 'stateofBackupMailboxIsDoubtful'
};
my $map_state = {
    1 => 'dead', 2 => 'canTakeover',
    3 => 'cannotTakeover', 4 => 'takeover',
    5 => 'partialGiveback'
};
my $map_partner_status = {
    1 => 'maybeDown', 2 => 'ok', 3 => 'dead'
};

my $mapping_cf = {
    cfState               => { oid => '.1.3.6.1.4.1.789.1.2.3.2', map => $map_state },
    cfCannotTakeoverCause => { oid => '.1.3.6.1.4.1.789.1.2.3.3', map => $map_cannot_takeover },
    cfPartnerStatus       => { oid => '.1.3.6.1.4.1.789.1.2.3.4', map => $map_partner_status },
};
my $mapping_ha = {
    haState               => { oid => '.1.3.6.1.4.1.789.1.21.2.1.4', map => $map_state },
    haCannotTakeoverCause => { oid => '.1.3.6.1.4.1.789.1.21.2.1.5', map => $map_cannot_takeover },
    haPartnerStatus       => { oid => '.1.3.6.1.4.1.789.1.21.2.1.6', map => $map_partner_status },
};
my $oid_cf = '.1.3.6.1.4.1.789.1.2.3';
my $oid_haEntry = '.1.3.6.1.4.1.789.1.21.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cf, start => $mapping_cf->{cfState}->{oid}, end => $mapping_cf->{cfPartnerStatus}->{oid} },
            { oid => $oid_haEntry, start => $mapping_ha->{haState}->{oid}, end => $mapping_ha->{haPartnerStatus}->{oid} },
        ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping_cf, results => $snmp_result->{$oid_cf}, instance => '0');
    $self->{global} = {
        cluster_status => $result->{cfState},
        reason_cannot_takeover => $result->{cfCannotTakeoverCause},
        partner_status => $result->{cfPartnerStatus}
    };

    $self->{nodes} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_haEntry}}) {
        next if ($oid !~ /^$mapping_ha->{haState}->{oid}\.(.*)$/);
        my $instance = $1;

        $result = $options{snmp}->map_instance(mapping => $mapping_ha, results => $snmp_result->{$oid_haEntry}, instance => $instance);
        my $name = $self->{output}->decode(join('', map(chr($_), split(/\./, $instance))));
        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            $name !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $name . "'.", debug => 1);
            next;
        }

        $self->{nodes}->{$instance} = {
            display => $name,
            status => $result->{haState},
            reason_cannot_takeover => $result->{haCannotTakeoverCause},
            partner_status => $result->{haPartnerStatus}
        };
    }
}

1;

__END__

=head1 MODE

Check failover status.

=over 8

=item B<--filter-node>

Filter name with regexp (based on serial)

=item B<--unknown-cluster-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{cluster_status}, %{reason_cannot_takeover}, %{partner_status}

=item B<--warning-cluster-status>

Set warning threshold for status (Default: '%{cluster_status} =~ /^takeover|partialGiveback/i').
Can used special variables like: %{cluster_status}, %{reason_cannot_takeover}, %{partner_status}

=item B<--critical-cluster-status>

Set critical threshold for status (Default: '%{cluster_status} =~ /dead|cannotTakeover/i').
Can used special variables like: %{cluster_status}, %{reason_cannot_takeover}, %{partner_status}

=item B<--unknown-node-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{status}, %{reason_cannot_takeover}, %{partner_status}, %{display}

=item B<--warning-node-status>

Set warning threshold for status (Default: '%{status} =~ /^takeover|partialGiveback/i').
Can used special variables like: %{status}, %{reason_cannot_takeover}, %{partner_status}, %{display}

=item B<--critical-node-status>

Set critical threshold for status (Default: '%{status} =~ /dead|cannotTakeover/i').
Can used special variables like: %{status}, %{reason_cannot_takeover}, %{partner_status}, %{display}

=back

=cut
