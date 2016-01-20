#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::netapp::snmp::mode::filesys;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    '000_usage' => { set => {
            key_values => [ { name => 'name' }, { name => 'used' }, { name => 'total' }, 
                            { name => 'dfCompressSavedPercent' }, { name => 'dfDedupeSavedPercent' } ],
            closure_custom_calc => \&custom_usage_calc,
            closure_custom_output => \&custom_usage_output,
            closure_custom_perfdata => \&custom_usage_perfdata,
            closure_custom_threshold_check => \&custom_usage_threshold,
        }
    },
    '001_inodes' => { set => {
            key_values => [ { name => 'dfPerCentInodeCapacity' }, { name => 'name' } ],
            output_template => 'Inodes Used : %s %%', output_error_template => "Inodes : %s",
            perfdatas => [
                { label => 'inodes', value => 'dfPerCentInodeCapacity_absolute', template => '%d',
                  unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name_absolute' },
            ],
        }
    },
};

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    return if ($self->{result_values}->{total} <= 0);
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($instance_mode->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{name} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = ();
    if ($instance_mode->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
    if (defined($self->{result_values}->{dfCompressSavedPercent}) && $self->{result_values}->{dfCompressSavedPercent} ne '' &&
        $self->{result_values}->{dfCompressSavedPercent} >= 0) {
        $self->{output}->perfdata_add(label => 'compresssaved' . $extra_label, unit => '%',
                                      value => $self->{result_values}->{dfCompressSavedPercent},
                                      min => 0, max => 100);
    }
    if (defined($self->{result_values}->{dfDedupeSavedPercent}) && $self->{result_values}->{dfDedupeSavedPercent} ne '' &&
        $self->{result_values}->{dfDedupeSavedPercent} >= 0) {
        $self->{output}->perfdata_add(label => 'dedupsaved' . $extra_label, unit => '%',
                                      value => $self->{result_values}->{dfDedupeSavedPercent},
                                      min => 0, max => 100);
    }
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    return 'ok' if ($self->{result_values}->{total} <= 0);
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    if ($self->{result_values}->{total} == 0) {
        $msg = 'skipping: total size is 0';
    } elsif ($self->{result_values}->{total} < 0) {
        $msg = 'skipping: negative total value (maybe use snmp v2c)';
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
        $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{dfCompressSavedPercent} = $options{new_datas}->{$self->{instance} . '_dfCompressSavedPercent'};
    $self->{result_values}->{dfDedupeSavedPercent} = $options{new_datas}->{$self->{instance} . '_dfDedupeSavedPercent'};

    return 0 if ($options{new_datas}->{$self->{instance} . '_total'} == 0);
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};

    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    # snapshot can be over 100%
    if ($self->{result_values}->{free} < 0) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_free} = 0;
    }
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "units:s"               => { name => 'units', default => '%' },
                                  "free"                  => { name => 'free' },
                                  "filter-name:s"         => { name => 'filter_name' },
                                  "filter-type:s"         => { name => 'filter_type' },
                                });                         
     
    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        $maps_counters->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    
    $instance_mode = $self;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{filesys_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All filesys usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{filesys_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{filesys_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
            push @exits, $exit2;

            my $output = $maps_counters->{$_}->{obj}->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Filesys '" . $self->{filesys_selected}->{$id}->{name} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Filesys '" . $self->{filesys_selected}->{$id}->{name} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Filesys '" . $self->{filesys_selected}->{$id}->{name} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

my %map_types = (
    1 => 'traditionalVolume',
    2 => 'flexibleVolume',
    3 => 'aggregate',
    4 => 'stripedAggregate',
    5 => 'stripedVolume'
);
my $mapping = {
    dfType      => { oid => '.1.3.6.1.4.1.789.1.5.4.1.23', map => \%map_types },
};
my $mapping2 = {
    dfFileSys               => { oid => '.1.3.6.1.4.1.789.1.5.4.1.2' },
    dfKBytesTotal           => { oid => '.1.3.6.1.4.1.789.1.5.4.1.3' },
    dfKBytesUsed            => { oid => '.1.3.6.1.4.1.789.1.5.4.1.4' },
    dfPerCentInodeCapacity  => { oid => '.1.3.6.1.4.1.789.1.5.4.1.9' },
    df64TotalKBytes         => { oid => '.1.3.6.1.4.1.789.1.5.4.1.29' },
    df64UsedKBytes          => { oid => '.1.3.6.1.4.1.789.1.5.4.1.30' },
    dfCompressSavedPercent  => { oid => '.1.3.6.1.4.1.789.1.5.4.1.38' },
    dfDedupeSavedPercent    => { oid => '.1.3.6.1.4.1.789.1.5.4.1.40' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oids = [
        { oid => $mapping->{dfType}->{oid} },
        { oid => $mapping2->{dfFileSys}->{oid} },
        { oid => $mapping2->{dfKBytesTotal}->{oid} },
        { oid => $mapping2->{dfKBytesUsed}->{oid} },
        { oid => $mapping2->{dfPerCentInodeCapacity}->{oid} },
        { oid => $mapping2->{dfCompressSavedPercent}->{oid} },
        { oid => $mapping2->{dfDedupeSavedPercent}->{oid} },
    ];
    if (!$self->{snmp}->is_snmpv1()) {
        push @{$oids}, { oid => $mapping2->{df64TotalKBytes}->{oid} }, { oid => $mapping2->{df64UsedKBytes}->{oid} };
    }
    
    my $results = $self->{snmp}->get_multiple_table(oids => $oids, return_type => 1, nothing_quit => 1);
    $self->{filesys_selected} = {};
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping2->{dfFileSys}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $results, instance => $instance);
        
        my $name = $result2->{dfFileSys};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': no matching filter name.");
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{dfType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{dfType} . "': no matching filter type.");
            next;
        }
    
        $self->{filesys_selected}->{$instance} = { name => $name };
        $self->{filesys_selected}->{$instance}->{total} = $result2->{dfKBytesTotal} * 1024;
        $self->{filesys_selected}->{$instance}->{used} = $result2->{dfKBytesUsed} * 1024;
        if (defined($result2->{df64TotalKBytes}) && $result2->{df64TotalKBytes} > 0) {
            $self->{filesys_selected}->{$instance}->{total} = $result2->{df64TotalKBytes} * 1024;
            $self->{filesys_selected}->{$instance}->{used} = $result2->{df64UsedKBytes} * 1024;
        }
        $self->{filesys_selected}->{$instance}->{dfCompressSavedPercent} = $result2->{dfCompressSavedPercent};
        $self->{filesys_selected}->{$instance}->{dfDedupeSavedPercent} = $result2->{dfDedupeSavedPercent};
        if ($self->{filesys_selected}->{$instance}->{total} > 0) {
            $self->{filesys_selected}->{$instance}->{dfPerCentInodeCapacity} = $result2->{dfPerCentInodeCapacity};
        }
    }
    
    if (scalar(keys %{$self->{filesys_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check filesystem usage (volumes, snapshots and aggregates also).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: usage, inodes (%).

=item B<--critical-*>

Threshold critical.
Can be: usage, inodes (%).

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-name>

Filter by filesystem name (can be a regexp).

=item B<--filter-type>

Filter filesystem type (can be a regexp. Example: 'flexibleVolume|aggregate').

=back

=cut
