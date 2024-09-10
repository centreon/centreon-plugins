#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package storage::emc::DataDomain::snmp::mode::mtrees;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub mtree_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking MTree '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_mtree_output {
    my ($self, %options) = @_;

    return sprintf(
        "MTree '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_daily_output {
    my ($self, %options) = @_;

    return 'daily data written ';
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of MTrees ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'mtrees', type => 3, cb_prefix_output => 'prefix_mtree_output', cb_long_output => 'mtree_long_output', indent_long_output => '    ', message_multiple => 'All MTrees are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'precomp', type => 0, skipped_code => { -10 => 1 } },
                { name => 'daily', type => 0, cb_prefix_output => 'prefix_daily_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'mtrees-detected', display_ok => 0, nlabel => 'mtrees.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
         {
             label => 'status',
             type => 2,
             set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{precomp} = [
        { label => 'space-precompression-usage', nlabel => 'mtree.precompression.space.usage.bytes', set => {
                key_values => [ { name => 'preComp' }, { name => 'name' } ],
                output_template => 'space precompression used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{daily} = [
        { label => 'daily-precompression-data-written', nlabel => 'mtree.daily.precompression.data.written.bytes', set => {
                key_values => [ { name => 'preComp' }, { name => 'name' } ],
                output_template => 'precompression: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'daily-postcompression-data-written', nlabel => 'mtree.daily.postcompression.data.written.bytes', set => {
                key_values => [ { name => 'postComp' }, { name => 'name' } ],
                output_template => 'postcompression: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'name' }
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
        'filter-mtree-name:s' => { name => 'filter_mtree_name' }
    });

    return $self;
}

sub load_daily_written {
    my ($self, %options) = @_;

    my $oid_mtreeCompressionEntry = '.1.3.6.1.4.1.19746.1.15.1.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_mtreeCompressionEntry
    );
    my $mapping = {
        name       => { oid => '.1.3.6.1.4.1.19746.1.15.1.1.1.2' }, # mtreeCompressionMtreePath
        preComp    => { oid => '.1.3.6.1.4.1.19746.1.15.1.1.1.3' }, # mtreeCompressionPreCompGib
        postComp   => { oid => '.1.3.6.1.4.1.19746.1.15.1.1.1.4' }, # mtreeCompressionPostCompGib
        timePeriod => { oid => '.1.3.6.1.4.1.19746.1.15.1.1.1.8' } # mtreeCompressionTimePeriod
    };

    my $daily_written = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if ($result->{timePeriod} !~ /Last 24 hours/i);

        $daily_written->{ $result->{name} } = {
            preComp => int($result->{preComp} * 1024 * 1024 * 1024),
            postComp => int($result->{postComp} * 1024 * 1024 * 1024)
        };
    }

    return $daily_written;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_mtreeListEntry = '.1.3.6.1.4.1.19746.1.15.2.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_mtreeListEntry,
        nothing_quit => 1
    );

    my $daily_written = $self->load_daily_written(snmp => $options{snmp});

    my %map_status = (
        1 => 'deleted',
        2 => 'readOnly',
        3 => 'readWrite',
        4 => 'replicationDestination',
        5 => 'retentionLockEnabled',
        6 => 'retentionLockDisabled'
    );

    my $mapping = {
        name    => { oid => '.1.3.6.1.4.1.19746.1.15.2.1.1.2' }, # mtreeListMtreeName
        preComp => { oid => '.1.3.6.1.4.1.19746.1.15.2.1.1.3' }, # mtreeListPreCompGib
        status  => { oid => '.1.3.6.1.4.1.19746.1.15.2.1.1.4', map => \%map_status } # mtreeListStatus
    };

    $self->{global} = { detected => 0 };
    $self->{mtrees} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        next if (defined($self->{option_results}->{filter_mtree_name}) && $self->{option_results}->{filter_mtree_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_mtree_name}/);

        $self->{global}->{detected}++;

        $self->{mtrees}->{$instance} = {
            name => $result->{name},
            status => {
                name => $result->{name},
                status => $result->{status}
            },
            precomp => {
                name => $result->{name},
                preComp => $result->{preComp} * 1024 * 1024 * 1024
            },
            daily => {
                name => $result->{name},
                %{$daily_written->{ $result->{name} }}
            }
        };
    }
}

1;

__END__

=head1 MODE

Check MTrees.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-mtree-name>

Check MTress by name.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{status}, %{source}, %{destination}, %{type}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'mtrees-detected', 'space-precompression-usage'.

=back

=cut
