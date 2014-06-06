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

package apps::varnish::mode::backend;

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
            "hostname:s"            => { name => 'hostname' },
            "remote"                => { name => 'remote' },
            "ssh-option:s@"         => { name => 'ssh_option' },
            "ssh-path:s"            => { name => 'ssh_path' },
            "ssh-command:s"         => { name => 'ssh_command', default => 'ssh' },
            "timeout:s"             => { name => 'timeout', default => 30 },
            "sudo"                  => { name => 'sudo' },
            "command:s"             => { name => 'command', default => 'varnishstat' },
            "command-path:s"        => { name => 'command_path', default => '/usr/bin/' },
            "command-options:s"     => { name => 'command_options', default => ' -1 ' },
            "command-options2:s"    => { name => 'command_options2', default => ' 2>&1' },
            "warning-conn:s"        => { name => 'warning_conn', default => '' },
            "critical-conn:s"       => { name => 'critical_conn', default => '' },
            "warning-unhealthy:s"   => { name => 'warning_unhealthy', default => '' },
            "critical-unhealthy:s"  => { name => 'critical_unhealthy', default => '' },
            "warning-busy:s"        => { name => 'warning_busy', default => '' },
            "critical-busy:s"       => { name => 'critical_busy', default => '' },
            "warning-fail:s"        => { name => 'warning_fail', default => '' },
            "critical-fail:s"       => { name => 'critical_fail', default => '' },
            "warning-reuse:s"       => { name => 'warning_reuse', default => '' },
            "critical-reuse:s"      => { name => 'critical_reuse', default => '' },
            "warning-toolate:s"     => { name => 'warning_toolate', default => '' },
            "critical-toolate:s"    => { name => 'critical_toolate', default => '' },
            "warning-recycle:s"     => { name => 'warning_recycle', default => '' },
            "critical-recycle:s"    => { name => 'critical_recycle', default => '' },
            "warning-retry:s"       => { name => 'warning_retry', default => '' },
            "critical-retry:s"      => { name => 'critical_retry', default => '' },
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

    if (($self->{perfdata}->threshold_validate(label => 'warning-unhealthy', value => $self->{option_results}->{warning_unhealthy})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-unhealthy threshold '" . $self->{option_results}->{warning_unhealthy} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-unhealthy', value => $self->{option_results}->{critical_unhealthy})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-unhealthy threshold '" . $self->{option_results}->{critical_unhealthy} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-busy', value => $self->{option_results}->{warning_busy})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-busy threshold '" . $self->{option_results}->{warning_busy} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-busy', value => $self->{option_results}->{critical_busy})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-busy threshold '" . $self->{option_results}->{critical_busy} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-fail', value => $self->{option_results}->{warning_fail})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-fail threshold '" . $self->{option_results}->{warning_fail} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-fail', value => $self->{option_results}->{critical_fail})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-fail threshold '" . $self->{option_results}->{critical_fail} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-reuse', value => $self->{option_results}->{warning_reuse})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-reuse threshold '" . $self->{option_results}->{warning_reuse} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-reuse', value => $self->{option_results}->{critical_reuse})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-reuse threshold '" . $self->{option_results}->{critical_reuse} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-toolate', value => $self->{option_results}->{warning_toolate})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-toolate threshold '" . $self->{option_results}->{warning_toolate} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-toolate', value => $self->{option_results}->{critical_toolate})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-toolate threshold '" . $self->{option_results}->{critical_toolate} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-recycle', value => $self->{option_results}->{warning_recycle})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-recycle threshold '" . $self->{option_results}->{warning_recycle} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-recycle', value => $self->{option_results}->{critical_recycle})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-recycle threshold '" . $self->{option_results}->{critical_recycle} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-retry', value => $self->{option_results}->{warning_retry})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-retry threshold '" . $self->{option_results}->{warning_retry} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-retry', value => $self->{option_results}->{critical_retry})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-retry threshold '" . $self->{option_results}->{critical_retry} . "'.");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
}

