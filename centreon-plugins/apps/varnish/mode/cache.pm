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

package apps::varnish::mode::cache;

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
            "warning-hit:s"      => { name => 'warning-hit', default => '' },
            "critical-hit:s"     => { name => 'critical-hit', default => '' },
            "warning-hitpass:s"  => { name => 'warning-hitpass', default => '' },
            "critical-hitpass:s" => { name => 'critical-hitpass', default => '' },
            "warning-miss:s"     => { name => 'warning-miss', default => '' },
            "critical-miss:s"    => { name => 'critical-miss', default => '' },
        });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-hit', value => $self->{option_results}->{warning-hit})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning-hit} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-hit', value => $self->{option_results}->{critical-hit})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical-hit} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-hitpass', value => $self->{option_results}->{warning_hitpass})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-bytes threshold '" . $self->{option_results}->{warning_hitpass} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-hitpass', value => $self->{option_results}->{critical_hitpass})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-bytes threshold '" . $self->{option_results}->{critical_hitpass} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-miss', value => $self->{option_results}->{warning_miss})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-access threshold '" . $self->{option_results}->{warning_miss} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-miss', value => $self->{option_results}->{critical_miss})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-access threshold '" . $self->{option_results}->{critical_miss} . "'.");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
}

#my $stdout = '
#client_conn            7287199         1.00 Client connections accepted
#client_drop                  0         0.00 Connection dropped, no sess/wrk
#client_req               24187         0.00 Client requests received
#cache_hit                17941         0.00 Cache hits
#cache_hitpass               10         0.00 Cache hits for pass
#cache_miss               16746         0.00 Cache misses
#backend_conn             13746         0.00 Backend conn. success
#backend_unhealthy            0         0.00 Backend conn. not attempted
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
            #print "FOUND: " . $2 . "\n";
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
    my $old_cache_hit = $self->{statefile_value}->get(name => 'cache_hit');
    my $old_hitpass = $self->{statefile_value}->get(name => 'cache_hitpass');
    my $old_miss    = $self->{statefile_value}->get(name => 'cache_miss');

    $self->{statefile_value}->write(data => $self->{result}); 
    if (!defined($old_timestamp) || !defined($old_cache_hit)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Set 0 if Cache > Result
    $old_cache_hit = 0 if ($old_cache_hit > $self->{result}->{cache_hit}->{value} ); 
    $old_cache_hitpass = 0 if ($old_hitpass > $self->{result}->{cache_hitpass}->{value});
    $old_cache_miss = 0 if ($old_miss > $self->{result}->{cache_miss}->{value});

    # Calculate
    my $delta_time = $self->{result}->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0); # One seconds ;)
    my $cache_hit = ($self->{result}->{cache_hit}->{value} - $old_cache_hit) / $delta_time;
    my $cache_hitpass = ($self->{result}->{cache_hitpass}->{value} - $old_cache_hitpass) / $delta_time;
    my $cache_miss = ($self->{result}->{cache_}->{value} - $old_cache_miss) / $delta_time;

    my $exit1 = $self->{perfdata}->threshold_check(value => $cache_hit, threshold =>      [ { label => 'critical-hit', 'exit_litteral' => 'critical' }, { label => 'warning-hit', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $cache_hitpass, threshold =>  [ { label => 'critical-hitpass', 'exit_litteral' => 'critical' }, { label => 'warning-hitpass', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $cache_miss, threshold =>     [ { label => 'critical-miss', 'exit_litteral' => 'critical' }, { label => 'warning-miss', exit_litteral => 'warning' } ]);
    
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Cache Hits: %.2f Cache Hits for pass: %.2f Cache misses: %.2f ", 
                                    $cache_hit,
                                    $cache_hitpass,
                                    $cache_miss,
                                    ));

    $self->{output}->perfdata_add(label => "cache_hit",
                                    value => $cache_hit,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-hit'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-hit'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "cache_hitpass",
                                    value => $cache_hitpass,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-hitpass'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-hitpass'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "cache_miss",
                                    value => $cache_miss,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-miss'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-miss'),
                                    min => 0
                                    );

    $self->{output}->display();
    $self->{output}->exit();
};


1;

__END__

=head1 MODE

Check Varnish Cache with varnishstat Command

=over 8

=item B<--command>

Varnishstat Binary Filename (Default: varnishstat)

=item B<--command-path>

Directory Path to Varnishstat Binary File (Default: /usr/bin/)

=item B<--command-options>

Parameter for Binary File (Default: ' -1 ')

=item B<--warning-hit>

Warning Threshold for Cache Hits

=item B<--warning-hit>

Warning Threshold for Cache Hits

=item B<--critical-hit>

Critical Threshold for Cache Hits

=item B<--warning-hitpass>

Warning Threshold for Cache hits for Pass

=item B<--critical-hitpass>

Critical Threshold for Cache hits for Pass

=item B<--warning-miss>

Warning Threshold for Cache Misses

=item B<--critical-miss>

Critical Threshold for Cache Misses

=back

=cut