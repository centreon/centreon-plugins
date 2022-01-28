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

package os::windows::wsman::mode::liststorages;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %storage_types_manage = (
    0 => 'unknown',
    1 => 'noRootDirectory',
    2 => 'removableDisk',
    3 => 'localDisk',
    4 => 'networkDrive',
    5 => 'compactDisc',
    6 => 'ramDisk'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'storage:s'               => { name => 'storage' },
        'filter-type:s'           => { name => 'filter_storage_type', 'default' => 'localDisk'},
    });

    $self->{storage_id_selected} = [];
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if ($self->{option_results}->{filter_storage_type} !~ /^(unknown|noRootDirectory|removableDisk|localDisk|networkDrive|compactDisc|ramDisk)$/) {
       $self->{output}->add_option_msg(short_msg => "Unsupported --filter-type option.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{wsman} = $options{wsman};

    $self->manage_selection();

    foreach my $drive (sort(keys %{$self->{result}})) {
        if (!defined($self->{result}->{$drive}->{DriveType}) ||
            ($storage_types_manage{$self->{result}->{$drive}->{DriveType}} !~ /$self->{option_results}->{filter_storage_type}/i)) {
            $self->{output}->output_add(long_msg => "Skipping storage '" . $self->{result}->{$drive}->{DeviceID} . "': no type or no matching filter type");
            next;
        }
        if (defined($self->{option_results}->{storage})) {
            my $storage = ($self->{option_results}->{storage} ne '') ? $self->{option_results}->{storage} : '.*';
            next if ($self->{result}->{$drive}->{DeviceID} !~ /$storage/);
        }
        $self->{output}->output_add(
            long_msg => sprintf(
                "'%s' [size: %s][desc: %s][type: %s]",
                $self->{result}->{$drive}->{DeviceID},
                defined($self->{result}->{$drive}->{Size}) ? $self->{result}->{$drive}->{Size} : '',
                defined($self->{result}->{$drive}->{Description}) ? $self->{result}->{$drive}->{Description} : '',
                $storage_types_manage{$self->{result}->{$drive}->{DriveType}}
            )
        );
    }


    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List storage:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result} = $self->{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => "select DriveType,DeviceID,Description,Size from Win32_LogicalDisk",
        result_type => 'hash',
        hash_key => 'DeviceID'
    );

    if (scalar(keys %{$self->{result}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get storages...");
        $self->{output}->option_exit();
    }
    
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'total', 'storagetype','desc']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{wsman} = $options{wsman};

    $self->manage_selection(disco => 1);
    foreach my $drive (sort(keys %{$self->{result}})) {
        if (!defined($self->{result}->{$drive}->{DriveType}) ||
            ($storage_types_manage{$self->{result}->{$drive}->{DriveType}} !~ /$self->{option_results}->{filter_storage_type}/i)) {
            next;
        }
        if (defined($self->{option_results}->{storage})) {
            my $storage = ($self->{option_results}->{storage} ne '') ? $self->{option_results}->{storage} : '.*';
            next if ($self->{result}->{$drive}->{DeviceID} !~ /$storage/);
        }
        $self->{output}->add_disco_entry(name => $self->{result}->{$drive}->{DeviceID},
                                         total => $self->{result}->{$drive}->{Size},
                                         desc => $self->{result}->{$drive}->{Description},
                                         storagetype => $storage_types_manage{$self->{result}->{$drive}->{DriveType}}
        );
    }
}

1;

__END__

=head1 MODE

=over 8

=item B<--storage>

Set the storage ex: C, D,... (empty means 'check all storage').
Regexp accepted.

=item B<--filter-storage>

Choose  filter storage (default: localDisk) (values: unknown, noRootDirectory, removableDisk, localDisk, networkDrive, compactDisc, ramDisk).

=back

=cut