#my $stdout = '
#backend_conn             13746         0.00 Backend conn. success
#backend_unhealthy            0         0.00 Backend conn. not attempted
#backend_busy                 0         0.00 Backend conn. too many
#backend_fail                 0         0.00 Backend conn. failures
#backend_reuse                0         0.00 Backend conn. reuses
#backend_toolate              0         0.00 Backend conn. was closed
#backend_recycle              0         0.00 Backend conn. recycles
#backend_retry                0         0.00 Backend conn. retry
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
    my $old_backend_conn = $self->{statefile_value}->get(name => 'backend_conn');
    my $old_backend_unhealthy = $self->{statefile_value}->get(name => 'backend_unhealthy');
    my $old_backend_busy    = $self->{statefile_value}->get(name => 'backend_busy');
    my $old_backend_fail    = $self->{statefile_value}->get(name => 'backend_fail');
    my $old_backend_reuse    = $self->{statefile_value}->get(name => 'backend_reuse');
    my $old_backend_toolate    = $self->{statefile_value}->get(name => 'backend_toolate');
    my $old_backend_recycle    = $self->{statefile_value}->get(name => 'backend_recycle');
    my $old_backend_retry    = $self->{statefile_value}->get(name => 'backend_retry');

    $self->{statefile_value}->write(data => $self->{result}); 
    if (!defined($old_timestamp) || !defined($old_backend_conn)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Set 0 if Cache > Result
    $old_backend_conn = 0 if ($old_backend_conn > $self->{result}->{backend_conn} ); 
    $old_backend_unhealthy = 0 if ($old_hitpass > $self->{result}->{backend_unhealthy});
    $old_backend_busy = 0 if ($old_miss > $self->{result}->{backend_busy});
    $old_backend_fail = 0 if ($old_miss > $self->{result}->{backend_fail});
    $old_backend_reuse = 0 if ($old_miss > $self->{result}->{backend_reuse});
    $old_backend_toolate = 0 if ($old_miss > $self->{result}->{backend_toolate});
    $old_backend_recycle = 0 if ($old_miss > $self->{result}->{backend_recycle});
    $old_backend_retry = 0 if ($old_miss > $self->{result}->{backend_retry});

    # Calculate
    my $delta_time = $self->{result}->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0); # One seconds ;)
    my $backend_conn = ($self->{result}->{backend_conn} - $old_backend_conn) / $delta_time;
    my $backend_unhealthy = ($self->{result}->{backend_unhealthy} - $old_backend_unhealthy) / $delta_time;
    my $backend_busy = ($self->{result}->{backend_busy} - $old_backend_busy) / $delta_time;
    my $backend_fail = ($self->{result}->{backend_fail} - $old_backend_fail) / $delta_time;
    my $backend_reuse = ($self->{result}->{backend_reuse} - $old_backend_reuse) / $delta_time;
    my $backend_toolate = ($self->{result}->{backend_toolate} - $old_backend_toolate) / $delta_time;
    my $backend_recycle = ($self->{result}->{backend_recycle} - $old_backend_recycle) / $delta_time;
    my $backend_retry = ($self->{result}->{backend_retry} - $old_backend_retry) / $delta_time;

    my $exit1 = $self->{perfdata}->threshold_check(value => $backend_conn, threshold =>   [ { label => 'critical-conn', 'exit_litteral' => 'critical' }, { label => 'warning-conn', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $backend_unhealthy, threshold =>   [ { label => 'critical-unhealthy', 'exit_litteral' => 'critical' }, { label => 'warning-unhealthy', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $backend_busy, threshold =>    [ { label => 'critical-busy', 'exit_litteral' => 'critical' }, { label => 'warning-busy', exit_litteral => 'warning' } ]);
    my $exit4 = $self->{perfdata}->threshold_check(value => $backend_fail, threshold =>    [ { label => 'critical-fail', 'exit_litteral' => 'critical' }, { label => 'warning-fail', exit_litteral => 'warning' } ]);
    my $exit5 = $self->{perfdata}->threshold_check(value => $backend_reuse, threshold =>    [ { label => 'critical-reuse', 'exit_litteral' => 'critical' }, { label => 'warning-reuse', exit_litteral => 'warning' } ]);
    my $exit6 = $self->{perfdata}->threshold_check(value => $backend_toolate, threshold =>    [ { label => 'critical-toolate', 'exit_litteral' => 'critical' }, { label => 'warning-toolate', exit_litteral => 'warning' } ]);
    my $exit7 = $self->{perfdata}->threshold_check(value => $backend_recycle, threshold =>    [ { label => 'critical-recycle', 'exit_litteral' => 'critical' }, { label => 'warning-recycle', exit_litteral => 'warning' } ]);
    my $exit8 = $self->{perfdata}->threshold_check(value => $backend_retry, threshold =>    [ { label => 'critical-retry', 'exit_litteral' => 'critical' }, { label => 'warning-retry', exit_litteral => 'warning' } ]);

    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3, $exit4, $exit5, $exit6, $exit7, $exit8 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Backend conn. success: %.2f 
                                                      Backend conn. not attempted: %.2f
                                                      Backend conn. too many: %.2f
                                                      Backend conn. failures: %.2f
                                                      Backend conn. reuses: %.2f
                                                      Backend conn. was closed: %.2f
                                                      Backend conn. recycles: %.2f
                                                      Backend conn. retry: %.2f ", 
                                    $backend_conn,
                                    $backend_unhealthy,
                                    $backend_busy,
                                    $backend_fail,
                                    $backend_reuse,
                                    $backend_toolate,
                                    $backend_recycle,
                                    $backend_retry,
                                    ));

    $self->{output}->perfdata_add(label => "backend_conn",
                                    value => $backend_conn,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-conn'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-conn'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "backend_unhealthy",
                                    value => $backend_unhealthy,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-unhealthy'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-unhealthy'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "backend_busy",
                                    value => $backend_busy,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-busy'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-busy'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "backend_fail",
                                    value => $backend_fail,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-fail'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-fail'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "backend_reuse",
                                    value => $backend_reuse,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-reuse'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-reuse'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "backend_toolate",
                                    value => $backend_toolate,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-toolate'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-toolate'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "backend_recycle",
                                    value => $backend_recycle,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-recycle'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-recycle'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "backend_retry",
                                    value => $backend_retry,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-retry'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-retry'),
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
- Backend conn. success
- Backend conn. not attempted
- Backend conn. too many
- Backend conn. failures
- Backend conn. reuses
- Backend conn. was closed
- Backend conn. recycles
- Backend conn. unused

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

Warning Threshold for Backend conn. success

=item B<--critical-conn>

Critical Threshold for Backend conn. success

=item B<--warning-unhealthy>

Warning Threshold for Backend conn. not attempted

=item B<--critical-unhealthy>

Critical Threshold for Backend conn. not attempted

=item B<--warning-busy>

Warning Threshold for Backend conn. too many

=item B<--critical-busy>

Critical Threshold for Backend conn. too many

=item B<--warning-fail>

Warning Threshold for Backend conn. failures

=item B<--critical-fail>

Critical Threshold for Backend conn. failures

=item B<--warning-reuse>

Warning Threshold for Backend conn. reuses

=item B<--critical-reuse>

Critical Threshold for Backend conn. reuses

=item B<--warning-toolate>

Warning Threshold for Backend conn. was closed

=item B<--critical-toolate>

Critical Threshold for Backend conn. was closed

=item B<--warning-recycle>

Warning Threshold for Backend conn. recycles

=item B<--critical-recycle>

Critical Threshold for Backend conn. recycles

=item B<--warning-retry>

Warning Threshold for Backend conn. retry

=item B<--critical-retry>

Critical Threshold for Backend conn. retry

=back

=cut