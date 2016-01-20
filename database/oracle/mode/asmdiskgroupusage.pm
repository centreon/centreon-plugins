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

package database::oracle::mode::asmdiskgroupusage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $thresholds = {
    diskgroup => [
        ['dismounted', 'OK'],
        ['mounted', 'OK'],
        ['connected', 'OK'],
    ],
};
my $instance_mode;

my $maps_counters = {
    dg => { 
        '000_status'   => { threshold => 0, set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => \&custom_status_calc,
                closure_custom_output => \&custom_status_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&custom_status_threshold,
            },
        },
        '001_offline-disks'   => { threshold => 0, set => {
                key_values => [ { name => 'offline_disks' }, { name => 'type' }, { name => 'display' } ],
                closure_custom_calc => \&custom_offline_calc,
                closure_custom_output => \&custom_offline_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&custom_offline_threshold,
            },
        },
        '002_usage'   => { set => {
                key_values => [ { name => 'used' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => \&custom_usage_calc,
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            },
        },
    },
};

sub custom_offline_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_offline_disks}) && $instance_mode->{option_results}->{critical_offline_disks} ne '' &&
            eval "$instance_mode->{option_results}->{critical_offline_disks}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_offline_disks}) && $instance_mode->{option_results}->{warning_offline_disks} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_offline_disks}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter offline status issue: ' . $message);
    }

    return $status;
}

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

sub custom_status_threshold {
    my ($self, %options) = @_;
    
    my $message;
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        $instance_mode->{last_status} = 0;
        if (eval "$instance_mode->{check_status}") {
            $instance_mode->{last_status} = 1;
        }
    };
    return $instance_mode->get_severity(section => 'diskgroup', value => $self->{result_values}->{state});
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ' . $self->{result_values}->{state};
    
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if ($self->{result_values}->{total} > 0 && defined($instance_mode->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = ();
    if ($self->{result_values}->{total} > 0 && $instance_mode->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    # cannot use '%' or free option with unlimited system 
    return 'ok' if ($self->{result_values}->{total} <= 0 && ($instance_mode->{option_results}->{units} eq '%' || $instance_mode->{option_results}->{free}));
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

    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});    
    my $msg;
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf("Used: %s (unlimited)", $total_used_value . " " . $total_used_unit);
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
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

    return -10 if (defined($instance_mode->{last_status}) && $instance_mode->{last_status} == 0);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    
    return 0 if ($self->{result_values}->{total} == 0);
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning-offline-disks:s"     => { name => 'warning_offline_disks', default => '(%{offline_disks} > 0 && %{type} eq "extern") || (%{offline_disks} > 1 && %{type} eq "high")' },
                                  "critical-offline-disks:s"    => { name => 'critical_offline_disks', default => '%{offline_disks} > 0 && %{type} =~ /^normal|high$/' },
                                  "filter-name:s"           => { name => 'filter_name', },
                                  "units:s"                 => { name => 'units', default => '%' },
                                  "free"                    => { name => 'free' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                  "no-component:s"          => { name => 'no_component' },
                                });
 
    foreach my $key (('dg')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_offline_disks', 'critical_offline_disks')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
    
    $self->{check_status} = '%{state} =~ /^(mounted|dismounted|connected)$/i';
    $self->{check_status} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('dg')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $instance_mode = $self;
    
    $self->change_macros();
    
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{dg}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All diskgroups are ok');
    }
    
    foreach my $id (sort keys %{$self->{dg}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{dg}}) {
            my $obj = $maps_counters->{dg}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{dg}->{$id});
            next if ($value_check == -10); # status issue
            
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

        $self->{output}->output_add(long_msg => "Diskgroup '$self->{dg}->{$id}->{display}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Diskgroup '$self->{dg}->{$id}->{display}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Diskgroup '$self->{dg}->{$id}->{display}' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{sql}->connect();
    my $query = q{SELECT name, state, type, total_mb, usable_file_mb, offline_disks FROM V$ASM_DISKGROUP};
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();
    
    $self->{dg} = {};
    foreach my $row (@$result) {
        my ($name, $state, $type, $total_mb, $usable_file_mb, $offline_disks) = @$row;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }
        
        
        $self->{dg}->{$name} = { display => $name, total => $total_mb * 1024 * 1024,
                                 used => ($total_mb * 1024 * 1024) - ($usable_file_mb * 1024 * 1024),
                                 state => $state, type => lc($type), offline_disks => $offline_disks };                        
    }
    
    if (scalar(keys %{$self->{dg}}) <= 0) {
        $self->{output}->output_add(severity => defined($self->{no_components}) ? $self->{no_components} : 'unknown',
                                    short_msg => 'No components are checked.');
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

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='diskgroup,CRITICAL,^(?!(mounted|connected|dismounted)$)'

=back

=cut
