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

package apps::varnish::mode::fetch;

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
            "warning-head:s"        => { name => 'warning_head', default => '' },
            "critical-head:s"       => { name => 'critical_head', default => '' },
            "warning-length:s"      => { name => 'warning_length', default => '' },
            "critical-length:s"     => { name => 'critical_length', default => '' },
            "warning-chunked:s"     => { name => 'warning_chunked', default => '' },
            "critical-chunked:s"    => { name => 'critical_chunked', default => '' },
            "warning-eof:s"         => { name => 'warning_eof', default => '' },
            "critical-eof:s"        => { name => 'critical_eof', default => '' },
            "warning-bad:s"         => { name => 'warning_bad', default => '' },
            "critical-bad:s"        => { name => 'critical_bad', default => '' },
            "warning-close:s"       => { name => 'warning_close', default => '' },
            "critical-close:s"      => { name => 'critical_close', default => '' },
            "warning-oldhttp:s"     => { name => 'warning_oldhttp', default => '' },
            "critical-oldhttp:s"    => { name => 'critical_oldhttp', default => '' },
            "warning-zero:s"        => { name => 'warning_zero', default => '' },
            "critical-zero:s"       => { name => 'critical_zero', default => '' },
            "warning-failed:s"      => { name => 'warning_failed', default => '' },
            "critical-failed:s"     => { name => 'critical_failed', default => '' },
            "warning-1xx:s"         => { name => 'warning_1xx', default => '' },
            "critical-1xx:s"        => { name => 'critical_1xx', default => '' },
            "warning-204:s"         => { name => 'warning_204', default => '' },
            "critical-204:s"        => { name => 'critical_204', default => '' },
            "warning-304:s"         => { name => 'warning_304', default => '' },
            "critical-304:s"        => { name => 'critical_304', default => '' },
        });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-head', value => $self->{option_results}->{warning_head})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-head threshold '" . $self->{option_results}->{warning_head} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-head', value => $self->{option_results}->{critical_head})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-head threshold '" . $self->{option_results}->{critical_head} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-length', value => $self->{option_results}->{warning_length})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-length threshold '" . $self->{option_results}->{warning_length} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-length', value => $self->{option_results}->{critical_length})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-length threshold '" . $self->{option_results}->{critical_length} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-chunked', value => $self->{option_results}->{warning_chunked})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-chunked threshold '" . $self->{option_results}->{warning_chunked} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-chunked', value => $self->{option_results}->{critical_chunked})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-chunked threshold '" . $self->{option_results}->{critical_chunked} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-eof', value => $self->{option_results}->{warning_eof})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-eof threshold '" . $self->{option_results}->{warning_eof} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-eof', value => $self->{option_results}->{critical_eof})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-eof threshold '" . $self->{option_results}->{critical_eof} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-bad', value => $self->{option_results}->{warning_bad})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-bad threshold '" . $self->{option_results}->{warning_bad} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-bad', value => $self->{option_results}->{critical_bad})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-bad threshold '" . $self->{option_results}->{critical_bad} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-close', value => $self->{option_results}->{warning_close})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-close threshold '" . $self->{option_results}->{warning_close} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-close', value => $self->{option_results}->{critical_close})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-close threshold '" . $self->{option_results}->{critical_close} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-oldhttp', value => $self->{option_results}->{warning_oldhttp})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-oldhttp threshold '" . $self->{option_results}->{warning_oldhttp} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-oldhttp', value => $self->{option_results}->{critical_oldhttp})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-oldhttp threshold '" . $self->{option_results}->{critical_oldhttp} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-zero', value => $self->{option_results}->{warning_zero})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-zero threshold '" . $self->{option_results}->{warning_zero} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-zero', value => $self->{option_results}->{critical_zero})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-zero threshold '" . $self->{option_results}->{critical_zero} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-failed', value => $self->{option_results}->{warning_failed})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-failed threshold '" . $self->{option_results}->{warning_failed} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-failed', value => $self->{option_results}->{critical_failed})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-failed threshold '" . $self->{option_results}->{critical_failed} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-1xx', value => $self->{option_results}->{warning_1xx})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-1xx threshold '" . $self->{option_results}->{warning_1xx} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-1xx', value => $self->{option_results}->{critical_1xx})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-1xx threshold '" . $self->{option_results}->{critical_1xx} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-204', value => $self->{option_results}->{warning_204})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-204 threshold '" . $self->{option_results}->{warning_204} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-204', value => $self->{option_results}->{critical_204})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-204 threshold '" . $self->{option_results}->{critical_204} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning-304', value => $self->{option_results}->{warning_304})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-304 threshold '" . $self->{option_results}->{warning_304} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-304', value => $self->{option_results}->{critical_304})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-304 threshold '" . $self->{option_results}->{critical_304} . "'.");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
}

