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

package apps::protocols::cifs::mode::filesdate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Filesys::SmbClient;
use centreon::plugins::misc;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_mtime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        instances => $self->{result_values}->{name},
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => floor($self->{result_values}->{mtime_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_mtime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{mtime_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

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
         { label => 'mtime-last', nlabel => 'file.mtime.last', set => {
                key_values  => [ { name => 'mtime_seconds' }, { name => 'mtime_human' }, { name => 'name' } ],
                output_template => 'last modified %s',
                output_use => 'mtime_human',
                closure_custom_perfdata => $self->can('custom_mtime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_mtime_threshold')
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
        'timezone:s'    => { name => 'timezone' },
        'unit:s'        => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        centreon::plugins::misc::mymodule_load(
            module => 'DateTime',
            error_msg => "Cannot load module 'DateTime'."
        );
    }

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }

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

sub manage_selection {
    my ($self, %options) = @_;

    my $ctime = time();

    $self->{files} = {};
    foreach my $dir (@{$self->{option_results}->{directory}}) {
        my ($rv, $message, $files) = $options{custom}->list_directory(directory => $dir);
        if ($rv != 0) {
            $self->{output}->add_option_msg(short_msg => "cannot read directory '" . $dir . "': " . $message);
            $self->{output}->option_exit();
        }

        foreach my $file (@$files) {
            next if ($file->[0] != SMBC_FILE && $file->[0] != SMBC_DIR); 
            next if ($file->[1] eq '.' || $file->[1] eq '..');

            my $name = $dir . '/' . $file->[1];

            next if (defined($self->{option_results}->{filter_file}) && $self->{option_results}->{filter_file} ne '' &&
                $name !~ /$self->{option_results}->{filter_file}/);

            $rv = $options{custom}->stat_file(file => $name);
            if ($rv->{code} != 0) {
                $self->{output}->add_option_msg(short_msg => "cannot stat file '" . $name . "': " . $rv->{message});
                $self->{output}->option_exit();
            }

            $self->{files}->{$name} = {
                name => $name,
                mtime_seconds => $ctime - $rv->{mtime},
                mtime_human => centreon::plugins::misc::change_seconds(
                    value => $ctime - $rv->{mtime}
                )
            };
        }
    }

    foreach my $file (@{$self->{option_results}->{file}}) {
        my $rv = $options{custom}->stat_file(file => $file);
        if ($rv->{code} != 0) {
            $self->{output}->add_option_msg(short_msg => "cannot stat file '" . $file . "': " . $rv->{message});
            $self->{output}->option_exit();
        }

        $self->{files}->{$file} = {
            name => $file,
            mtime_seconds => $ctime - $rv->{mtime},
            mtime_human => centreon::plugins::misc::change_seconds(
                value => $ctime - $rv->{mtime}
            )
        };
    }
}

1;

__END__

=head1 MODE

Check modified time of files.

=over 8

=item B<--directory>

Check files in the directory (no recursive) (multiple option)

=item B<--file>

Check file (multiple option)

=item B<--filter-file>

Filter files (can be a regexp. Directory in the name).

=item B<--timezone>

Set the timezone of display date.
Can use format: 'Europe/London' or '+0100'.

=item B<--unit>

Select the time unit for the modified time thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'mtime-last'.

=back

=cut
