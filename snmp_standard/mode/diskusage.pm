#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($instance_mode->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
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
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

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

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size'};
    my $reserved_value = 0;
    if (defined($instance_mode->{option_results}->{space_reservation})) {
        $reserved_value = $instance_mode->{option_results}->{space_reservation} * $self->{result_values}->{total} / 100;
    }
    
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used} - $reserved_value;
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / ($self->{result_values}->{total} - $reserved_value);
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    # limit to 100. Better output.
    if ($self->{result_values}->{prct_used} > 100) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_used} = 100;
        $self->{result_values}->{prct_free} = 0;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global' },
        { name => 'diskpath', type => 1, cb_prefix_output => 'prefix_diskpath_output', message_multiple => 'All partitions are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Partitions count : %d',
                perfdatas => [
                    { label => 'count', value => 'count_absolute', template => '%d', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{diskpath} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'size' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{diskpath}}) > 1 ? return(0) : return(1);
}

sub prefix_diskpath_output {
    my ($self, %options) = @_;
    
    return "Partition '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "units:s"                 => { name => 'units', default => '%' },
                                  "free"                    => { name => 'free' },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                  "name"                    => { name => 'use_name' },
                                  "diskpath:s"              => { name => 'diskpath' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                  "show-cache"              => { name => 'show_cache' },
                                  "space-reservation:s"     => { name => 'space_reservation' },
                                  "filter-counters:s"       => { name => 'filter_counters', default => 'usage' },
                                });

    $self->{diskpath_id_selected} = [];
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{space_reservation}) && 
        ($self->{option_results}->{space_reservation} < 0 || $self->{option_results}->{space_reservation} > 100)) {
        $self->{output}->add_option_msg(short_msg => "Space reservation argument must be between 0 and 100 percent.");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_cache}->check_options(%options);
    $instance_mode = $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->get_selection();
    
    my $oid_dskTotalLow = '.1.3.6.1.4.1.2021.9.1.11'; # in kB
    my $oid_dskTotalHigh = '.1.3.6.1.4.1.2021.9.1.12'; # in kB
    my $oid_dskUsedLow = '.1.3.6.1.4.1.2021.9.1.15'; # in kB
    my $oid_dskUsedHigh = '.1.3.6.1.4.1.2021.9.1.16'; # in kB

    $self->{snmp}->load(oids => [$oid_dskTotalLow, $oid_dskTotalHigh, $oid_dskUsedLow, $oid_dskUsedHigh], 
                        instances => $self->{diskpath_id_selected}, nothing_quit => 1);
    my $result = $self->{snmp}->get_leef();
    
    $self->{global}->{count} = 0;
    $self->{diskpath} = {};
    foreach (sort @{$self->{diskpath_id_selected}}) {
        my $name_diskpath = $self->get_display_value(id => $_);

        if (!defined($result->{$oid_dskTotalHigh . "." . $_})) {
            $self->{output}->add_option_msg(long_msg => sprintf("Skipping partition '%s': not found (need to reload the cache)", 
                                                                $name_diskpath));
            next;
        }
        
        my $total_size = (($result->{$oid_dskTotalHigh . "." . $_} << 32) + $result->{$oid_dskTotalLow . "." . $_}) * 1024;
        if ($total_size == 0) {
            $self->{output}->output_add(long_msg => sprintf("Skipping partition '%s' (total size is 0)", $name_diskpath));
            next;
        }
        my $total_used = (($result->{$oid_dskUsedHigh . "." . $_} << 32) + $result->{$oid_dskUsedLow . "." . $_}) * 1024;

        $self->{diskpath}->{$_} = {
            display => $name_diskpath,
            size => $total_size,
            used => $total_used,
        };
        $self->{global}->{count}++;
    }
    
    if (scalar(keys %{$self->{diskpath}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Issue with disk path information (see details)");
        $self->{output}->option_exit();
    }
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];
    
    my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';
    
    my $result = $self->{snmp}->get_table(oid => $oid_dskPath);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result})) {
        next if ($key !~ /\.([0-9]+)$/);        
        my $diskpath_index = $1;
        push @{$datas->{all_ids}}, $diskpath_index;
        $datas->{"dskPath_" . $diskpath_index} = $self->{output}->to_utf8($result->{$key});
    }

    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub get_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $self->{snmp}->get_hostname()  . '_' . $self->{snmp}->get_port() . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
            $self->reload_cache();
            $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{diskpath})) {
        # get by ID
        my $name = $self->{statefile_cache}->get(name => "dskPath_" . $self->{option_results}->{diskpath});
        push @{$self->{diskpath_id_selected}}, $self->{option_results}->{diskpath} if (defined($name));
    } else {
        foreach my $i (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => "dskPath_" . $i);
            next if (!defined($filter_name));
            
            if (!defined($self->{option_results}->{diskpath})) {
                push @{$self->{diskpath_id_selected}}, $i;
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{diskpath}/i) {
                push @{$self->{diskpath_id_selected}}, $i;
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{diskpath}/) {
                push @{$self->{diskpath_id_selected}}, $i;
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{diskpath}) {
                push @{$self->{diskpath_id_selected}}, $i;
            }
        }
    }
    
    if (scalar(@{$self->{diskpath_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No disk path found. Can be: filters, cache file.");
        $self->{output}->option_exit();
    }
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{statefile_cache}->get(name => "dskPath_" . $options{id});
    
    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

1;

__END__

=head1 MODE

Check usage on partitions (UCD-SNMP-MIB).
Need to enable "includeAllDisks 10%" on snmpd.conf.

=over 8

=item B<--filter-counters>

Filter counters to be displayed (Default: 'usage', Can be: 'usage', 'count').

=item B<--warning-*>

Threshold warning (Can be: 'usage', 'count').

=item B<--critical-*>

Threshold warning (Can be: 'usage', 'count').

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--diskpath>

Set the disk path (number expected) ex: 1, 2,... (empty means 'check all disk path').

=item B<--name>

Allows to use disk path name with option --diskpath instead of disk path oid index.

=item B<--regexp>

Allows to use regexp to filter disk path (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--show-cache>

Display cache disk path datas.

=item B<--space-reservation>

Some filesystem has space reserved (like ext4 for root).
The value is in percent of total (Default: none) (results like 'df' command).

=back

=cut
