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

package centreon::common::cisco::standard::snmp::mode::memoryflash;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    '000_usage' => { set => {
                        key_values => [ { name => 'display' }, { name => 'free' }, { name => 'total' } ],
                        closure_custom_calc => \&custom_usage_calc,
                        closure_custom_output => \&custom_usage_output,
                        closure_custom_perfdata => \&custom_usage_perfdata,
                        closure_custom_threshold_check => \&custom_usage_threshold,
                    }
               },
};

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    $self->{output}->perfdata_add(label => 'used' . $extra_label, unit => 'B',
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
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
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"     => { name => 'filter_name' },
                                });                         
     
    foreach (sort keys %{$maps_counters}) {
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
    
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{memory_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All memory flash partitions are ok');
    }
    
    foreach my $id (sort keys %{$self->{memory_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            my $obj = $maps_counters->{$_}->{obj};
            
            $obj->set(instance => $id);
            my ($value_check) = $obj->execute(values => $self->{memory_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Partition '" . $self->{memory_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Partition '" . $self->{memory_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Partition '" . $self->{memory_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    ciscoFlashPartitionSize                 => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.4' },
    ciscoFlashPartitionFreeSpace            => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.5' },
    ciscoFlashPartitionName                 => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.10' },
    ciscoFlashPartitionSizeExtended         => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.13' },
    ciscoFlashPartitionFreeSpaceExtended    => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.14' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{memory_selected} = {};
    my $ciscoFlashPartitionEntry = '.1.3.6.1.4.1.9.9.10.1.1.4.1.1';
    $self->{results} = $self->{snmp}->get_table(oid => $ciscoFlashPartitionEntry,
                                                nothing_quit => 1);
    
    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{ciscoFlashPartitionSize}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ciscoFlashPartitionName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{ciscoFlashPartitionName} . "': no matching filter.", debug => 1);
            next;
        }

        my $total = $result->{ciscoFlashPartitionSize};
        if (defined($result->{ciscoFlashPartitionSizeExtended})) {
            $total = $result->{ciscoFlashPartitionSizeExtended};
        }
        my $free = $result->{ciscoFlashPartitionFreeSpace};
        if (defined($result->{ciscoFlashPartitionFreeSpaceExtended})) {
            $free = $result->{ciscoFlashPartitionFreeSpaceExtended};
        }
        
        $self->{memory_selected}->{$instance} = { display => $result->{ciscoFlashPartitionName}, 
                                                  free => $free, total => $total };
    }
    
    if (scalar(keys %{$self->{memory_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory flash usages.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=item B<--filter-name>

Filter partition name (can be a regexp).

=back

=cut
