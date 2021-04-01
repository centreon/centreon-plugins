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

package snmp_standard::mode::storage;

use base qw(centreon::plugins::templates::counter);

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

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'storage.space.free.bytes');
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
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size'} * $options{new_datas}->{$self->{instance} . '_allocation_units'};
    my $reserved_value = 0;
    if (defined($self->{instance_mode}->{option_results}->{space_reservation})) {
        $reserved_value = $self->{instance_mode}->{option_results}->{space_reservation} * $self->{result_values}->{total} / 100;
    }
    
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'} * $options{new_datas}->{$self->{instance} . '_allocation_units'};
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

sub custom_access_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Access : %s", 
        $self->{result_values}->{access} == 1 ? 'readWrite' : 'readOnly'
    );

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'storage', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'storage.partitions.count', display_ok => 0, set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Partitions count : %d',
                perfdatas => [
                    { label => 'count', value => 'count', template => '%d', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'size' }, { name => 'allocation_units' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
        { label => 'access', nlabel => 'storage.access', set => {
                key_values => [ { name => 'access' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_access_output'),
                perfdatas => [
                    { label => 'access', value => 'access', template => '%d', min => 1, max => 2, 
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Storage '" . $options{instance_value}->{display} . "' ";
}

sub default_storage_type {
    my ($self, %options) = @_;

    return '^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'units:s'                 => { name => 'units', default => '%' },
        'free'                    => { name => 'free' },
        'reload-cache-time:s'     => { name => 'reload_cache_time', default => 180 },
        'name'                    => { name => 'use_name' },
        'storage:s'               => { name => 'storage' },
        'regexp'                  => { name => 'use_regexp' },
        'regexp-isensitive'       => { name => 'use_regexpi' },
        'oid-filter:s'            => { name => 'oid_filter', default => 'hrStorageDescr'},
        'oid-display:s'           => { name => 'oid_display', default => 'hrStorageDescr'},
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' },
        'show-cache'              => { name => 'show_cache' },
        'space-reservation:s'     => { name => 'space_reservation' },
        'filter-duplicate'        => { name => 'filter_duplicate' },
        'filter-storage-type:s'   => { name => 'filter_storage_type', default => $self->default_storage_type() },
        'add-access'              => { name => 'add_access' },
    });

    $self->{storage_id_selected} = [];
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

sub access_result {
    my ($self, %options) = @_;

    return {}
        if (!defined($self->{option_results}->{add_access}));
    my $oid_hrFSAccess = '.1.3.6.1.2.1.25.3.8.1.5';
    my $relations = $self->{statefile_cache}->get(name => 'relation_storageindex_fsstorageindex');
    return {} if (!defined($relations) || scalar(keys %$relations) <= 0);
    my $instances = [];
    foreach (@{$self->{storage_id_selected}}) {
        if (defined($relations->{$_})) {
            push @$instances, $relations->{$_};
        }
    }

    $options{snmp}->load(
        oids => [$oid_hrFSAccess], 
        instances => $instances,
        nothing_quit => 1
    );
    my $snmp_result = $options{snmp}->get_leef();
    my $result = {};
    foreach (@{$self->{storage_id_selected}}) {
        if (defined($snmp_result->{$oid_hrFSAccess . '.' . $relations->{$_}})) {
            $result->{$_} = $snmp_result->{$oid_hrFSAccess . '.' . $relations->{$_}};
        }
    }

    return $result;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->get_selection(snmp => $options{snmp});

    my $oid_hrStorageAllocationUnits = '.1.3.6.1.2.1.25.2.3.1.4';
    my $oid_hrStorageSize = '.1.3.6.1.2.1.25.2.3.1.5';
    my $oid_hrStorageUsed = '.1.3.6.1.2.1.25.2.3.1.6';
    my $oid_hrStorageType = '.1.3.6.1.2.1.25.2.3.1.2';

    $options{snmp}->load(
        oids => [$oid_hrStorageAllocationUnits, $oid_hrStorageSize, $oid_hrStorageUsed], 
        instances => $self->{storage_id_selected},
        nothing_quit => 1
    );
    my $result = $options{snmp}->get_leef();
    my $access_result = $self->access_result(snmp => $options{snmp});

    $self->{global}->{count} = 0;
    $self->{storage} = {};
    foreach (sort @{$self->{storage_id_selected}}) {
        my $name_storage = $self->get_display_value(id => $_);

        if (!defined($result->{$oid_hrStorageAllocationUnits . "." . $_})) {
            $self->{output}->add_option_msg(
                long_msg => sprintf(
                    "skipping storage '%s': not found (need to reload the cache)", 
                    $name_storage
                )
            );
            next;
        }
        
        # in bytes hrStorageAllocationUnits
        my $total_size = $result->{$oid_hrStorageSize . "." . $_} * $result->{$oid_hrStorageAllocationUnits . "." . $_};
        if ($total_size <= 0) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    "skipping storage '%s': total size is <= 0 (%s)", 
                    $name_storage,
                    int($total_size)
                ),
                debug => 1
            );
            next;
        }
        
        if (defined($self->{option_results}->{filter_duplicate})) {
            my $duplicate = 0;
            foreach my $entry (values %{$self->{storage}}) {
                if (($entry->{allocation_units} == $result->{$oid_hrStorageAllocationUnits . '.' . $_}) &&
                    ($entry->{size} == $result->{$oid_hrStorageSize . "." . $_}) &&
                    ($entry->{used} == $result->{$oid_hrStorageUsed . "." . $_})) {
                    $duplicate = 1;
                    last;
                }
            }                
            next if ($duplicate == 1);
        }

        $self->{storage}->{$_} = {
            display => $name_storage,
            allocation_units => $result->{$oid_hrStorageAllocationUnits . '.' . $_},
            size => $result->{$oid_hrStorageSize . '.' . $_},
            used => $result->{$oid_hrStorageUsed . '.' . $_},
            access => defined($access_result->{$_}) ? $access_result->{$_} : undef,
        };
        $self->{global}->{count}++;
    }
    
    if (scalar(keys %{$self->{storage}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'Issue with storage information (see details)');
        $self->{output}->option_exit();
    }
}

sub reload_cache {
    my ($self, %options) = @_;
    my $datas = {};

    $datas->{oid_filter} = $self->{option_results}->{oid_filter};
    $datas->{oid_display} = $self->{option_results}->{oid_display};
    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];
    $datas->{relation_storageindex_fsstorageindex} = {};
    
    my $request = [ { oid => $oids_hrStorageTable{hrstoragetype} } ];
    my $added = {};
    my $build_relation = 0;
    foreach (($self->{option_results}->{oid_filter}, $self->{option_results}->{oid_display} )) {
        next if (defined($added->{$_}));
        $added->{$_} = 1;
        if (/hrFSMountPoint/i) {
            push @{$request}, ({ oid => $oids_hrStorageTable{hrfsmountpoint} }, { oid => $oids_hrStorageTable{hrfsstorageindex} });
            $build_relation = 1;
        } else {
            push @{$request}, { oid => $oids_hrStorageTable{hrstoragedescr} };
        }
    }
    
    if (defined($self->{option_results}->{add_access}) && !defined($added->{hrFSMountPoint})) {
        push @{$request}, { oid => $oids_hrStorageTable{hrfsstorageindex} };
        $build_relation = 1;
    }

    my $result = $options{snmp}->get_multiple_table(oids => $request);
    foreach ((['filter', $self->{option_results}->{oid_filter}], ['display', $self->{option_results}->{oid_display}], ['type', 'hrstoragetype'])) {
        foreach my $key ($options{snmp}->oid_lex_sort(keys %{$result->{ $oids_hrStorageTable{$$_[1]} }})) {
            next if ($key !~ /\.([0-9]+)$/);
            # get storage index
            my $storage_index = $1;
            if ($$_[1] =~ /hrFSMountPoint/i) {
                $storage_index = $result->{ $oids_hrStorageTable{hrfsstorageindex} }->{$oids_hrStorageTable{hrfsstorageindex} . '.' . $storage_index};
            }            
            if ($$_[0] eq 'filter') {
                push @{$datas->{all_ids}}, $storage_index;
            }

            $datas->{$$_[1] . "_" . $storage_index} = $self->{output}->decode($result->{ $oids_hrStorageTable{$$_[1]} }->{$key});
        }
    }
    
    if ($build_relation == 1) {
        foreach (keys %{$result->{ $oids_hrStorageTable{hrfsstorageindex} }}) {
            /\.([0-9]+)$/;
            $datas->{relation_storageindex_fsstorageindex}->{ $result->{ $oids_hrStorageTable{hrfsstorageindex} }->{$_} } = $1;
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

sub get_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
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
            $self->reload_cache(snmp => $options{snmp});
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

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--warning-access>

Threshold warning. 

=item B<--critical-access>

Threshold critical.
Check if storage is readOnly: --critical-access=@2:2

=item B<--add-access>

Check storage access (readOnly, readWrite).

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

Time in minutes before reloading cache file (default: 180).

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

=item B<--filter-duplicate>

Filter duplicate storages (in used size and total size).

=item B<--filter-storage-type>

Filter storage types with a regexp (Default: '^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$').

=back

=cut
