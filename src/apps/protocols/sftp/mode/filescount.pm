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

package apps::protocols::sftp::mode::filescount;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'files-detected', nlabel => 'files.detected.count', set => {
            key_values      => [ { name => 'detected' } ],
            output_template => 'number of files: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
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
        'directory:s@'  => { name => 'directory' },
        'max-depth:s'   => { name => 'max_depth', default => 0 },
        'filter-file:s' => { name => 'filter_file' }
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

    if (scalar(@$dirs) == 0) {
        $self->{output}->add_option_msg(short_msg => 'Set --directory option');
        $self->{output}->option_exit();
    }

    $self->{option_results}->{directory} = $dirs;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($rv, $message) = $options{custom}->connect();
    if ($rv != 0) {
        $self->{output}->add_option_msg(short_msg => $message);
        $self->{output}->option_exit();
    }

    $self->{global} = { detected => 0 };
    $self->countFiles(custom => $options{custom});
}

sub countFiles {
    my ($self, %options) = @_;
    my @listings;

    foreach my $dir (@{$self->{option_results}->{directory}}) {
        push @listings, [ { name => $dir, level => 0 } ];
    }

    my @build_name = ();
    foreach my $list (@listings) {
        while (@$list) {
            my @files;
            my $hash = pop(@$list);
            my $dir = $hash->{name};
            my $level = $hash->{level};

            my $rv = $options{custom}->list_directory(dir => $dir);
            if ($rv->{code} != 0) {
                # Cannot list we skip
                next;
            }
            # this loop is recursive, when we find a directory we add it to the list used by the for loop.
            # max_depth is used to limit the depth we search.
            # same behaviour as cifs(samba) and ftp protocol.
            foreach my $file (@{$rv->{files}}) {
                next if ($file->{name} eq '.' || $file->{name} eq '..');
                my $name = $dir . '/' . $file->{name};

                if ($file->{type} == 2) {
                    # case of a directory
                    if (defined($self->{option_results}->{max_depth}) && $level + 1 <= $self->{option_results}->{max_depth}) {
                        push @$list, { name => $name, level => $level + 1 };
                    }
                    next;
                } elsif (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_file})
                    && $name !~ /$self->{option_results}->{filter_file}/) {
                    $self->{output}->output_add(long_msg => sprintf("skipping '%s'", $name), debug => 1);
                    next;
                }
                $self->{output}->output_add(long_msg => sprintf("Match '%s'", $name));
                $self->{global}->{detected}++;
            }
        }
    }
}

1;

__END__

=head1 MODE

Count files in a directory (can be recursive).

=over 8

=item B<--directory>

Check files in the directory (multiple option)

=item B<--max-depth>

Don't check fewer levels (default: '0'. Means current dir only).

=item B<--filter-file>

Filter files (can be a regexp. Directory in the name).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'mtime-last'.

=back

=cut
