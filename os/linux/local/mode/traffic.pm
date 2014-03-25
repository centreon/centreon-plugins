################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package os::linux::local::mode::traffic;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

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
                                  "command:s"         => { name => 'command', default => 'ifconfig' },
                                  "command-path:s"    => { name => 'command_path', default => '/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '-a 2>&1' },
                                  "filter-state:s"    => { name => 'filter_state', default => 'RU' },
                                  "warning-in:s"      => { name => 'warning_in' },
                                  "critical-in:s"     => { name => 'critical_in' },
                                  "warning-out:s"     => { name => 'warning_out' },
                                  "critical-out:s"    => { name => 'critical_out' },
                                  "units:s"           => { name => 'units', default => 'B' },
                                  "name:s"            => { name => 'name' },
                                  "regexp"              => { name => 'use_regexp' },
                                  "regexp-isensitive"   => { name => 'use_regexpi' },
                                  "speed:s"             => { name => 'speed' },
                                  "no-loopback"         => { name => 'no_loopback', },
                                });
    $self->{result} = {};
    $self->{hostname} = undef;
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'in' threshold '" . $self->{option_results}->{warning_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'in' threshold '" . $self->{option_results}->{critical_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'out' threshold '" . $self->{option_results}->{warning_out} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'out' threshold '" . $self->{option_results}->{critical_out} . "'.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' && $self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
        $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also).");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{units}) && $self->{option_results}->{units} eq '%' && 
        (!defined($self->{option_results}->{speed}) || $self->{option_results}->{speed} eq '')) {
        $self->{output}->add_option_msg(short_msg => "To use percent, you need to set --speed option.");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_value}->check_options(%options);
    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    while ($stdout =~ /^(\S+)(.*?)(\n\n|\n$)/msg) {
        my ($interface_name, $values) = ($1, $2);
        my $states = '';
        $states .= 'R' if ($values =~ /RUNNING/ms);
        $states .= 'U' if ($values =~ /UP/ms);
        
        next if (defined($self->{option_results}->{no_loopback}) && $values =~ /LOOPBACK/ms);
        next if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
                 $states !~ /$self->{option_results}->{filter_state}/);
        
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $interface_name !~ /$self->{option_results}->{name}/i);
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $interface_name !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $interface_name ne $self->{option_results}->{name});

        $values =~ /RX bytes:(\S+).*?TX bytes:(\S+)/msi;
        $self->{result}->{$interface_name} = {state => $states, in => $1, out => $2};
    }
    
    if (scalar(keys %{$self->{result}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->add_option_msg(short_msg => "No interface found for name '" . $self->{option_results}->{name} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No interface found.");
        }
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
	
    $self->manage_selection();

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "cache_linux_local_" . $self->{hostname}  . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All traffic are ok.');
    }
    
    foreach my $name (sort(keys %{$self->{result}})) {
 
        $new_datas->{'in_' . $name} = $self->{result}->{$name}->{in} * 8;
        $new_datas->{'out_' . $name} = $self->{result}->{$name}->{out} * 8;
        
        my $old_in = $self->{statefile_value}->get(name => 'in_' . $name);
        my $old_out = $self->{statefile_value}->get(name => 'out_' . $name);
        if (!defined($old_timestamp) || !defined($old_in) || !defined($old_out)) {
            next;
        }
        if ($new_datas->{'in_' . $name} < $old_in) {
            # We set 0. Has reboot.
            $old_in = 0;
        }
        if ($new_datas->{'out_' . $name} < $old_out) {
            # We set 0. Has reboot.
            $old_out = 0;
        }

        my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }
        my $in_absolute_per_sec = ($new_datas->{'in_' . $name} - $old_in) / $time_delta;
        my $out_absolute_per_sec = ($new_datas->{'out_' . $name} - $old_out) / $time_delta;
        
        my ($exit, $interface_speed, $in_prct, $out_prct);
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed} * 1000000;
            $in_prct = $in_absolute_per_sec * 100 / ($self->{option_results}->{speed} * 1000000);
            $out_prct = $out_absolute_per_sec * 100 / ($self->{option_results}->{speed} * 1000000);
            if ($self->{option_results}->{units} eq '%') {
                my $exit1 = $self->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
                my $exit2 = $self->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
                $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            }
            $in_prct = sprintf("%.2f", $in_prct);
            $out_prct = sprintf("%.2f", $out_prct);
        } else {
            my $exit1 = $self->{perfdata}->threshold_check(value => $in_absolute_per_sec, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
            my $exit2 = $self->{perfdata}->threshold_check(value => $out_absolute_per_sec, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
            $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            $in_prct = '-';
            $out_prct = '-';
        }
       
        ###########
        # Manage Output
        ###########
        
        my ($in_value, $in_unit) = $self->{perfdata}->change_bytes(value => $in_absolute_per_sec, network => 1);
        my ($out_value, $out_unit) = $self->{perfdata}->change_bytes(value => $out_absolute_per_sec, network => 1);
        $self->{output}->output_add(long_msg => sprintf("Interface '%s' Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ", $name,
                                       $in_value . $in_unit, $in_prct,
                                       $out_value . $out_unit, $out_prct));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Interface '%s' Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ", $name,
                                            $in_value . $in_unit, $in_prct,
                                            $out_value . $out_unit, $out_prct));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'traffic_in' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $in_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $interface_speed),
                                      min => 0, max => $interface_speed);
        $self->{output}->perfdata_add(label => 'traffic_out' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $out_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $interface_speed),
                                      min => 0, max => $interface_speed);
    }
    
    $self->{statefile_value}->write(data => $new_datas);    
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Traffic

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

Command to get information (Default: 'ifconfig').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/sbin').

=item B<--command-options>

Command options (Default: '-a 2>&1').

=item B<--warning-in>

Threshold warning in percent for 'in' traffic.

=item B<--critical-in>

Threshold critical in percent for 'in' traffic.

=item B<--warning-out>

Threshold warning in percent for 'out' traffic.

=item B<--critical-out>

Threshold critical in percent for 'out' traffic.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').
Percent can be used only if --speed is set.

=item B<--name>

Set the interface name (empty means 'check all interfaces')

=item B<--regexp>

Allows to use regexp to filter intefaces (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--filter-state>

Filter interfaces type (regexp can be used. Default: 'RU').

=item B<--speed>

Set interface speed (in Mb).

=item B<--no-loopback>

Don't display loopback interfaces.

=back

=cut