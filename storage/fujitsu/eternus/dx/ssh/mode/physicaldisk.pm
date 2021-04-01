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

package storage::fujitsu::eternus::dx::ssh::mode::physicaldisk;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    disk => [
        ['Available', 'OK'],
        ['Spare', 'OK'],
        ['Readying', 'OK'],
        ['Redundant Copy', 'OK'],
        ['Rebuild/Copyback', 'WARNING'],
        ['Available (Predictive Failure)', 'WARNING'],
        ['Present', 'OK'],
        ['Failed Usable', 'WARNING'],
        ['Formatting', 'WARNING'],
        ['Not Format', 'WARNING'],
        ['Not Supported', 'CRITICAL'],
        ['Not Available', 'CRITICAL'],
        ['Broken', 'CRITICAL'],
        ['Not Exist', 'CRITICAL'],
        ['Unknown', 'UNKNOWN'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"              => { name => 'hostname' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "command:s"               => { name => 'command', default => 'show' },
                                  "command-path:s"          => { name => 'command_path' },
                                  "command-options:s"       => { name => 'command_options', default => 'disks' },
                                  "filter:s@"               => { name => 'filter' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                  "no-component:s"          => { name => 'no_component' },
                                });
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
    
    $self->{filter} = [];
    foreach my $val (@{$self->{option_results}->{filter}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        push @{$self->{filter}}, { filter => $values[0], instance => $values[1] }; 
    }

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  ssh_pipe => 1,
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});

    #Location      Status                        Size    Type                Speed(rpm) Usage               Health(%)
    #------------- ----------------------------- ------- ------------------- ---------- ------------------- ---------
    #CE-Disk#0     Available                         4TB 3.5 SSD-H                 7200 System                    100
    #CE-Disk#1     Available                         4TB 3.5 SSD-M                 7200 System                      0
    #CE-Disk#2     Available                         4TB 3.5 SSD-L                 7200 System                      0
    #CE-Disk#3     Available                         4TB 3.5 Nearline SED          7200 System                      0
    
    my $total_components = 0;
    while ($stdout =~ /^(\S+)\s+(\S+)/msg) {
        my ($disk_name, $disk_status) = ($1, $2);
        next if ($disk_name =~ /Location|---/);
        next if ($disk_name !~ /Disk/i);

        next if ($self->check_filter(section => 'disk', instance => $disk_name));

        $total_components++;
        $self->{output}->output_add(long_msg => sprintf("Physical Disk '%s' status is '%s'", $disk_name, $disk_status));
        my $exit = $self->get_severity(section => 'disk', value => $disk_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Physical Disk '%s' status is '%s'.", $disk_name, $disk_status));
        }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %d physical disks are ok.", $total_components));
     
    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

sub check_filter {
    my ($self, %options) = @_;

    foreach (@{$self->{filter}}) {
        if ($options{section} =~ /$_->{filter}/) {
            if (!defined($options{instance}) && !defined($_->{instance})) {
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
                return 1;
            } elsif (defined($options{instance}) && $options{instance} =~ /$_->{instance}/) {
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
                return 1;
            }
        }
    }
    
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check Physical disks.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to get information (Default: 'show').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: 'disks').

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=disk,CE-Disk#0

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='disk,CRITICAL,^(?!(Available|Spare)$)'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut
