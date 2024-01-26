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

package apps::protocols::cifs::mode::filessize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Filesys::SmbClient;

sub prefix_file_output {
    my ($self, %options) = @_;

    return "File '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'files', type => 1, cb_prefix_output => 'prefix_file_output', message_multiple => 'All files are ok' }
    ];

    $self->{maps_counters}->{files} = [
         { label => 'size', nlabel => 'file.size.bytes', set => {
                key_values  => [ { name => 'size' } ],
                output_template => 'size: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-file:s' => { name => 'filter_file' },
        'directory:s@'  => { name => 'directory' },
        'file:s@'       => { name => 'file' },
        'max-depth:s'   => { name => 'max_depth', default => 0 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    my $dirs = [];
    if (defined($self->{option_results}->{directory})) {
        foreach my $dir (@{$self->{option_results}->{directory}}) {
            push @$dirs, $dir if ($dir ne '');
        }
    }

    my $files = [];
    if (defined($self->{option_results}->{file})) {
        foreach my $file (@{$self->{option_results}->{file}}) {
            push @$files, $file if ($file ne '');
        }
    }

    if (scalar(@$files) == 0 && scalar(@$dirs) == 0) {
        $self->{output}->add_option_msg(short_msg => 'Set --file and/or --directory option');
        $self->{output}->option_exit();
    }

    $self->{option_results}->{directory} = $dirs;
    $self->{option_results}->{file} = $files;
}

sub check_directory {
    my ($self, %options) = @_;

    my @listings = ( [ { name => $options{dir}, level => 0 } ] );
    my @build_name = ();

    $self->{files}->{ $options{dir} } = { name => $options{dir}, size => 0 };

    foreach my $list (@listings) {
        while (@$list) {
            my @files;
            my $hash = pop(@$list);
            my $dir = $hash->{name};
            my $level = $hash->{level};

            my ($rv, $message, $files) =  $options{custom}->list_directory(directory => $dir);
            if ($rv != 0) {
                # Cannot list we skip
                next;
            }

            foreach my $file (@$files) {
                next if ($file->[0] != SMBC_FILE && $file->[0] != SMBC_DIR); 
                next if ($file->[1] eq '.' || $file->[1] eq '..');

                my $name = $dir . '/' . $file->[1];

                next if (defined($self->{option_results}->{filter_file}) && $self->{option_results}->{filter_file} ne '' &&
                    $name !~ /$self->{option_results}->{filter_file}/);

                if ($file->[0] == SMBC_DIR) {
                    if (defined($self->{option_results}->{max_depth}) && $level + 1 <= $self->{option_results}->{max_depth}) {
                        push @$list, { name => $name, level => $level + 1 };
                    }
                } else {
                    my $rv = $options{custom}->stat_file(file => $name);
                    $self->{files}->{ $options{dir} }->{size} += $rv->{size};
                }
            }        
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{files} = {};

    foreach my $dir (@{$self->{option_results}->{directory}}) {
        $self->check_directory(custom => $options{custom}, dir => $dir);
    }

    foreach my $file (@{$self->{option_results}->{file}}) {
        my $rv = $options{custom}->stat_file(file => $file);
        if ($rv->{code} != 0) {
            $self->{output}->add_option_msg(short_msg => "cannot stat file '" . $file . "': " . $rv->{message});
            $self->{output}->option_exit();
        }

        $self->{files}->{$file} = {
            name => $file,
            size => $rv->{size}
        };
    }
}

1;

__END__

=head1 MODE

Check files size.

=over 8

=item B<--directory>

Check directory size (multiple option).
Can get sub directory size with --max-depth option.

=item B<--file>

Check file (multiple option)

=item B<--filter-file>

Filter files (can be a regexp. Directory in the name).

=item B<--max-depth>

Don't check fewer levels (default: '0'. Means current dir only).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'size'.

=back

=cut
