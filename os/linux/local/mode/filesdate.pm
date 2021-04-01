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

package os::linux::local::mode::filesdate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning:s'       => { name => 'warning' },
        'critical:s'      => { name => 'critical' },
        'separate-dirs'   => { name => 'separate_dirs' },
        'max-depth:s'     => { name => 'max_depth' },
        'exclude-du:s@'   => { name => 'exclude_du' },
        'filter-plugin:s' => { name => 'filter_plugin' },
        'files:s'         => { name => 'files' },
        'time:s'          => { name => 'time' }
    });

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
    if (!defined($self->{option_results}->{files}) || $self->{option_results}->{files} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify files option.");
       $self->{output}->option_exit();
    }

    #### Create command_options
    $self->{command_options} = '-x --time-style=+%s';
    if (defined($self->{option_results}->{separate_dirs})) {
        $self->{command_options} .= ' --separate-dirs';
    }
    if (defined($self->{option_results}->{max_depth})) {
        $self->{command_options} .= ' --max-depth=' . $self->{option_results}->{max_depth};
    }
    if (defined($self->{option_results}->{time})) {
        $self->{command_options} .= ' --time=' . $self->{option_results}->{time};
    } else {
        $self->{command_options} .= ' --time';
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
    my $current_time = time();

    my ($stdout) = $options{custom}->execute_command(
        command => 'du',
        command_options => $self->{command_options}
    );

    $self->{output}->output_add(
        severity => 'OK', 
        short_msg => 'All file/directory times are ok.'
    );
    foreach (split(/\n/, $stdout)) {
        next if (!/(\d+)\t+(\d+)\t+(.*)/);
        my ($size, $time, $name) = ($1, $2, centreon::plugins::misc::trim($3));
        my $diff_time = $current_time - $time;
        
        next if (defined($self->{option_results}->{filter_plugin}) && $self->{option_results}->{filter_plugin} ne '' &&
                 $name !~ /$self->{option_results}->{filter_plugin}/);
        
        my $exit_code = $self->{perfdata}->threshold_check(
            value => $diff_time, 
            threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
        );
        $self->{output}->output_add(long_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, scalar(localtime($time))));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(
                severity => $exit_code,
                short_msg => sprintf('%s: %s seconds (time: %s)', $name, $diff_time, scalar(localtime($time)))
            );
        }
        $self->{output}->perfdata_add(
            label => $name, unit => 's',
            value => $diff_time,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
        );
    }
      
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check time (modified, creation,...) of files/directories.

=over 8

=item B<--files>

Files/Directories to check. (Shell expansion is ok)

=item B<--warning>

Threshold warning in seconds for each files/directories (diff time).

=item B<--critical>

Threshold critical in seconds for each files/directories (diff time).

=item B<--separate-dirs>

Do not include size of subdirectories.

=item B<--max-depth>

Don't check fewer levels. (can be use --separate-dirs)

=item B<--time>

Check another time than modified time.

=item B<--exclude-du>

Exclude files/directories with 'du' command. Values from exclude files/directories are not counted in parent directories.
Shell pattern can be used.

=item B<--filter-plugin>

Filter files/directories in the plugin. Values from exclude files/directories are counted in parent directories!!!
Perl Regexp can be used.

=back

=cut
