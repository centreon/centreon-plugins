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

package storage::hitachi::hcp::snmp::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{status}
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub volume_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking volume '%s' [node: %s]",
        $options{instance_value}->{label},
        $options{instance_value}->{node_id}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return sprintf(
        "volume '%s' [node: %s] ",
        $options{instance_value}->{label},
        $options{instance_value}->{node_id}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'volumes', type => 3, cb_prefix_output => 'prefix_volume_output', cb_long_output => 'volume_long_output',
          indent_long_output => '    ', message_multiple => 'All volumes are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'volume-status',
            type => 2,
            warning_default => '%{status} =~ /degraded/',
            critical_default => '%{status} =~ /broken/',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'node_id' }, { name => 'label' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'volume.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'volume.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
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
        'filter-node-id:s' => { name => 'filter_node_id' },
        'filter-label:s'   => { name => 'filter_label' }
    });

    return $self;
}

my $map_volume_status = {
    0 => 'unavailable', 1 => 'broken',
    2 => 'suspended', 3 => 'initialized',
    4 => 'available', 5 => 'degraded'
};
my $mapping = {
    space_free  => { oid => '.1.3.6.1.4.1.116.5.46.2.1.1.4' }, # storageAvailability
    space_total => { oid => '.1.3.6.1.4.1.116.5.46.2.1.1.5' }, # storageCapacity
    status      => { oid => '.1.3.6.1.4.1.116.5.46.2.1.1.7', map => $map_volume_status }  # storageStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_node_id = '.1.3.6.1.4.1.116.5.46.2.1.1.2'; # storageNodeNumber
    my $oid_label = '.1.3.6.1.4.1.116.5.46.2.1.1.6'; # storageChannelUnit
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_node_id },
            { oid => $oid_label }
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{volumes} = {};
    foreach (keys %$snmp_result) {
        next if (! /$oid_node_id\.(.*)$/);
        my $instance = $1;
        my $node_id = $snmp_result->{$_};
        my $label = $snmp_result->{ $oid_label . '.' . $instance };

        my $fullname = $node_id . ':' . $label;
        if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $node_id !~ /$self->{option_results}->{filter_node_id}/) {
            $self->{output}->output_add(long_msg => "skipping volume '$fullname'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_label}) && $self->{option_results}->{filter_label} ne '' &&
            $label !~ /$self->{option_results}->{filter_label}/) {
            $self->{output}->output_add(long_msg => "skipping volume '$fullname'.", debug => 1);
            next;
        }

        $self->{volumes}->{$instance} = {
            node_id => $node_id,
            label => $label,
            status => { node_id => $node_id, label => $label },
            space => { name => $fullname }
        };
    }

    return if (scalar(keys %{$self->{volumes}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %{$self->{volumes}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{volumes}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{volumes}->{$_}->{status}->{status} = $result->{status};

        next if (!defined($result->{space_total}));

        $self->{volumes}->{$_}->{space}->{total} = $result->{space_total};
        $self->{volumes}->{$_}->{space}->{free} = $result->{space_free};
        $self->{volumes}->{$_}->{space}->{used} = $result->{space_total} - $result->{space_free};
        $self->{volumes}->{$_}->{space}->{prct_free} = $result->{space_free} * 100 / $result->{space_total};
        $self->{volumes}->{$_}->{space}->{prct_used} = 100 - $self->{volumes}->{$_}->{space}->{prct_free};
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-node-id>

Filter volumes by node id (can be a regexp).

=item B<--unknown-volume-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{node_id}, %{label}

=item B<--warning-volume-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/').
Can used special variables like: %{status}, %{node_id}, %{label}

=item B<--critical-volume-status>

Set critical threshold for status (Default: '%{status} =~ /broken/').
Can used special variables like: %{status}, %{node_id}, %{label}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage-prct', 'space-usage', 'space-usage-free'.

=back

=cut
