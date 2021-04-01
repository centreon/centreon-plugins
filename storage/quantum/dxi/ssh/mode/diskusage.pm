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

package storage::quantum::dxi::ssh::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'used',
        unit => 'B',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{label}, exit_litteral => 'warning' }
        ]
    );

    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});

    return sprintf(
        "Capacity: %s Used: %s (%.2f%%) Available: %s (%.2f%%)", 
        $total_value . " " . $total_unit, 
        $used_value . " " . $used_unit, $self->{result_values}->{prct_used}, 
        $free_value . " " . $free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $self->{instance_mode}->convert_to_bytes(raw_value => $options{new_datas}->{$self->{instance} . '_disk_capacity'});
    $self->{result_values}->{used} = $self->{instance_mode}->convert_to_bytes(raw_value => $options{new_datas}->{$self->{instance} . '_used_disk_space'});

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_free} = '0';
    }

    return 0;
}

sub custom_volume_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label}, unit => 'B',
        value => $self->{result_values}->{volume},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label})
    );
}

sub custom_volume_threshold {
    my ($self, %options) = @_;
    
    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{volume},
        threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]
    );
}

sub custom_volume_output {
    my ($self, %options) = @_;

    my ($volume_value, $volume_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{volume});
    return sprintf('%s: %s %s (%.2f%%)', $self->{result_values}->{display}, $volume_value, $volume_unit, $self->{result_values}->{prct_volume});
}

sub custom_volume_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{volume} = $self->{instance_mode}->convert_to_bytes(raw_value => $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    $self->{result_values}->{total} = $self->{instance_mode}->convert_to_bytes(raw_value => $options{new_datas}->{$self->{instance} . '_disk_capacity'});
    $self->{result_values}->{display} = $options{extra_options}->{display_ref};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{volume};
        $self->{result_values}->{prct_volume} = $self->{result_values}->{volume} * 100 / $self->{result_values}->{total};
    } else {
        $self->{result_values}->{free} = '0';
        $self->{result_values}->{prct_volume} = '0';
    }

    return 0;
}

sub convert_to_bytes {
    my ($class, %options) = @_;
    
    my ($value, $unit) = split(/\s+/, $options{raw_value});
    if ($unit =~ /kb*/i) {
        $value = $value * 1024;
    } elsif ($unit =~ /mb*/i) {
        $value = $value * 1024 * 1024;
    } elsif ($unit =~ /gb*/i) {
        $value = $value * 1024 * 1024 * 1024;
    } elsif ($unit =~ /tb*/i) {
        $value = $value * 1024 * 1024 * 1024 * 1024;
    }

    return $value;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used_disk_space' }, { name => 'disk_capacity' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'free-space', set => {
                key_values => [ { name => 'free_space' }, { name => 'disk_capacity' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'free_space', display_ref => 'Free Space' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'reclaimable-space', set => {
                key_values => [ { name => 'reclaimable_space' }, { name => 'disk_capacity' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'reclaimable_space', display_ref => 'Reclaimable Space' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'deduplicated-data', set => {
                key_values => [ { name => 'deduplicated_data' }, { name => 'disk_capacity' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'deduplicated_data', display_ref => 'Deduplicated Data' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'system-metadata', set => {
                key_values => [ { name => 'system_metadata' }, { name => 'disk_capacity' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'system_metadata', display_ref => 'System Metadata' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'data-not-intended-for-deduplication', set => {
                key_values => [ { name => 'data_not_intended_for_deduplication' }, { name => 'disk_capacity' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'data_not_intended_for_deduplication', display_ref => 'Data Not Intended for Deduplication' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'units:s' => { name => 'units', default => '%' },
        'free'    => { name => 'free' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = $options{custom}->execute_command(command => 'syscli --get diskusage');
    # 2.2	Output data:
    #	    Disk Capacity = 16.00 TB
    #	    Available Disk Space = 15.66 TB
    #	    - Free Space = 15.64 TB  (97.78% of capacity)
    #	    - Reclaimable Space = 15.55 GB  (0.10% of capacity)
    #	    Used Disk Space = 355.23 GB
    #	    - Deduplicated Data = 238.12 GB  (1.49% of capacity)
    #	    - System Metadata = 69.30 GB  (0.43% of capacity)
    #	    - Data Not Intended for Deduplication = 32.26 GB  (0.20% of capacity)
    # 2.1	Output data:
    #	    Disk Capacity = 10.00 TB
    #	    Available Disk Space = 9.35 TB
    #	    Used Disk Space = 649.78 GB
    #	    Deduplicated Data = 501.95 GB  5.02%
    #	    System Metadata = 147.83 GB  1.48%
    #	    Data Not Intended for Deduplication = 0.00 MB  0.00%

    $self->{global} = {};
    foreach (split(/\n/, $stdout)) {
        $self->{global}->{disk_capacity} = $1 if (/.*Disk\sCapacity\s=\s(.*)$/i);
        $self->{global}->{available_disk_space} = $1 if (/.*Available\sDisk\sSpace\s=\s(.*)$/i);
        $self->{global}->{free_space} = $1 if (/.*Free\sSpace\s=\s(.*)\s+.*%.*$/i);
        $self->{global}->{reclaimable_space} = $1 if (/.*Reclaimable\sSpace\s=\s(.*)\s+.*%.*$/i);
        $self->{global}->{used_disk_space} = $1 if (/.*Used\sDisk\sSpace\s=\s(.*)$/i);
        $self->{global}->{deduplicated_data} = $1 if (/.*Deduplicated\sData\s=\s(.*)\s+.*%.*$/i);
        $self->{global}->{system_metadata} = $1 if (/.*System\sMetadata\s=\s(.*)\s+.*%.*$/i);
        $self->{global}->{data_not_intended_for_deduplication} = $1 if (/.*Data\sNot\sIntended\sfor\sDeduplication\s=\s(.*)\s+.*%.*$/i);
    }
}

1;

__END__

=head1 MODE

Check disk usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='usage'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'free-space','reclaimable-space', 'deduplicated-data',
'system-metadata', 'data-not-intended-for-deduplication'.

=back

=cut
