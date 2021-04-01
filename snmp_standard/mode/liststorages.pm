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

package snmp_standard::mode::liststorages;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %oids_hrStorageTable = (
    'hrstoragedescr'    => '.1.3.6.1.2.1.25.2.3.1.3',
    'hrfsmountpoint'    => '.1.3.6.1.2.1.25.3.8.1.2',
    'hrfsstorageindex'  => '.1.3.6.1.2.1.25.3.8.1.7',
    'hrstoragetype'     => '.1.3.6.1.2.1.25.2.3.1.2',
);

my $oid_hrStorageAllocationUnits = '.1.3.6.1.2.1.25.2.3.1.4';
my $oid_hrStorageSize = '.1.3.6.1.2.1.25.2.3.1.5';
my $oid_hrStorageType = '.1.3.6.1.2.1.25.2.3.1.2';

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
    
    $options{options}->add_options(arguments => { 
        'storage:s'               => { name => 'storage' },
        'name'                    => { name => 'use_name' },
        'regexp'                  => { name => 'use_regexp' },
        'regexp-isensitive'       => { name => 'use_regexpi' },
        'oid-filter:s'            => { name => 'oid_filter', default => 'hrStorageDescr'},
        'oid-display:s'           => { name => 'oid_display', default => 'hrStorageDescr'},
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' },
        'filter-storage-type:s'   => { name => 'filter_storage_type', default => '^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$' }
    });

    $self->{storage_id_selected} = [];
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

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
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $result = $self->get_additional_information();

    foreach (sort @{$self->{storage_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);
        my $storage_type = $result->{$oid_hrStorageType . "." . $_};
        if (!defined($storage_type) || 
            ($storage_types_manage{$storage_type} !~ /$self->{option_results}->{filter_storage_type}/i)) {
            $self->{output}->output_add(long_msg => "Skipping storage '" . $display_value . "': no type or no matching filter type");
            next;
        }
        
        $self->{output}->output_add(long_msg => "'" . $display_value . "' [size = " . $result->{$oid_hrStorageSize . "." . $_} * $result->{$oid_hrStorageAllocationUnits . "." . $_}  . "B] [id = $_]");
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List storage:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub get_additional_information {
    my ($self, %options) = @_;
    
    $self->{snmp}->load(oids => [$oid_hrStorageType, $oid_hrStorageAllocationUnits, $oid_hrStorageSize], instances => $self->{storage_id_selected});
    return $self->{snmp}->get_leef();
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{datas}->{$self->{option_results}->{oid_display} . "_" . $options{id}};

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{datas} = {};
    $self->{datas}->{oid_filter} = $self->{option_results}->{oid_filter};
    $self->{datas}->{oid_display} = $self->{option_results}->{oid_display};
    $self->{datas}->{all_ids} = [];
    
    my $request = [];
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
    foreach ((['filter', $self->{option_results}->{oid_filter}], ['display', $self->{option_results}->{oid_display}])) {
        foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{ $oids_hrStorageTable{$$_[1]} }})) {
            next if ($key !~ /\.([0-9]+)$/);
            # get storage index
            my $storage_index = $1;
            if ($$_[1] =~ /hrFSMountPoint/i) {
                $storage_index = $result->{ $oids_hrStorageTable{hrfsstorageindex} }->{$oids_hrStorageTable{hrfsstorageindex} . '.' . $storage_index};
            }
            if ($$_[0] eq 'filter') {
                push @{$self->{datas}->{all_ids}}, $storage_index;
            }

            $self->{datas}->{$$_[1] . "_" . $storage_index} = $self->{output}->decode($result->{ $oids_hrStorageTable{$$_[1]} }->{$key});
        }
    }
    
    if (scalar(keys %{$self->{datas}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get storages...");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
       $result = $self->{snmp}->get_table(oid => $oids_hrStorageTable{$self->{option_results}->{oid_display}});
       foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
            next if ($key !~ /\.([0-9]+)$/);
            $self->{datas}->{$self->{option_results}->{oid_display} . "_" . $1} = $self->{output}->decode($result->{$key});
       }
    }
    
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{storage})) {
        # get by ID
        push @{$self->{storage_id_selected}}, $self->{option_results}->{storage}; 
        my $name = $self->{datas}->{$self->{option_results}->{oid_display} . "_" . $self->{option_results}->{storage}};
        if (!defined($name) && !defined($options{disco})) {
            $self->{output}->add_option_msg(short_msg => "No storage found for id '" . $self->{option_results}->{storage} . "'.");
            $self->{output}->option_exit();
        }
    } else {
        foreach my $i (@{$self->{datas}->{all_ids}}) {
            my $filter_name = $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $i};
            next if (!defined($filter_name));
            if (!defined($self->{option_results}->{storage})) {
                push @{$self->{storage_id_selected}}, $i; 
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{storage}/i) {
                push @{$self->{storage_id_selected}}, $i; 
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{storage}/) {
                push @{$self->{storage_id_selected}}, $i; 
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{storage}) {
                push @{$self->{storage_id_selected}}, $i; 
            }
        }
        
        if (scalar(@{$self->{storage_id_selected}}) <= 0 && !defined($options{disco})) {
            if (defined($self->{option_results}->{storage})) {
                $self->{output}->add_option_msg(short_msg => "No storage found for name '" . $self->{option_results}->{storage} . "'.");
            } else {
                $self->{output}->add_option_msg(short_msg => "No storage found.");
            }
            $self->{output}->option_exit();
        }
    }
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'total', 'storageid']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    my $result;
    if (scalar(@{$self->{storage_id_selected}}) > 0) {
        $result = $self->get_additional_information()
    }
    foreach (sort @{$self->{storage_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);
        my $storage_type = $result->{$oid_hrStorageType . "." . $_};
        next if (!defined($storage_type) || 
                ($storage_types_manage{$storage_type} !~ /$self->{option_results}->{filter_storage_type}/i));

        $self->{output}->add_disco_entry(name => $display_value,
                                         total => $result->{$oid_hrStorageSize . "." . $_} * $result->{$oid_hrStorageAllocationUnits . "." . $_},
                                         storageid => $_);
    }
}

1;

__END__

=head1 MODE

=over 8

=item B<--storage>

Set the storage (number expected) ex: 1, 2,... (empty means 'check all storage').

=item B<--name>

Allows to use storage name with option --storage instead of storage oid index.

=item B<--regexp>

Allows to use regexp to filter storage (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--oid-filter>

Choose OID used to filter storage (default: hrStorageDescr) (values: hrStorageDescr, hrFSMountPoint).

=item B<--oid-display>

Choose OID used to display storage (default: hrStorageDescr) (values: hrStorageDescr, hrFSMountPoint).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--filter-storage-type>

Filter storage types with a regexp (Default: '^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$').

=back

=cut
