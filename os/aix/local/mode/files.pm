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

package os::aix::local::mode::files;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Time::Local 'timelocal';

my $instance_mode;

sub custom_attributes_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_attributes_output {
    my ($self, %options) = @_;
    my $msg;

    $msg = 'Attributes : [owner: ' . $self->{result_values}->{owner} . " uid: " . $self->{result_values}->{uid} . "] [group: " . $self->{result_values}->{group} . " gid: " . $self->{result_values}->{gid} . "]\n" ;

    return $msg;
}

sub custom_attributes_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{owner} = $options{new_datas}->{$self->{instance} . '_owner'};
    $self->{result_values}->{uid} = $options{new_datas}->{$self->{instance} . '_uid'};
    $self->{result_values}->{group} = $options{new_datas}->{$self->{instance} . '_group'};
    $self->{result_values}->{gid} = $options{new_datas}->{$self->{instance} . '_gid'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'count', type => 0 },
        { name => 'files', type => 1, cb_prefix_output => 'prefix_file_output', message_multiple => 'All file(s) stats are ok' },
    ];
    $self->{maps_counters}->{count} = [
        { label => 'count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total count : %s',
                perfdatas => [
                    { label => 'total_absolute', value => 'total_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{files} = [
        { label => 'size', set => {
                key_values => [ { name => 'size' }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'File size is : %s%s',
                perfdatas => [
                    { label => 'size', value => 'size_absolute', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'mtime', set => {
                key_values => [ { name => 'mtime' } ],
                output_template => 'mtime is : %s sec ago',
                closure_custom_perfdata => sub { return 0; },
            }
        },
        { label => 'atime', set => {
                key_values => [ { name => 'atime' } ],
                output_template => 'accessed time : %s sec ago',
                closure_custom_perfdata => sub { return 0; },
            }
        },
        { label => 'utime', set => {
                key_values => [ { name => 'utime' } ],
                output_template => 'updated time : %s sec ago',
                closure_custom_perfdata => sub { return 0; },
            }
        },
        { label => 'attributes', threshold => 0, set => {
                key_values => [ { name => 'owner' }, { name => 'uid' }, { name => 'group' }, { name => 'gid' } ],
                closure_custom_calc => $self->can('custom_attributes_calc'),
                closure_custom_output => $self->can('custom_attributes_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_attributes_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning-attributes:s"  => { name => 'warning_attributes', default => '' },
                                  "critical-attributes:s" => { name => 'critical_attributes', default => '' },
                                  "remote"                => { name => 'remote' },
                                  "ssh-option:s@"         => { name => 'ssh_option' },
                                  "ssh-path:s"            => { name => 'ssh_path' },
                                  "ssh-command:s"         => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"             => { name => 'timeout', default => 30 },
                                  "sudo"                  => { name => 'sudo' },
								  "directory:s"			  => { name => 'directory' },
                                  "files:s"               => { name => 'files' },
                                  "type:s"                => { name => 'type' },
                                  "zero-depth"            => { name => 'zerodepth' },
								  "skip-dir"			  => { name => 'skipdir' },		  
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();

	if (!defined($self->{option_results}->{directory}) || $self->{option_results}->{directory} eq '') {
		$self->{output}->add_option_msg(short_msg => "Please set at least --directory option");
		$self->{output}->option_exit();	
	}
	
}

sub prefix_file_output {
    my ($self, %options) = @_;

    return "File '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_attributes', 'critical_attributes')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_month = (
    'Jan' => '0',
    'Feb' => '1',
    'Mar' => '2',
    'Apr' => '3',
    'May' => '4',
    'Jun' => '5',
    'Jul' => '6',
    'Aug' => '7',
    'Sep' => '8',
    'Oct' => '9',
    'Nov' => '10',
    'Dec' => '11',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $cmd_opts;
    my $cmd = "find";

	if (defined($self->{option_results}->{zerodepth})) {
		$cmd = "ls";
		$cmd_opts = defined($self->{option_results}->{files}) ? " -Ap " . $self->{option_results}->{directory} . $self->{option_results}->{files} : " -Ap " . $self->{option_results}->{directory};
		$cmd_opts .= " | grep -v /" if (defined($self->{option_results}->{skipdir}));
	} else {
		$cmd_opts = defined($self->{option_results}->{files}) ? $self->{option_results}->{directory} . "-name " . $self->{option_results}->{files} : $self->{option_results}->{directory};
		$cmd_opts .= ' -type ' . $self->{option_results}->{type} if defined($self->{option_results}->{type});
	}

    my ($stdout, $ret) = centreon::plugins::misc::execute(command => $cmd,
                                                  options => $self->{option_results},
                                                  command_path => '/usr/bin/',
                                                  command_options => $cmd_opts,
												  no_quit => 1);
												  
	if ($ret != 0) {									  
		$self->{output}->output_add(severity => 'UNKNOWN',
									short_msg => "Please check --directory and --files options values, command doesn't return anything !");
		$self->{output}->display();
		$self->{output}->exit();
	}
	
    my @targets = split /\n/, $stdout;
    foreach my $target (@targets) {
		$target = $self->{option_results}->{directory}.$target if ($cmd eq 'ls');
        $self->{count}->{total}++;
        my $istat = centreon::plugins::misc::execute(command => "istat ",
                                                     options => $self->{option_results},
                                                     command_path => '/usr/bin/',
                                                     command_options => $target);

        $istat =~ tr{\n}{ };
        $istat =~ /.*Owner: ([0-9]+)\(([a-z0-9-]+)\)\s+Group:\s([0-9]+)\(([a-z0-9-]+)\).*Length\s([0-9]+)\sbytes\s+Last updated:\s+(.*)\sLast modified:\s+(.*)\sLast accessed:\s+(.*)$/;
        my ($ownerId, $ownerName, $groupId, $groupName, $size_b, $updated_str, $modified_str, $accessed_str) = ($1, $2, $3, $4, $5, $6, $7, $8);

        $self->{files}->{$target}->{size} =  $size_b;
        $self->{files}->{$target}->{owner} = $ownerName;
        $self->{files}->{$target}->{uid} = $ownerId;
        $self->{files}->{$target}->{group} = $groupName;
        $self->{files}->{$target}->{gid} = $groupId;
        $self->{files}->{$target}->{display} = $target;

        my $now = time();
        my ($mday, $mon, $hour, $min, $sec, $year) = (0, 0, 0, 0, 0, 0);
        my ($mtime, $atime, $utime);

        $modified_str =~ /.*\s(.*)\s\s([0-9]+)\s([0-9]+):([0-9]+):([0-9]+)\s.*\s([0-9]+)/;
        ($mon, $mday, $hour, $min, $sec, $year) = ($map_month{$1}, $2, $3, $4, $5, $6);
        $mtime = timelocal($sec,$min,$hour,$mday,$mon,$year);
        $self->{files}->{$target}->{mtime} = $now - $mtime;

        $updated_str =~  /.*\s(.*)\s\s([0-9]+)\s([0-9]+):([0-9]+):([0-9]+)\s.*\s([0-9]+)/;
        ($mon, $mday, $hour, $min, $sec, $year) = ($map_month{$1}, $2, $3, $4, $5, $6);
        $utime = timelocal($sec,$min,$hour,$mday,$mon,$year);
        $self->{files}->{$target}->{utime} = $now - $utime;

        $accessed_str =~ /.*\s(.*)\s\s([0-9]+)\s([0-9]+):([0-9]+):([0-9]+)\s.*\s([0-9]+)/;
        ($mon, $mday, $hour, $min, $sec, $year) = ($map_month{$1}, $2, $3, $4, $5, $6);
        $atime = timelocal($sec,$min,$hour,$mday,$mon,$year);
        $self->{files}->{$target}->{atime} = $now - $atime;
    }
}

1;

__END__

=head1 MODE

Count Files on AIX and check various properties (mods, size, atime/utime/mtime)

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='count'

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--type>

Specifiy to find what you are looking for ('d' for directories and 'f' for files)

=item B<--zero-depth>

Do not search recursively for files (will use 'ls' instead of 'find' command ) 

=item B<--skip-subdir>

Do not list subdir in output when option --zero-depth is used (no effect otherwise, can't manage this with find command on AIX)

=item B<--warning-attributes>

Set warning threshold for attributes.
Can used special variables like: %{owner}, %{uid}, %{group}, %{gid}, %{display}

=item B<--critical-attributes>

Set critical threshold for attributes.
Can used special variables like: %{owner}, %{uid}, %{group}, %{gid}, %{display}

=back

=cut