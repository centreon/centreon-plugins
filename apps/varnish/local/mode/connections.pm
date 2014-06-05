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

package apps::varnish::mode::connections;

use base qw(centreon::plugins::mode);
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
            "hostname:s"         => { name => 'hostname' },
            "remote"             => { name => 'remote' },
            "ssh-option:s@"      => { name => 'ssh_option' },
            "ssh-path:s"         => { name => 'ssh_path' },
            "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
            "timeout:s"          => { name => 'timeout', default => 30 },
            "sudo"               => { name => 'sudo' },
            "command:s"          => { name => 'command', default => 'varnishstat' },
            "command-path:s"     => { name => 'command_path', default => '/usr/bin/' },
            "command-options:s"  => { name => 'command_options', default => ' -1 ' },
            "command-options2:s" => { name => 'command_options2', default => ' 2>&1' },
            "warning-hit:s"      => { name => 'warning_hit', default => '' },
            "critical-hit:s"     => { name => 'critical_hit', default => '' },
            "warning-hitpass:s"  => { name => 'warning_hitpass', default => '' },
            "critical-hitpass:s" => { name => 'critical_hitpass', default => '' },
            "warning-miss:s"     => { name => 'warning_miss', default => '' },
            "critical-miss:s"    => { name => 'critical_miss', default => '' },
        });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-conn', value => $self->{option_results}->{warning_conn})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-conn threshold '" . $self->{option_results}->{warning_conn} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-conn', value => $self->{option_results}->{critical_conn})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-conn threshold '" . $self->{option_results}->{critical_conn} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-drop', value => $self->{option_results}->{warning_drop})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-drop threshold '" . $self->{option_results}->{warning_drop} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-drop', value => $self->{option_results}->{critical_drop})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-drop threshold '" . $self->{option_results}->{critical_drop} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-req', value => $self->{option_results}->{warning_req})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-req threshold '" . $self->{option_results}->{warning_req} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-req', value => $self->{option_results}->{critical_req})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-req threshold '" . $self->{option_results}->{critical_req} . "'.");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
}

#my $stdout = '
#client_conn            7287199         1.00 Client connections accepted
#client_drop                  0         0.00 Connection dropped, no sess/wrk
#client_req               24187         0.00 Client requests received
#';

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
    my $old_client_conn = $self->{statefile_value}->get(name => 'client_conn');
    my $old_client_drop = $self->{statefile_value}->get(name => 'client_drop');
    my $old_client_req    = $self->{statefile_value}->get(name => 'client_req');

    $self->{statefile_value}->write(data => $self->{result}); 
    if (!defined($old_timestamp) || !defined($old_client_conn)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Set 0 if Cache > Result
    $old_client_conn = 0 if ($old_client_conn > $self->{result}->{client_conn} ); 
    $old_client_drop = 0 if ($old_hitpass > $self->{result}->{client_drop});
    $old_client_req = 0 if ($old_miss > $self->{result}->{client_req});

    # Calculate
    my $delta_time = $self->{result}->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0); # One seconds ;)
    my $client_conn = ($self->{result}->{client_conn} - $old_client_conn) / $delta_time;
    my $client_drop = ($self->{result}->{client_drop} - $old_client_drop) / $delta_time;
    my $client_req = ($self->{result}->{client_req} - $old_client_req) / $delta_time;

    #print $old_client_conn . "\n";
    #print $self->{result}->{client_conn} . "\n";
    #print $client_conn . "\n";

    my $exit1 = $self->{perfdata}->threshold_check(value => $client_conn, threshold =>   [ { label => 'critical-conn', 'exit_litteral' => 'critical' }, { label => 'warning-conn', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $client_drop, threshold =>   [ { label => 'critical-drop', 'exit_litteral' => 'critical' }, { label => 'warning-drop', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $client_req, threshold =>    [ { label => 'critical-req', 'exit_litteral' => 'critical' }, { label => 'warning-req', exit_litteral => 'warning' } ]);
    
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Client connections accepted: %.2f Connection dropped, no sess/wrk: %.2f Client requests received: %.2f ", 
                                    $client_conn,
                                    $client_drop,
                                    $client_req,
                                    ));

    $self->{output}->perfdata_add(label => "client_conn",
                                    value => $client_conn,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-conn'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-conn'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "client_drop",
                                    value => $client_drop,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-drop'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-drop'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "client_req",
                                    value => $client_req,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-req'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-req'),
                                    min => 0
                                    );

    $self->{output}->display();
    $self->{output}->exit();
};


1;

__END__

=head1 MODE

Check Varnish Cache with varnishstat Command
This Mode Checks:
- Client connections accepted
- Connection dropped, no sess 
- Client requests received

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

Directory Path to Varnishstat Binary File (Default: /usr/bin/)

=item B<--command-options>

Parameter for Binary File (Default: ' -1 ')

=item B<--warning-conn>

Warning Threshold for Client connections accepted

=item B<--critical-conn>

Critical Threshold for Client connections accepted

=item B<--warning-drop>

Warning Threshold for Connection dropped, no sess/wrk

=item B<--critical-drop>

Critical Threshold for Connection dropped, no sess/wrk

=item B<--warning-req>

Warning Threshold for Client requests received

=item B<--critical-req>

Critical Threshold for Client requests received

=back

=cut