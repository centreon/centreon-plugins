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

package os::as400::connector::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Disks ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 }  },
        { name => 'disks', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'disks-total', nlabel => 'disks.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'disks-active', nlabel => 'disks.active.count', set => {
                key_values => [ { name => 'active' }, { name => 'total' } ],
                output_template => 'active: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'disks-errors', nlabel => 'disks.errors.count', set => {
                key_values => [ { name => 'errors' }, { name => 'total' } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'disks-gap-repartition', nlabel => 'disks.gap.repartition.percentage', set => {
                key_values => [ { name => 'gap' } ],
                output_template => 'gap repartition between min/max: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
    ];

    $self->{maps_counters}->{disks} = [
         {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /noReady|busy|hwFailureOk|hwFailurePerf|Protected|rebuilding/i',
            critical_default => '%{status} =~ /^(noAccess|otherDiskSubFailed|failed|notOperational|noUnitControl)$/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'space-usage', nlabel => 'disk.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'disk.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'disk.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'reserved', nlabel => 'disk.space.reserved.bytes', set => {
                key_values => [ { name => 'reserved_space' }, { name => 'total_space' } ],
                output_template => 'reserved: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, max => 'total_space', label_extra_instance => 1 }
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
        'disk-name:s'        => { name => 'disk_name' },
        'filter-disk-name:s' => { name => 'filter_disk_name' }
    });
    
    return $self;
}

my $map_disk_status = {
    0 => 'noUnitControl', 1 => 'active', 2 => 'failed',
    3 => 'otherDiskSubFailed', 4 => 'hwFailurePerf', 5 => 'hwFailureOk',
    6 => 'rebuilding', 7 => 'noReady', 8 => 'writeProtected', 9 => 'busy',
    10 => 'notOperational', 11 => 'unknownStatus', 12 => 'noAccess',
    13 => 'rwProtected'
};

sub manage_selection {
    my ($self, %options) = @_;

    my %cmd = (command => 'listDisks');
    if (defined($self->{option_results}->{disk_name}) && $self->{option_results}->{disk_name} ne '') {
        $cmd{args} = { diskName => $self->{option_results}->{disk_name} };
    }
    my $disks = $options{custom}->request_api(%cmd);

    $self->{global} = { total => 0, active => 0, errors => 0 };
    $self->{disks} = {};
    my ($max, $min) = (0, 100);
    foreach my $disk (@{$disks->{result}}) {
        if (defined($self->{option_results}->{filter_disk_name}) && $self->{option_results}->{filter_disk_name} ne '' &&
            $disk->{name} !~ /$self->{option_results}->{filter_disk_name}/) {
            $self->{output}->output_add(long_msg => "skipping disk '" . $disk->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{disks}->{ $disk->{name} } = {
            name => $disk->{name},
            status => $map_disk_status->{ $disk->{status} },
            used_space => $disk->{totalSpace} - $disk->{freeSpace} - $disk->{reservedSpace},
            total_space => $disk->{totalSpace},
            reserved_space => $disk->{reservedSpace}
        };
        $self->{disks}->{ $disk->{name} }->{free_space} = $disk->{totalSpace} - $self->{disks}->{ $disk->{name} }->{used_space};
        $self->{disks}->{ $disk->{name} }->{prct_used_space} = $self->{disks}->{ $disk->{name} }->{used_space} * 100 / $disk->{totalSpace};
        $self->{disks}->{ $disk->{name} }->{prct_free_space} = 100 - $self->{disks}->{ $disk->{name} }->{prct_used_space};
        $max = $self->{disks}->{ $disk->{name} }->{prct_used_space} if ($self->{disks}->{ $disk->{name} }->{prct_used_space} > $max);
        $min = $self->{disks}->{ $disk->{name} }->{prct_used_space} if ($self->{disks}->{ $disk->{name} }->{prct_used_space} < $min);

        if ($self->{disks}->{ $disk->{name} }->{status} eq 'active') {
            $self->{global}->{active}++;
        } else {
            $self->{global}->{errors}++;
        }
        $self->{global}->{total}++;
    }

    if ($self->{global}->{total} > 1) {
        $self->{global}->{gap} = $max - $min;
    };
}

1;

__END__

=head1 MODE

Check disks.

=over 8

=item B<--disk-name>

Check exact disk.

=item B<--filter-disk-name>

Filter disks by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /unknown/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /noReady|busy|hwFailureOk|hwFailurePerf|Protected|rebuilding/i').
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /^(noAccess|otherDiskSubFailed|failed|notOperational|noUnitControl)$/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct', 'reserved', 
'disks-total', 'disks-active', 'disks-errors', 'disks-gap-repartition'.

=back

=cut