#my $stdout = '
#fetch_head                   0         0.00 Fetch head
#fetch_length             13742         0.00 Fetch with Length
#fetch_chunked                0         0.00 Fetch chunked
#fetch_eof                    0         0.00 Fetch EOF
#fetch_bad                    0         0.00 Fetch had bad headers
#fetch_close                  0         0.00 Fetch wanted close
#fetch_oldhttp                0         0.00 Fetch pre HTTP/1.1 closed
#fetch_zero                   0         0.00 Fetch zero len
#fetch_failed                 0         0.00 Fetch failed
#fetch_1xx                    0         0.00 Fetch no body (1xx)
#fetch_204                    0         0.00 Fetch no body (204)
#fetch_304                    0         0.00 Fetch no body (304)
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
    my $old_fetch_head      = $self->{statefile_value}->get(name => 'fetch_head');
    my $old_fetch_length    = $self->{statefile_value}->get(name => 'fetch_length');
    my $old_fetch_chunked   = $self->{statefile_value}->get(name => 'fetch_chunked');
    my $old_fetch_eof       = $self->{statefile_value}->get(name => 'fetch_eof');
    my $old_fetch_bad       = $self->{statefile_value}->get(name => 'fetch_bad');
    my $old_fetch_close     = $self->{statefile_value}->get(name => 'fetch_close');
    my $old_fetch_oldhttp   = $self->{statefile_value}->get(name => 'fetch_oldhttp');
    my $old_fetch_zero      = $self->{statefile_value}->get(name => 'fetch_zero');
    my $old_fetch_failed    = $self->{statefile_value}->get(name => 'fetch_failed');
    my $old_fetch_1xx       = $self->{statefile_value}->get(name => 'fetch_1xx');
    my $old_fetch_204       = $self->{statefile_value}->get(name => 'fetch_204');
    my $old_fetch_304       = $self->{statefile_value}->get(name => 'fetch_304');


    $self->{statefile_value}->write(data => $self->{result}); 
    if (!defined($old_timestamp) || !defined($old_fetch_head)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Set 0 if Cache > Result
    $old_fetch_head = 0 if ($old_fetch_head > $self->{result}->{fetch_head} ); 
    $old_fetch_length = 0 if ($old_hitpass > $self->{result}->{fetch_length});
    $old_fetch_chunked = 0 if ($old_miss > $self->{result}->{fetch_chunked});
    $old_fetch_eof = 0 if ($old_miss > $self->{result}->{fetch_eof});
    $old_fetch_bad = 0 if ($old_miss > $self->{result}->{fetch_bad});
    $old_fetch_close = 0 if ($old_miss > $self->{result}->{fetch_close});
    $old_fetch_oldhttp = 0 if ($old_miss > $self->{result}->{fetch_oldhttp});
    $old_fetch_zero = 0 if ($old_miss > $self->{result}->{fetch_zero});
    $old_fetch_failed = 0 if ($old_miss > $self->{result}->{fetch_failed});
    $old_fetch_1xx = 0 if ($old_miss > $self->{result}->{fetch_1xx});
    $old_fetch_204 = 0 if ($old_miss > $self->{result}->{fetch_204});
    $old_fetch_304 = 0 if ($old_miss > $self->{result}->{fetch_304});

    # Calculate
    my $delta_time = $self->{result}->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0); # One seconds ;)
    my $fetch_head = ($self->{result}->{fetch_head} - $old_fetch_head) / $delta_time;
    my $fetch_length = ($self->{result}->{fetch_length} - $old_fetch_length) / $delta_time;
    my $fetch_chunked = ($self->{result}->{fetch_chunked} - $old_fetch_chunked) / $delta_time;
    my $fetch_eof = ($self->{result}->{fetch_eof} - $old_fetch_eof) / $delta_time;
    my $fetch_bad = ($self->{result}->{fetch_bad} - $old_fetch_bad) / $delta_time;
    my $fetch_close = ($self->{result}->{fetch_close} - $old_fetch_close) / $delta_time;
    my $fetch_oldhttp = ($self->{result}->{fetch_oldhttp} - $old_fetch_oldhttp) / $delta_time;
    my $fetch_zero = ($self->{result}->{fetch_zero} - $old_fetch_zero) / $delta_time;
    my $fetch_failed = ($self->{result}->{fetch_failed} - $old_fetch_failed) / $delta_time;
    my $fetch_1xx = ($self->{result}->{fetch_1xx} - $old_fetch_1xx) / $delta_time;
    my $fetch_204 = ($self->{result}->{fetch_204} - $old_fetch_204) / $delta_time;
    my $fetch_304 = ($self->{result}->{fetch_304} - $old_fetch_304) / $delta_time;

    my $exit1  = $self->{perfdata}->threshold_check(value => $fetch_head, threshold =>   [ { label => 'critical-head', 'exit_litteral' => 'critical' }, { label => 'warning-head', exit_litteral => 'warning' } ]);
    my $exit2  = $self->{perfdata}->threshold_check(value => $fetch_length, threshold =>   [ { label => 'critical-length', 'exit_litteral' => 'critical' }, { label => 'warning-length', exit_litteral => 'warning' } ]);
    my $exit3  = $self->{perfdata}->threshold_check(value => $fetch_chunked, threshold =>    [ { label => 'critical-chunked', 'exit_litteral' => 'critical' }, { label => 'warning-chunked', exit_litteral => 'warning' } ]);
    my $exit4  = $self->{perfdata}->threshold_check(value => $fetch_eof, threshold =>    [ { label => 'critical-eof', 'exit_litteral' => 'critical' }, { label => 'warning-eof', exit_litteral => 'warning' } ]);
    my $exit5  = $self->{perfdata}->threshold_check(value => $fetch_eof, threshold =>    [ { label => 'critical-eof', 'exit_litteral' => 'critical' }, { label => 'warning-eof', exit_litteral => 'warning' } ]);    
    my $exit6  = $self->{perfdata}->threshold_check(value => $fetch_close, threshold =>    [ { label => 'critical-close', 'exit_litteral' => 'critical' }, { label => 'warning-close', exit_litteral => 'warning' } ]);
    my $exit7  = $self->{perfdata}->threshold_check(value => $fetch_oldhttp, threshold =>    [ { label => 'critical-oldhttp', 'exit_litteral' => 'critical' }, { label => 'warning-oldhttp', exit_litteral => 'warning' } ]);
    my $exit8  = $self->{perfdata}->threshold_check(value => $fetch_zero, threshold =>    [ { label => 'critical-zero', 'exit_litteral' => 'critical' }, { label => 'warning-zero', exit_litteral => 'warning' } ]);
    my $exit9  = $self->{perfdata}->threshold_check(value => $fetch_failed, threshold =>    [ { label => 'critical-failed', 'exit_litteral' => 'critical' }, { label => 'warning-failed', exit_litteral => 'warning' } ]);
    my $exit10 = $self->{perfdata}->threshold_check(value => $fetch_1xx, threshold =>    [ { label => 'critical-1xx', 'exit_litteral' => 'critical' }, { label => 'warning-1xx', exit_litteral => 'warning' } ]);
    my $exit11 = $self->{perfdata}->threshold_check(value => $fetch_204, threshold =>    [ { label => 'critical-204', 'exit_litteral' => 'critical' }, { label => 'warning-204', exit_litteral => 'warning' } ]);
    my $exit12 = $self->{perfdata}->threshold_check(value => $fetch_304, threshold =>    [ { label => 'critical-304', 'exit_litteral' => 'critical' }, { label => 'warning-304', exit_litteral => 'warning' } ]);

    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3, $exit4, $exit5, $exit6, $exit7, $exit8, $exit9, $exit10, $exit11, $exit12 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Fetch head: %.2f 
                                                      Fetch with Length: %.2f
                                                      Fetch chunked: %.2f
                                                      Fetch EOF: %.2f
                                                      Fetch had bad headers: %.2f
                                                      Fetch wanted close: %.2f
                                                      Fetch pre HTTP/1.1 closed: %.2f
                                                      Fetch zero len: %.2f
                                                      Fetch failed: %.2f
                                                      Fetch no body (1xx): %.2f
                                                      Fetch no body (204): %.2f
                                                      Fetch no body (304): %.2f ", 
                                    $fetch_head,
                                    $fetch_length,
                                    $fetch_chunked,
                                    $fetch_eof,
                                    $fetch_bad,
                                    $fetch_close,
                                    $fetch_oldhttp,
                                    $fetch_zero,
                                    $fetch_failed,
                                    $fetch_1xx,
                                    $fetch_204,
                                    $fetch_304,
                                    ));

    $self->{output}->perfdata_add(label => "fetch_head",
                                    value => $fetch_head,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-head'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-head'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_length",
                                    value => $fetch_length,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-length'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-length'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_chunked",
                                    value => $fetch_chunked,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-chunked'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-chunked'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_eof",
                                    value => $fetch_eof,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-eof'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-eof'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_bad",
                                    value => $fetch_bad,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-bad'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-bad'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_close",
                                    value => $fetch_close,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-close'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-close'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_oldhttp",
                                    value => $fetch_oldhttp,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-oldhttp'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-oldhttp'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_zero",
                                    value => $fetch_zero,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-zero'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-zero'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_failed",
                                    value => $fetch_failed,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-failed'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-failed'),
                                    min => 0
                                    );

    $self->{output}->perfdata_add(label => "fetch_1xx",
                                    value => $fetch_1xx,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-1xx'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-1xx'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_204",
                                    value => $fetch_204,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-204'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-204'),
                                    min => 0
                                    );
    $self->{output}->perfdata_add(label => "fetch_304",
                                    value => $fetch_304,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-304'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-304'),
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
- Fetch head
- Fetch with Length
- Fetch chunked
- Fetch EOF
- Fetch had bad headers
- Fetch wanted close
- Fetch pre HTTP/1.1 closed
- Fetch zero len
- Fetch failed
- Fetch no body (1xx)
- Fetch no body (204)
- Fetch no body (304)

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

