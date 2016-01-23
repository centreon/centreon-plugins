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

package storage::emc::celerra::local::mode::getreason;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my $thresholds = {
    controlstation => [
        ['Primary Control Station', 'OK'], # 10
        ['Secondary Control Station', 'OK'], # 11
        ['Control Station is ready, but is not running NAS service', 'CRITICAL'], # 6
    ],
    datamover => [
        ['Reset (or unknown state)', 'WARNING'],
        ['DOS boot phase, BIOS check, boot sequence', 'WARNING'],
        ['SIB POST failures (that is, hardware failures)', 'CRITICAL'],
        ['DART is loaded on Data Mover, DOS boot and execution of boot.bat, boot.cfg', 'WARNING'],
        ['DART is ready on Data Mover, running, and MAC threads started', 'WARNING'],
        ['DART is in contact with Control Station box monitor', 'OK'],
        ['DART is in panic state', 'CRITICAL'],
        ['DART reboot is pending or in halted state', 'WARNING'],
        ['DART panicked and completed memory dump', 'CRITICAL'],
        ['DM Misc problems', 'CRITICAL'], # code 14
        ['Data Mover is flashing firmware. DART is flashing BIOS and/or POST firmware. Data Mover cannot be reset', 'CRITICAL'],
        ['Data Mover Hardware fault detected', 'CRITICAL'],
        ['DM Memory Test Failure. BIOS detected memory error', 'CRITICAL'],
        ['DM POST Test Failure. General POST error', 'CRITICAL'],
        ['DM POST NVRAM test failure. Invalid NVRAM content error', 'CRITICAL'],
        ['DM POST invalid peer Data Mover type', 'CRITICAL'],
        ['DM POST invalid Data Mover part number', 'CRITICAL'],
        ['DM POST Fibre Channel test failure. Error in blade Fibre connection', 'CRITICAL'],
        ['DM POST network test failure. Error in Ethernet controller', 'CRITICAL'],
        ['DM T2NET Error. Unable to get blade reason code due to management switch problems', 'CRITICAL'],
    ],
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
                                  "command:s"         => { name => 'command', default => 'getreason' },
                                  "command-path:s"    => { name => 'command_path', default => '/nas/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '2>&1' },
                                  "exclude:s"               => { name => 'exclude' },
                                  "component:s"             => { name => 'component', default => '.*' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
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
}

sub run {
    my ($self, %options) = @_;

    ($self->{stdout}) = centreon::plugins::misc::execute(output => $self->{output},
                                                         options => $self->{option_results},
                                                         sudo => $self->{option_results}->{sudo},
                                                         command => $self->{option_results}->{command},
                                                         command_path => $self->{option_results}->{command_path},
                                                         command_options => $self->{option_results}->{command_options},
                                                         no_quit => 1);
    my @components = ('controlstation', 'datamover');
    my $components = 0;
    foreach (@components) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = "storage::emc::celerra::local::mode::components::$_";
            centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod_name,
                                                   error_msg => "Cannot load module '$mod_name'.");
            $components = 1;
        }
    }
    
    if ($components == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    
    foreach (@components) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = "storage::emc::celerra::local::mode::components::$_";
            my $func = $mod_name->can('check');
            $func->($self); 
        }
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        my $count_by_components = $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip}; 
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $count_by_components . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components are ok [%s].", 
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
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

Check control stations and data movers status (use 'getreason' command).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'controlstation', 'datamover'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=datamover)
Can also exclude specific instance: --exclude='datamover#slot_2#'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='datamover,CRITICAL,^(?!(normal)$)'

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'getreason').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/nas/sbin').

=item B<--command-options>

Command options (Default: '2>&1').

=back

=cut
    
