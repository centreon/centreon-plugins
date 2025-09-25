#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::forcepoint::sdwan::snmp::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{total_space}
    );
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{used_space}
    );
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{free_space}
    );
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disks', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok' }
    ];

    $self->{maps_counters}->{disks} = [
        {
            label  => 'space-usage',
            nlabel => 'disk.space.usage.bytes',
            set    => {
                key_values            =>
                    [
                        { name => 'used_space' },
                        { name => 'free_space' },
                        { name => 'prct_used_space' },
                        { name => 'prct_free_space' },
                        { name => 'total_space' }
                    ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas             =>
                    [
                        {
                            template             => '%d',
                            min                  => 0,
                            max                  => 'total_space',
                            unit                 => 'B',
                            cast_int             => 1,
                            label_extra_instance => 1
                        }
                    ]
            }
        },
        {
            label      => 'space-usage-free',
            nlabel     => 'disk.space.free.bytes',
            display_ok => 0,
            set        => {
                key_values            =>
                    [
                        { name => 'free_space' },
                        { name => 'used_space' },
                        { name => 'prct_used_space' },
                        { name => 'prct_free_space' },
                        { name => 'total_space' }
                    ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas             =>
                    [
                        {
                            template             => '%d',
                            min                  => 0,
                            max                  => 'total_space',
                            unit                 => 'B',
                            cast_int             => 1,
                            label_extra_instance => 1
                        }
                    ]
            }
        },
        {
            label      => 'space-usage-prct',
            nlabel     => 'disk.space.usage.percentage',
            display_ok => 0,
            set        => {
                key_values            =>
                    [
                        { name => 'prct_used_space' },
                        { name => 'used_space' },
                        { name => 'free_space' },
                        { name => 'prct_free_space' },
                        { name => 'total_space' }
                    ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas             =>
                    [
                        { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                    ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 'filter-name:s' => { name => 'filter_name' } });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        name  => { oid => '.1.3.6.1.4.1.47565.1.1.1.11.3.1.2' },# fwPartitionDevName
        total => { oid => '.1.3.6.1.4.1.47565.1.1.1.11.3.1.4' },# fwPartitionSize
        free  => { oid => '.1.3.6.1.4.1.47565.1.1.1.11.3.1.6' },# fwPartitionAvail
        used  => { oid => '.1.3.6.1.4.1.47565.1.1.1.11.3.1.5' }# fwPartitionUsed
    };
    my $oid_fwDiskStatsEntry = '.1.3.6.1.4.1.47565.1.1.1.11.3.1';

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $oid_fwDiskStatsEntry, start => $mapping->{name}->{oid}, end => $mapping->{free}->{oid} },
            { oid => $mapping->{name}->{oid} }
        ],
        return_type  => 1,
        nothing_quit => 1
    );

    $self->{disks} = {};
    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        # Filter disks by partition dev name
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{disks}->{ $result->{name} } = {
            free_space      => $result->{free},
            total_space     => $result->{total},
            used_space      => $result->{used},
            prct_used_space => $result->{used} * 100 / $result->{total},
            prct_free_space => $result->{free} * 100 / $result->{total},
        };
    }

    if (scalar(keys %{$self->{disks}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No disk found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check disks.

=over 8

=item B<--filter-name>

Filter disks by partition dev name (can be a regexp).

=item B<--warning-space-usage>

Threshold in bytes.

=item B<--critical-space-usage>

Threshold in bytes.

=item B<--warning-space-usage-free>

Threshold in bytes.

=item B<--critical-space-usage-free>

Threshold in bytes.

=item B<--warning-space-usage-prct>

Threshold in percentage.

=item B<--critical-space-usage-prct>

Threshold in percentage.

=back

=cut
