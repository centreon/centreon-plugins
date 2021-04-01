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

package storage::qnap::snmp::mode::volumeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'volume.space.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
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
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_used'} + $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};    
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'volume', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' },
    ];

    $self->{maps_counters}->{volume} = [
        { label => 'usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'free' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s"     => { name => 'filter_name' },
        "units:s"           => { name => 'units', default => '%' },
        "free"              => { name => 'free' },
    });

    return $self;
}

my $mapping = {
    SysVolumeDescr      => { oid => '.1.3.6.1.4.1.24681.1.2.17.1.2' },
    SysVolumeFS         => { oid => '.1.3.6.1.4.1.24681.1.2.17.1.3' },
    SysVolumeTotalSize  => { oid => '.1.3.6.1.4.1.24681.1.2.17.1.4' },
    SysVolumeFreeSize   => { oid => '.1.3.6.1.4.1.24681.1.2.17.1.5' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{volume} = {};
    my $oid_SysVolumeEntry = '.1.3.6.1.4.1.24681.1.2.17.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_SysVolumeEntry, 
        start => $mapping->{SysVolumeDescr}->{oid}, 
        end => $mapping->{SysVolumeFreeSize}->{oid}, 
        nothing_quit => 1
    );
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{SysVolumeDescr}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{SysVolumeDescr} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{SysVolumeDescr} . "': no matching filter.");
            next;
        }
        
        my $free = $self->convert_bytes(value => $result->{SysVolumeFreeSize});
        my $total = $self->convert_bytes(value => $result->{SysVolumeTotalSize});
        if ($total == 0) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{SysVolumeDescr} . "': total size is 0.");
            next;
        }
        
        $self->{volume}->{$instance} = { 
            display => $result->{SysVolumeDescr}, 
            free => $free, used => $total - $free
        };
    }
    
    if (scalar(keys %{$self->{volume}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

sub convert_bytes {
    my ($self, %options) = @_;
    my $multiple = defined($options{network}) ? 1000 : 1024;
    my %units = (K => 1, M => 2, G => 3, T => 4);
    
    if ($options{value} !~ /^\s*([0-9\.\,]+)\s*(.)/) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    output => "Cannot convert value '" . $options{value} . "'");
        $self->{output}->display();
        $self->{output}->exit();
    }
    my ($bytes, $unit) = ($1, uc($2));
    
    for (my $i = 0; $i < $units{$unit}; $i++) {
        $bytes *= $multiple;
    }

    return $bytes;
}

1;

__END__

=head1 MODE

Check volume usages.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-name>

Filter volume name (can be a regexp).

=back

=cut
