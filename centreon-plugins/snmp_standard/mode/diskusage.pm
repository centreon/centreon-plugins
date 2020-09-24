#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'diskpath', type => 1, cb_prefix_output => 'prefix_diskpath_output', message_multiple => 'All partitions are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'storage.partitions.count', display_ok => 0, set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Partitions count : %d',
                perfdatas => [
                    { label => 'count', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{diskpath} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'storage.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'storage.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { label => 'used_prct', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'inodes', nlabel => 'storage.inodes.usage.percentage', set => {
                key_values => [ { name => 'inodes' }, { name => 'display' } ],
                output_template => 'Inodes used: %s %%',
                perfdatas => [
                    { label => 'inodes', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_diskpath_output {
    my ($self, %options) = @_;
    
    return "Partition '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'units:s'                 => { name => 'units', default => '' },
        'free'                    => { name => 'free' },
        'reload-cache-time:s'     => { name => 'reload_cache_time', default => 180 },
        'name'                    => { name => 'use_name' },
        'diskpath:s'              => { name => 'diskpath' },
        'regexp'                  => { name => 'use_regexp' },
        'regexp-isensitive'       => { name => 'use_regexpi' },
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' },
        'show-cache'              => { name => 'show_cache' },
        'space-reservation:s'     => { name => 'space_reservation' },
        'force-use-mib-percent'   => { name => 'force_use_mib_percent' },
        'force-counters32'        => { name => 'force_counters32' }
    });

    $self->{diskpath_id_selected} = [];
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    # Compatibility
    $self->compat_threshold_counter(%options, 
        compat => { 
            th => [ ['usage', { free => 'usage-free', prct => 'usage-prct'} ], [ 'storage.space.usage.bytes', { free => 'storage.space.free.bytes', prct => 'storage.space.usage.percentage' } ] ], 
            units => $options{option_results}->{units}, free => $options{option_results}->{free}
        }
    );

    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{space_reservation}) && 
        ($self->{option_results}->{space_reservation} < 0 || $self->{option_results}->{space_reservation} > 100)) {
        $self->{output}->add_option_msg(short_msg => "Space reservation argument must be between 0 and 100 percent.");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_cache}->check_options(%options);
}

my $mapping = {
    dskTotal32     => { oid => '.1.3.6.1.4.1.2021.9.1.6' }, # kB
    dskUsed32      => { oid => '.1.3.6.1.4.1.2021.9.1.8' }, # kB
    dskPercent     => { oid => '.1.3.6.1.4.1.2021.9.1.9' },
    dskPercentNode => { oid => '.1.3.6.1.4.1.2021.9.1.10' },
    dskTotalLow    => { oid => '.1.3.6.1.4.1.2021.9.1.11' }, # kB
    dskTotalHigh   => { oid => '.1.3.6.1.4.1.2021.9.1.12' }, # kB
    dskUsedLow     => { oid => '.1.3.6.1.4.1.2021.9.1.15' }, # kB
    dskUsedHigh    => { oid => '.1.3.6.1.4.1.2021.9.1.16' } # kB
};

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->get_selection(snmp => $options{snmp});

    delete($mapping->{dskPercent}) if (!defined($self->{option_results}->{force_use_mib_percent}));
    if (!defined($self->{option_results}->{force_counters32})) {
        delete($mapping->{dskTotal32});
        delete($mapping->{dskUsed32});
    } else {
        delete($mapping->{dskTotalLow});
        delete($mapping->{dskTotalHigh});
        delete($mapping->{dskUsedLow});
        delete($mapping->{dskUsedHigh});
    }

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => $self->{diskpath_id_selected},
        nothing_quit => 1
    );
    my $snmp_result = $options{snmp}->get_leef();

    $self->{global}->{count} = 0;
    $self->{diskpath} = {};
    foreach (sort @{$self->{diskpath_id_selected}}) {
        my $name_diskpath = $self->get_display_value(id => $_);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        if (!defined($result->{dskTotal32}) && !defined($result->{dskTotalHigh})) {
            $self->{output}->add_option_msg(
                long_msg => sprintf(
                    "skipping partition '%s': not found (need to reload the cache)", 
                    $name_diskpath
                )
            );
            next;
        }

        my $total_size = defined($result->{dskTotalHigh}) ? ((($result->{dskTotalHigh} << 32) + $result->{dskTotalLow}) * 1024) : $result->{dskTotal32} * 1024;
        if ($total_size == 0) {
            $self->{output}->output_add(long_msg => sprintf("skipping partition '%s' (total size is 0)", $name_diskpath), debug => 1);
            next;
        }
        my $total_used = defined($result->{dskUsedHigh}) ? ((($result->{dskUsedHigh} << 32) + $result->{dskUsedLow}) * 1024) : $result->{dskUsed32} * 1024;

        my $reserved_value = 0;
        if (defined($self->{option_results}->{space_reservation})) {
            $reserved_value = $self->{option_results}->{space_reservation} * $total_size / 100;
        }

        my $prct_used = $total_used * 100 / ($total_size - $reserved_value);
        my $prct_free = 100 - $prct_used;
        my $free = $total_size - $total_used - $reserved_value;
        # limit to 100. Better output.
        if ($prct_used > 100) {
            $free = 0;
            $prct_used = 100;
            $prct_free = 0;
        }

        $prct_used = $result->{dskPercent} if (defined($self->{option_results}->{force_use_mib_percent}));
        $self->{diskpath}->{$name_diskpath} = {
            display => $name_diskpath,
            total => $total_size,
            used => $total_used,
            free => $free,
            prct_free => $prct_free,
            prct_used => $prct_used,
            inodes => $result->{dskPercentNode}
        };
        $self->{global}->{count}++;
    }

    if (scalar(keys %{$self->{diskpath}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'Issue with disk path information (see details)');
        $self->{output}->option_exit();
    }
}

sub reload_cache {
    my ($self, %options) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];

    my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

    my $result = $options{snmp}->get_table(oid => $oid_dskPath);
    foreach my $key (keys %$result) {
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
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
            $self->reload_cache(snmp => $options{snmp});
            $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{diskpath})) {
        # get by ID
        my $name = $self->{statefile_cache}->get(name => 'dskPath_' . $self->{option_results}->{diskpath});
        push @{$self->{diskpath_id_selected}}, $self->{option_results}->{diskpath} if (defined($name));
    } else {
        foreach my $i (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => 'dskPath_' . $i);
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
    my $value = $self->{statefile_cache}->get(name => 'dskPath_' . $options{id});

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

Filter counters to be displayed (Can be: 'usage', 'count', 'inodes').

=item B<--warning-*> B<--critical-*>

Thresholds (Can be: 'usage', 'usage-free', 'usage-prct', 'inodes', 'count').

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

=item B<--force-use-mib-percent>

Can be used if you have counters overload by big disks.

=item B<--force-counters32>

Force to use 32 bits counters. Should be used when 64 bits high/low components are not available.

=back

=cut
