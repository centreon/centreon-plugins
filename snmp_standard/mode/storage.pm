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

package snmp_standard::mode::storage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my %oids_hrStorageTable = (
    'hrstoragedescr'    => '.1.3.6.1.2.1.25.2.3.1.3',
    'hrfsmountpoint'    => '.1.3.6.1.2.1.25.3.8.1.2',
    'hrfsstorageindex'  => '.1.3.6.1.2.1.25.3.8.1.7',
    'hrstoragetype'     => '.1.3.6.1.2.1.25.2.3.1.2',
);
my %storage_types_manage = (
    '.1.3.6.1.2.1.25.2.1.1'  => 'hrStorageOther',
    '.1.3.6.1.2.1.25.2.1.2'  => 'hrStorageRam',
    '.1.3.6.1.2.1.25.2.1.3'  => 'hrStorageVirtualMemory',
    '.1.3.6.1.2.1.25.2.1.4'  => 'hrStorageFixedDisk',
    '.1.3.6.1.2.1.25.2.1.5'  => 'hrStorageRemovableDisk',
    '.1.3.6.1.2.1.25.2.1.6'  => 'hrStorageFloppyDisk',
    '.1.3.6.1.2.1.25.2.1.7'  => 'hrStorageCompactDisc',
    '.1.3.6.1.2.1.25.2.1.8'  => 'hrStorageRamDisk',
    '.1.3.6.1.2.1.25.2.1.9'  => 'hrStorageFlashMemory',
    '.1.3.6.1.2.1.25.2.1.10' => 'hrStorageNetworkDisk',
    '.1.3.6.1.2.1.25.3.9.1'  => 'hrFSOther',
    '.1.3.6.1.2.1.25.3.9.2'  => 'hrFSUnknown',
    '.1.3.6.1.2.1.25.3.9.3'  => 'hrFSBerkeleyFFS', # For Freebsd
    '.1.3.6.1.2.1.25.3.9.4'  => 'hrFSSys5FS',
    '.1.3.6.1.2.1.25.3.9.5'  => 'hrFSFat',
    '.1.3.6.1.2.1.25.3.9.6'  => 'hrFSHPFS',
    '.1.3.6.1.2.1.25.3.9.7'  => 'hrFSHFS',
    '.1.3.6.1.2.1.25.3.9.8'  => 'hrFSMFS',
    '.1.3.6.1.2.1.25.3.9.9'  => 'hrFSNTFS',
    '.1.3.6.1.2.1.25.3.9.10' => 'hrFSVNode',
    '.1.3.6.1.2.1.25.3.9.11' => 'hrFSJournaled',
    '.1.3.6.1.2.1.25.3.9.12' => 'hrFSiso9660',
    '.1.3.6.1.2.1.25.3.9.13' => 'hrFSRockRidge',
    '.1.3.6.1.2.1.25.3.9.14' => 'hrFSNFS',
    '.1.3.6.1.2.1.25.3.9.15' => 'hrFSNetware',
    '.1.3.6.1.2.1.25.3.9.16' => 'hrFSAFS',
    '.1.3.6.1.2.1.25.3.9.17' => 'hrFSDFS',
    '.1.3.6.1.2.1.25.3.9.18' => 'hrFSAppleshare',
    '.1.3.6.1.2.1.25.3.9.19' => 'hrFSRFS',
    '.1.3.6.1.2.1.25.3.9.20' => 'hrFSDGCFS',
    '.1.3.6.1.2.1.25.3.9.21' => 'hrFSBFS',
    '.1.3.6.1.2.1.25.3.9.22' => 'hrFSFAT32',
    '.1.3.6.1.2.1.25.3.9.23' => 'hrFSLinuxExt2',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "units:s"                 => { name => 'units', default => '%' },
                                  "free"                    => { name => 'free' },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                  "name"                    => { name => 'use_name' },
                                  "storage:s"               => { name => 'storage' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "oid-filter:s"            => { name => 'oid_filter', default => 'hrStorageDescr'},
                                  "oid-display:s"           => { name => 'oid_display', default => 'hrStorageDescr'},
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                  "show-cache"              => { name => 'show_cache' },
                                  "space-reservation:s"     => { name => 'space_reservation' },
                                  "filter-storage-type:s"   => { name => 'filter_storage_type', default => '^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$' },
                                });

    $self->{storage_id_selected} = [];
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{space_reservation}) && 
        ($self->{option_results}->{space_reservation} < 0 || $self->{option_results}->{space_reservation} > 100)) {
       $self->{output}->add_option_msg(short_msg => "Space reservation argument must be between 0 and 100 percent.");
       $self->{output}->option_exit();
    }
    
    $self->{option_results}->{oid_filter} = lc($self->{option_results}->{oid_filter});
    if ($self->{option_results}->{oid_filter} !~ /^(hrstoragedescr|hrfsmountpoint)$/) {
       $self->{output}->add_option_msg(short_msg => "Unsupported --oid-filter option.");
       $self->{output}->option_exit();
    }
    $self->{option_results}->{oid_display} = lc($self->{option_results}->{oid_display});
    if ($self->{option_results}->{oid_display} !~ /^(hrstoragedescr|hrfsmountpoint)$/) {
       $self->{output}->add_option_msg(short_msg => "Unsupported --oid-display option.");
       $self->{output}->option_exit();
    }
    
    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    my $oid_hrStorageAllocationUnits = '.1.3.6.1.2.1.25.2.3.1.4';
    my $oid_hrStorageSize = '.1.3.6.1.2.1.25.2.3.1.5';
    my $oid_hrStorageUsed = '.1.3.6.1.2.1.25.2.3.1.6';
    my $oid_hrStorageType = '.1.3.6.1.2.1.25.2.3.1.2';

    $self->{snmp}->load(oids => [$oid_hrStorageAllocationUnits, $oid_hrStorageSize, $oid_hrStorageUsed], 
                        instances => $self->{storage_id_selected}, nothing_quit => 1);
    my $result = $self->{snmp}->get_leef();
    my $multiple = 0;
    if (scalar(@{$self->{storage_id_selected}}) > 1) {
        $multiple = 1;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All storages are ok.');
    }

    foreach (sort @{$self->{storage_id_selected}}) {
        my $name_storage = $self->get_display_value(id => $_);

        # in bytes hrStorageAllocationUnits
        my $total_size = $result->{$oid_hrStorageSize . "." . $_} * $result->{$oid_hrStorageAllocationUnits . "." . $_};
        if ($total_size <= 0) {
            if ($multiple == 0) {
                $self->{output}->add_option_msg(severity => 'UNKNOWN',
                                                short_msg => sprintf("Skipping storage '%s': total size is <= 0 (%s)", 
                                                                     $name_storage, int($total_size)));
            } else {
                $self->{output}->add_option_msg(long_msg => sprintf("Skipping storage '%s': total size is <= 0 (%s)", 
                                                                    $name_storage, int($total_size)));
            }
            next;
        }
        
        my $reserved_value = 0;
        if (defined($self->{option_results}->{space_reservation})) {
            $reserved_value = $self->{option_results}->{space_reservation} * $total_size / 100;
        }
        my $total_used = $result->{$oid_hrStorageUsed . "." . $_} * $result->{$oid_hrStorageAllocationUnits . "." . $_};
        my $total_free = $total_size - $total_used - $reserved_value;
        my $prct_used = $total_used * 100 / ($total_size - $reserved_value);
        my $prct_free = 100 - $prct_used;
        
        # limit to 100. Better output.
        if ($prct_used > 100) {
            $total_free = 0;
            $prct_used = 100;
            $prct_free = 0;
        }

        my ($exit, $threshold_value);

        $threshold_value = $total_used;
        $threshold_value = $total_free if (defined($self->{option_results}->{free}));
        if ($self->{option_results}->{units} eq '%') {
            $threshold_value = $prct_used;
            $threshold_value = $prct_free if (defined($self->{option_results}->{free}));
        } 
        $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $total_size);
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $total_used);
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $total_free);

        $self->{output}->output_add(long_msg => sprintf("Storage '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name_storage,
                                            $total_size_value . " " . $total_size_unit,
                                            $total_used_value . " " . $total_used_unit, $prct_used,
                                            $total_free_value . " " . $total_free_unit, $prct_free));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || ($multiple == 0)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Storage '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name_storage,
                                            $total_size_value . " " . $total_size_unit,
                                            $total_used_value . " " . $total_used_unit, $prct_used,
                                            $total_free_value . " " . $total_free_unit, $prct_free));
        }    

        my $label = 'used';
        my $value_perf = $total_used;
        if (defined($self->{option_results}->{free})) {
            $label = 'free';
            $value_perf = $total_free;
        }
        my $extra_label = '';
        $extra_label = '_' . $name_storage if ($multiple == 1);
        my %total_options = ();
        if ($self->{option_results}->{units} eq '%') {
            $total_options{total} = $total_size - $reserved_value;
            $total_options{cast_int} = 1; 
        }
        $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                      value => $value_perf,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', %total_options),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', %total_options),
                                      min => 0, max => int($total_size - $reserved_value));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{oid_filter} = $self->{option_results}->{oid_filter};
    $datas->{oid_display} = $self->{option_results}->{oid_display};
    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];
    
    my $request = [ { oid => $oids_hrStorageTable{hrstoragetype} } ];
    my $added = {};
    foreach (($self->{option_results}->{oid_filter}, $self->{option_results}->{oid_display} )) {
        next if (defined($added->{$_}));
        $added->{$_} = 1;
        if (/hrFSMountPoint/i) {
            push @{$request}, ({ oid => $oids_hrStorageTable{hrfsmountpoint} }, { oid => $oids_hrStorageTable{hrfsstorageindex} });
        } else {
            push @{$request}, { oid => $oids_hrStorageTable{hrstoragedescr} };
        }
    }

    my $result = $self->{snmp}->get_multiple_table(oids => $request);
    foreach ((['filter', $self->{option_results}->{oid_filter}], ['display', $self->{option_results}->{oid_display}], ['type', 'hrstoragetype'])) {
        foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{ $oids_hrStorageTable{$$_[1]} }})) {
            next if ($key !~ /\.([0-9]+)$/);
            # get storage index
            my $storage_index = $1;
            if ($$_[1] =~ /hrFSMountPoint/i) {
                $storage_index = $result->{ $oids_hrStorageTable{hrfsstorageindex} }->{$oids_hrStorageTable{hrfsstorageindex} . '.' . $storage_index};
            }            
            if ($$_[0] eq 'filter') {
                push @{$datas->{all_ids}}, $storage_index;
            }

            $datas->{$$_[1] . "_" . $storage_index} = $self->{output}->to_utf8($result->{ $oids_hrStorageTable{$$_[1]} }->{$key});
        }
    }

    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub filter_type {
    my ($self, %options) = @_;
    
    my $storage_type = $self->{statefile_cache}->get(name => "hrstoragetype_" . $options{id});
    if (defined($storage_type) && 
        ($storage_types_manage{$storage_type} =~ /$self->{option_results}->{filter_storage_type}/i)) {
        return 1;
    }
    return 0;
}

