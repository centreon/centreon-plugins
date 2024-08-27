#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use Safe;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' }
    });

    $self->{safe} = Safe->new();
    $self->{safe}->share('$assign_var');

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
}

my @labels = ('size', 'name', 'label', 'type'); 
my $map_types = {
    0 => 'unknown',
    1 => 'noRootDirectory',
    2 => 'removableDisk',
    3 => 'localDisk',
    4 => 'networkDrive',
    5 => 'compactDisc',
    6 => 'ramDisk'
};

sub get_display_value {
    my ($self, %options) = @_;

    our $assign_var = $options{name};
    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));

        $self->{safe}->reval("\$assign_var =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}", 1);
        if ($@) {
            die 'Unsafe code evaluation: ' . $@;
        }
    }

    return $assign_var;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $entries = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => 'Select Capacity,DeviceID,DriveLetter,DriveType,FileSystem,FreeSpace,Label,Name from Win32_Volume',
        result_type => 'array'
    );

    my $results = {};
    foreach my $entry (@$entries) {
        my $display_value = $self->get_display_value(name => $entry->{Name} );
        $results->{ $entry->{DeviceID} } = {
            size => $entry->{Capacity},
            name => $display_value,
            label => $entry->{Label},
            type => $map_types->{ $entry->{DriveType} }
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(wsman => $options{wsman});
    foreach my $instance (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_: " . $results->{$instance}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List storages:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [@labels]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(wsman => $options{wsman});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}
1;

__END__

=head1 MODE

List storages.

=over 8

=item B<--display-transform-src> B<--display-transform-dst>

Modify the storage name displayed by using a regular expression.

Example: adding --display-transform-src='dev' --display-transform-dst='run'  will replace all occurrences of 'dev' with 'run'

=back

=cut
