#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package os::linux::local::mode::paging;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::values;

my $maps_counters = {
    pgpgin =>  { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'pgpgin', diff => 1 },
                                      ],
                        output_template => 'pgpgin : %s %s/s', per_second => 1, output_change_bytes => 1,
                        perfdatas => [
                            { value => 'pgpgin_per_second', label => 'pgpgin', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
    pgpgout =>  { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'pgpgout', diff => 1 },
                                      ],
                        output_template => 'pgpgout : %s %s/s', per_second => 1, output_change_bytes => 1,
                        perfdatas => [
                            { value => 'pgpgout_per_second', label => 'pgpgout', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
    pswpin =>  { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'pswpin', diff => 1 },
                                      ],
                        output_template => 'pswpin : %s %s/s', per_second => 1, output_change_bytes => 1,
                        perfdatas => [
                            { value => 'pswpin_per_second', label => 'pswpin', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
    pswpout =>  { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'pswpout', diff => 1 },
                                      ],
                        output_template => 'pswpout : %s %s/s', per_second => 1, output_change_bytes => 1,
                        perfdatas => [
                            { value => 'pswpout_per_second', label => 'pswpout', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
    pgfault =>  { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'pgfault', diff => 1 },
                                      ],
                        output_template => 'pgfault : %s %s/s', per_second => 1, output_change_bytes => 1,
                        perfdatas => [
                            { value => 'pgfault_per_second', label => 'pgfault', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
    pgmajfault =>  { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'pgmajfault', diff => 1 },
                                      ],
                        output_template => 'pgmajfault : %s %s/s', per_second => 1, output_change_bytes => 1,
                        perfdatas => [
                            { value => 'pgmajfault_per_second', label => 'pgmajfault', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "hostname:s"        => { name => 'hostname' },
                                "remote"            => { name => 'remote' },
                                "ssh-option:s@"     => { name => 'ssh_option' },
                                "ssh-path:s"        => { name => 'ssh_path' },
                                "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                "timeout:s"         => { name => 'timeout', default => 30 },
                                "sudo"              => { name => 'sudo' },
                                "command:s"         => { name => 'command', default => 'cat' },
                                "command-path:s"    => { name => 'command_path' },
                                "command-options:s" => { name => 'command_options', default => '/proc/vmstat 2>&1' },
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);                           
     
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }

    $self->{statefile_value}->check_options(%options);
    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->{stdout} = centreon::plugins::misc::execute(output => $self->{output},
                                                       options => $self->{option_results},
                                                       sudo => $self->{option_results}->{sudo},
                                                       command => $self->{option_results}->{command},
                                                       command_path => $self->{option_results}->{command_path},
                                                       command_options => $self->{option_results}->{command_options});
    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile =>  "cache_linux_local_" . $self->{hostname}  . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'paging');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{paging},
                                                                 new_datas => $self->{new_datas});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $maps_counters->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Paging $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Paging $long_msg");
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
        
    $self->{paging} = {};
    $self->{paging}->{pgpgin} = $self->{stdout} =~ /^pgpgin.*?(\d+)/msi ? $1 * 1024 : undef;
    $self->{paging}->{pgpgout} = $self->{stdout} =~ /^pgpgout.*?(\d+)/msi ? $1 * 1024 : undef;
    $self->{paging}->{pswpin} = $self->{stdout} =~ /^pswpin.*?(\d+)/msi ? $1 * 1024 : undef;
    $self->{paging}->{pswpout} = $self->{stdout} =~ /^pswpout.*?(\d+)/msi ? $1 * 1024: undef;
    $self->{paging}->{pgfault} = $self->{stdout} =~ /^pgfault.*?(\d+)/msi ? $1 * 1024: undef;
    $self->{paging}->{pgmajfault} = $self->{stdout} =~ /^pgmajfault.*?(\d+)/msi ? $1 * 1014: undef;
}

1;

__END__

=head1 MODE

Check paging informations.

=over 8

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

=item B<--command>

Command to get information (Default: 'cat').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '/proc/vmstat 2>&1').

=item B<--warning-*>

Threshold warning.
Can be: 'pgpgin', 'pgpgout', 'pswpin', 'pswpout', 'pgfault', 'pgmajfault'.

=item B<--critical-*>

Threshold critical.
Can be: 'pgpgin', 'pgpgout', 'pswpin', 'pswpout', 'pgfault', 'pgmajfault'.

=back

=cut