sub manage_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $oid_display = $self->{statefile_cache}->get(name => 'oid_display');
    my $oid_filter = $self->{statefile_cache}->get(name => 'oid_filter');
    if ($has_cache_file == 0 ||
        ($self->{option_results}->{oid_display} !~ /^($oid_display|$oid_filter)$/i || $self->{option_results}->{oid_filter} !~ /^($oid_display|$oid_filter)$/i) ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
            $self->reload_cache();
            $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{storage})) {
        # get by ID
        my $name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_filter} . "_" . $self->{option_results}->{storage});
        push @{$self->{storage_id_selected}}, $self->{option_results}->{storage} if (defined($name) && $self->filter_type(id => $self->{option_results}->{storage}));
    } else {
        foreach my $i (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_filter} . "_" . $i);
            next if (!defined($filter_name));
            
            if (!defined($self->{option_results}->{storage})) {
                push @{$self->{storage_id_selected}}, $i if ($self->filter_type(id => $i));
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{storage}/i) {
                push @{$self->{storage_id_selected}}, $i if ($self->filter_type(id => $i));
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{storage}/) {
                push @{$self->{storage_id_selected}}, $i if ($self->filter_type(id => $i));
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{storage}) {
                push @{$self->{storage_id_selected}}, $i if ($self->filter_type(id => $i));
            }
        }
    }
    
    if (scalar(@{$self->{storage_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage found. Can be: filters, cache file.");
        $self->{output}->option_exit();
    }
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_display} . "_" . $options{id});
    
    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

1;

__END__

=head1 MODE

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--storage>

Set the storage (number expected) ex: 1, 2,... (empty means 'check all storage').

=item B<--name>

Allows to use storage name with option --storage instead of storage oid index.

=item B<--regexp>

Allows to use regexp to filter storage (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter storage (default: hrStorageDescr) (values: hrStorageDescr, hrFSMountPoint).

=item B<--oid-display>

Choose OID used to display storage (default: hrStorageDescr) (values: hrStorageDescr, hrFSMountPoint).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--show-cache>

Display cache storage datas.

=item B<--space-reservation>

Some filesystem has space reserved (like ext4 for root).
The value is in percent of total (Default: none) (results like 'df' command).

=item B<--filter-storage-type>

Filter storage types with a regexp (Default: '^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$').

=back

=cut
