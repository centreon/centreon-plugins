###############################################################################
# Copyright 2005-2013 MERETHIS
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Florian Asche <info@florian-asche.de>
#
####################################################################################

package apps::varnish::mode::hcb;

use base qw(centreon::plugins::mode);
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    hcb_nolock   => { thresholds => {
                                warning_nolock  =>  { label => 'warning-nolock', exit_value => 'warning' },
                                critical_nolock =>  { label => 'critical-nolock', exit_value => 'critical' },
                              },
                output_msg => 'HCB Lookups without lock: %.2f',
                factor => 1, unit => '',
               },
    hcb_lock => { thresholds => {
                                warning_lock  =>  { label => 'warning-lock', exit_value => 'warning' },
                                critical_lock =>  { label => 'critical-lock', exit_value => 'critical' },
                                },
                 output_msg => 'HCB Lookups with lock: %.2f',
                 factor => 1, unit => '',
                },
    hcb_insert => { thresholds => {
                                warning_insert    =>  { label => 'warning-insert', exit_value => 'warning' },
                                critical_insert   =>  { label => 'critical-insert', exit_value => 'critical' },
                                },
                 output_msg => 'HCB Inserts: %.2f',
                 factor => 1, unit => '',
               },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
    {
        "hostname:s"         => { name => 'hostname' },
        "remote"             => { name => 'remote' },
        "ssh-option:s@"      => { name => 'ssh_option' },
        "ssh-path:s"         => { name => 'ssh_path' },
        "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"          => { name => 'timeout', default => 30 },
        "sudo"               => { name => 'sudo' },
        "command:s"          => { name => 'command', default => 'varnishstat' },
        "command-path:s"     => { name => 'command_path', default => '/usr/bin' },
        "command-options:s"  => { name => 'command_options', default => ' -1 ' },
        "command-options2:s" => { name => 'command_options2', default => ' 2>&1' },
    });

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $options{options}->add_options(arguments => {
                $maps_counters->{$_}->{thresholds}->{$name}->{label} . ':s'    => { name => $name },
            });
        };
    };

    $self->{instances_done} = {};
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
};

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            };
        };
    };
    $self->{statefile_value}->check_options(%options);
};

sub getdata {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options} . $self->{option_results}->{command_options2});
    #print $stdout;

    foreach (split(/\n/, $stdout)) {
        #client_conn            7390867         1.00 Client connections
        # - Symbolic entry name
        # - Value
        # - Per-second average over process lifetime, or a period if the value can not be averaged
        # - Descriptive text

        if  (/^(.\S*)\s*([0-9]*)\s*([0-9.]*)\s(.*)$/i) {
            #print "FOUND: " . $1 . "=" . $2 . "\n";
            $self->{result}->{$1} = $2;
        };
    };
};

sub run {
    my ($self, %options) = @_;

    $self->getdata();

    $self->{statefile_value}->read(statefile => 'cache_apps_varnish' . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $self->{result}->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    # Calculate
    my $delta_time = $self->{result}->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0); # One seconds ;)

    
    foreach (keys %{$maps_counters}) {
        #print $_ . "\n";
        $self->{old_cache}->{$_} = $self->{statefile_value}->get(name => '$_');     # Get Data from Cache
        $self->{old_cache}->{$_} = 0 if ( $self->{old_cache}->{$_} > $self->{result}->{$_} );
        $self->{outputdata}->{$_} = ($self->{result}->{$_} - $self->{old_cache}->{$_}) / $delta_time;
    };

    # Write Cache if not there
    $self->{statefile_value}->write(data => $self->{result}); 
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    my @exits;
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            push @exits, $self->{perfdata}->threshold_check(value => $self->{outputdata}->{$_}, threshold => [ { label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$_}->{thresholds}->{$name}->{exit_value} }]);
        }
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    

    my $extra_label = '';
    $extra_label = '_' . $instance_output if ($num > 1);

    my $str_output = "";
    my $str_append = '';
    foreach (keys %{$maps_counters}) {
        $str_output .= $str_append . sprintf($maps_counters->{$_}->{output_msg}, $self->{outputdata}->{$_} * $maps_counters->{$_}->{factor});
        $str_append = ', ';
        my ($warning, $critical);
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $warning = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'warning');
            $critical = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'critical');
        }
        $self->{output}->perfdata_add(label => $_ . $extra_label, unit => $maps_counters->{$_}->{unit},
                                        value => sprintf("%.2f", $self->{outputdata}->{$_} * $maps_counters->{$_}->{factor}),
                                        warning => $warning,
                                        critical => $critical);
    }
    $self->{output}->output_add(severity => $exit,
                                short_msg => $str_output);

    $self->{output}->display();
    $self->{output}->exit();
};


1;

__END__

=head1 MODE

Check Varnish Cache with varnishstat Command

=over 8

=item B<--remote>

If you dont run this script locally, if you wanna use it remote, you can run it remotely with 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--command>

Varnishstat Binary Filename (Default: varnishstat)

=item B<--command-path>

Directory Path to Varnishstat Binary File (Default: /usr/bin)

=item B<--command-options>

Parameter for Binary File (Default: ' -1 ')

=item B<--warning-*>

Warning Threshold for: 
nolock => HCB Lookups without lock,
lock   => HCB Lookups with lock,
insert => HCB Inserts

=item B<--critical-*>

Critical Threshold for: 
nolock => HCB Lookups without lock,
lock   => HCB Lookups with lock,
insert => HCB Inserts

=back

=cut