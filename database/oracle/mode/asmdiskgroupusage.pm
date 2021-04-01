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

package database::oracle::mode::asmdiskgroupusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_offline_output {
    my ($self, %options) = @_;
    my $msg = 'Offline disks : ' . $self->{result_values}->{offline_disks};
    
    return $msg;
}

sub custom_offline_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{offline_disks} = $options{new_datas}->{$self->{instance} . '_offline_disks'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status: ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_threshold {
    my ($self, %options) = @_;

    my $status = catalog_status_threshold($self, %options);
    $self->{instance_mode}->{last_status} = 0;
    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{instance_mode}->{last_status} = 1;
    }
    return $status;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if ($self->{result_values}->{total} > 0 && defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    
    $label .= '_' . $self->{result_values}->{label_ref}
        if (defined($self->{result_values}->{label_ref}));

    my %total_options = ();
    if ($self->{result_values}->{total} > 0 && $self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    # cannot use '%' or free option with unlimited system 
    return 'ok' if ($self->{result_values}->{total} <= 0 && ($self->{instance_mode}->{option_results}->{units} eq '%' || $self->{instance_mode}->{option_results}->{free}));
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $label = 'Disk ';
    if (defined($self->{result_values}->{label_ref})) {
        $label = 'Disk Failure';
    }

    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});    
    my $msg;
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf("%s Used: %s (unlimited)", $label, $total_used_value . " " . $total_used_unit);
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
        $msg = sprintf("%s Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $label,
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    }

    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    return -10 if (defined($self->{instance_mode}->{last_status}) && $self->{instance_mode}->{last_status} == 0);
    
    my $label_used = 'used';
    $label_used .= '_' . $options{extra_options}->{label_ref}
        if (defined($options{extra_options}->{label_ref}));

    $self->{result_values}->{label_ref} = defined($options{extra_options}->{label_ref}) ? $options{extra_options}->{label_ref} : undef;
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $label_used};
    
    return 0 if ($self->{result_values}->{total} == 0);
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'dg', type => 1, cb_prefix_output => 'prefix_dg_output', message_multiple => 'All diskgroups are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{dg} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_output'),
            }
        },
        { label => 'offline-disks', set => {
                key_values => [ { name => 'offline_disks' }, { name => 'type' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_offline_calc'),
                closure_custom_output =>  $self->can('custom_offline_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'usage-failure', set => {
                key_values => [ { name => 'used_failure' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'failure' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_dg_output {
    my ($self, %options) = @_;

    return "Diskgroup '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "unknown-status:s"          => { name => 'unknown_status', default => '' },
        "warning-status:s"          => { name => 'warning_status', default => '' },
        "critical-status:s"         => { name => 'critical_status', default => '' },
        "warning-offline-disks:s"   => { name => 'warning_offline_disks', default => '(%{offline_disks} > 0 && %{type} eq "extern") || (%{offline_disks} > 1 && %{type} eq "high")' },
        "critical-offline-disks:s"  => { name => 'critical_offline_disks', default => '%{offline_disks} > 0 && %{type} =~ /^normal|high$/' },
        "filter-name:s"             => { name => 'filter_name', },
        "units:s"                   => { name => 'units', default => '%' },
        "free"                      => { name => 'free' },
    });
 
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_offline_disks', 'critical_offline_disks',
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    my $query = q{SELECT name, state, type, total_mb, usable_file_mb, offline_disks, FREE_MB FROM V$ASM_DISKGROUP};
    $options{sql}->query(query => $query);
    my $result = $options{sql}->fetchall_arrayref();
    $options{sql}->disconnect();
    
    $self->{dg} = {};
    foreach my $row (@$result) {
        my ($name, $state, $type, $total_mb, $usable_file_mb, $offline_disks, $free_mb) = @$row;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }

        my $used_failure = ($total_mb * 1024 * 1024) - ($usable_file_mb * 1024 * 1024);
        if ($usable_file_mb < 0) {
            $used_failure = ($total_mb * 1024 * 1024);
        }
        $self->{dg}->{$name} = { 
            display => $name, 
            total => $total_mb * 1024 * 1024,
            used => ($total_mb * 1024 * 1024) - ($free_mb * 1024 * 1024),
            used_failure => $used_failure,
            status => $state, 
            type => lc($type), 
            offline_disks => $offline_disks
        };                        
    }
    
    if (scalar(keys %{$self->{dg}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No diskgroup found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Oracle ASM diskgroup usage and status.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--warning-usage-failure>

Threshold warning.

=item B<--critical-usage-failure>

Threshold critical.

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-offline-disks>

Set warning threshold for offline disks (Default: '(%{offline_disks} > 0 && %{type} eq "extern") || (%{offline_disks} > 1 && %{type} eq "high")').
Can used special variables like: %{offline_disks}, %{type}, %{display}

=item B<--critical-offline-disks>

Set critical threshold for offline disks (Default: '%{offline_disks} > 0 && %{type} =~ /^normal|high$/').
Can used special variables like: %{offline_disks}, %{type}, %{display}

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-name>

Filter by name (regexp can be used).

=back

=cut