=item B<--warning-head>

Warning Threshold for Fetch head

=item B<--critical-head>

Critical Threshold for Fetch head

=item B<--warning-length>

Warning Threshold for Fetch with Length

=item B<--critical-length>

Critical Threshold for Fetch with Length

=item B<--warning-chunked>

Warning Threshold for Fetch chunked

=item B<--critical-chunked>

Critical Threshold for Fetch chunked

=item B<--warning-eof>

Warning Threshold for Fetch EOF

=item B<--critical-eof>

Critical Threshold for Fetch EOF

=item B<--warning-bad>

Warning Threshold for Fetch had bad headers

=item B<--critical-bad>

Critical Threshold for Fetch had bad headers

=item B<--warning-close>

Warning Threshold for Fetch wanted close

=item B<--critical-close>

Critical Threshold for Fetch wanted close

=item B<--warning-oldhttp>

Warning Threshold for Fetch pre HTTP/1.1 closed

=item B<--critical-oldhttp>

Critical Threshold for Fetch pre HTTP/1.1 closed

=item B<--warning-zero>

Warning Threshold for Fetch zero len

=item B<--critical-zero>

Critical Threshold for Fetch zero len

=item B<--warning-failed>

Warning Threshold for Fetch failed

=item B<--critical-failed>

Critical Threshold for Fetch failed

=item B<--warning-1xx>

Warning Threshold for Fetch no body (1xx)

=item B<--critical-1xx>

Critical Threshold for Fetch no body (1xx)

=item B<--warning-204>

Warning Threshold for Fetch no body (204)

=item B<--critical-204>

Critical Threshold for Fetch no body (204)

=item B<--warning-304>

Warning Threshold for Fetch no body (304)

=item B<--critical-304>

Critical Threshold for Fetch no body (304)

=back

=cut