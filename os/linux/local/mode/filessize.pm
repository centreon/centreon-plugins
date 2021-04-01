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

package os::linux::local::mode::filessize;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-one:s'    => { name => 'warning_one' },
        'critical-one:s'   => { name => 'critical_one' },
        'warning-total:s'  => { name => 'warning_total' },
        'critical-total:s' => { name => 'critical_total' },
        'separate-dirs'    => { name => 'separate_dirs' },
        'max-depth:s'      => { name => 'max_depth' },
        'all-files'        => { name => 'all_files' },
        'exclude-du:s@'    => { name => 'exclude_du' },
        'filter-plugin:s'  => { name => 'filter_plugin' },
        'files:s'          => { name => 'files' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_one', value => $self->{option_results}->{warning_one})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-one threshold '" . $self->{warning_one} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_one', value => $self->{option_results}->{critical_one})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-one threshold '" . $self->{critical_one} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_total', value => $self->{option_results}->{warning_total})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-total threshold '" . $self->{warning_total} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_total', value => $self->{option_results}->{critical_total})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-total threshold '" . $self->{critical_total} . "'.");
       $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{files}) || $self->{option_results}->{files} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify files option.");
       $self->{output}->option_exit();
    }

    $self->{command_options} = '-x -b';
    if (defined($self->{option_results}->{separate_dirs})) {
        $self->{command_options} .= ' --separate-dirs';
    }
    if (defined($self->{option_results}->{max_depth})) {
        $self->{command_options} .= ' --max-depth=' . $self->{option_results}->{max_depth};
    }
    if (defined($self->{option_results}->{all_files})) {
        $self->{command_options} .= ' --all';
    }
    foreach my $exclude (@{$self->{option_results}->{exclude_du}}) {
        $self->{command_options} .= " --exclude='" . $exclude . "'";
    }
    $self->{command_options} .= ' ' . $self->{option_results}->{files};
    $self->{command_options} .= ' 2>&1';
}

sub run {
    my ($self, %options) = @_;
    my $total_size = 0;

    my ($stdout) = $options{custom}->execute_command(
        command => 'du',
        command_options => $self->{command_options}
    );
    
    $self->{output}->output_add(
        severity => 'OK', 
        short_msg => "All file/directory sizes are ok."
    );
    foreach (split(/\n/, $stdout)) {
        next if (!/(\d+)\t+(.*)/);
        my ($size, $name) = ($1, centreon::plugins::misc::trim($2));
        
        next if (defined($self->{option_results}->{filter_plugin}) && $self->{option_results}->{filter_plugin} ne '' &&
                 $name !~ /$self->{option_results}->{filter_plugin}/);
        
        $total_size += $size;
        my $exit_code = $self->{perfdata}->threshold_check(
            value => $size, 
            threshold => [ { label => 'critical_one', exit_litteral => 'critical' }, { label => 'warning_one', exit_litteral => 'warning' } ]
        );
        my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
        $self->{output}->output_add(long_msg => sprintf("%s: %s", $name, $size_value . ' ' . $size_unit));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(
                severity => $exit_code,
                short_msg => sprintf("'%s' size is %s", $name, $size_value . ' ' . $size_unit)
            );
        }
        $self->{output}->perfdata_add(
            label => $name, unit => 'B',
            value => $size,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_one'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_one'),
            min => 0
        );
    }
 
    # Total Size
    my $exit_code = $self->{perfdata}->threshold_check(
        value => $total_size, 
        threshold => [ { label => 'critical_total', exit_litteral => 'critical' }, { label => 'warning_total', exit_litteral => 'warning' } ]
    );
    my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    $self->{output}->output_add(long_msg => sprintf("Total: %s", $size_value . ' ' . $size_unit));
    if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf('Total size is %s', $size_value . ' ' . $size_unit)
        );
    }
    $self->{output}->perfdata_add(
        label => 'total', unit => 'B',
        value => $total_size,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_total'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_total'),
        min => 0
    );
      
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check size of files/directories.

=over 8

=item B<--files>

Files/Directories to check. (Shell expansion is ok)

=item B<--warning-one>

Threshold warning in bytes for each files/directories.

=item B<--critical-one>

Threshold critical in bytes for each files/directories.

=item B<--warning-total>

Threshold warning in bytes for all files/directories.

=item B<--critical-total>

Threshold critical in bytes for all files/directories.

=item B<--separate-dirs>

Do not include size of subdirectories.

=item B<--max-depth>

Don't check fewer levels. (can be use --separate-dirs)

=item B<--all-files>

Add files when you check directories.

=item B<--exclude-du>

Exclude files/directories with 'du' command. Values from exclude files/directories are not counted in parent directories.
Shell pattern can be used.

=item B<--filter-plugin>

Filter files/directories in the plugin. Values from exclude files/directories are counted in parent directories!!!
Perl Regexp can be used.

=back

=cut
