################################################################################
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

package centreon::plugins::misc;

use strict;
use warnings;
use utf8;

# Function more simple for Windows platform
sub windows_execute {
    my (%options) = @_;
    my $result = undef;
    my $stdout = '';
    my ($exit_code, $cmd);
    
    $cmd = $options{command_path} . '/' if (defined($options{command_path}));
    $cmd .= $options{command} . ' ' if (defined($options{command}));
    $cmd .= $options{command_options} if (defined($options{command_options}));
    
    eval {
        local $SIG{ALRM} = sub { die "Timeout by signal ALARM\n"; };
        alarm( $options{timeout} );
        $stdout = `$cmd`;
        $exit_code = ($? >> 8);
        alarm(0);
    };

    if ($@) {
        $options{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command too long to execute (timeout)...");
        $options{output}->display();
        $options{output}->exit();
    }
    chomp $stdout;
    $stdout =~ s/\r//g;
    
    if (defined($options{no_quit}) && $options{no_quit} == 1) {
        return ($stdout, $exit_code);
    }
    
    if ($exit_code != 0) {
        $stdout =~ s/\n/ - /g;
        $options{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command error: $stdout");
        $options{output}->display();
        $options{output}->exit();
    }

    return $stdout;
}

sub execute {
    my (%options) = @_;
    my $cmd = '';
    my $args = [];
    my ($lerror, $stdout, $exit_code);
    
    # Build command line
    # Can choose which command is done remotely (can filter and use local file)
    if (defined($options{options}->{remote}) && 
        ($options{options}->{remote} eq '' || !defined($options{label}) || $options{label} =~ /$options{options}->{remote}/)) {
        my $sub_cmd;

        $cmd = $options{options}->{ssh_path} . '/' if (defined($options{options}->{ssh_path}));
        $cmd .= $options{options}->{ssh_command} if (defined($options{options}->{ssh_command}));
        
        foreach (@{$options{options}->{ssh_option}}) {
            my ($lvalue, $rvalue) = split /=/;
            push @$args, $lvalue if (defined($lvalue));
            push @$args, $rvalue if (defined($rvalue));
        }
        
        push @$args, $options{options}->{hostname};
        
        $sub_cmd = 'sudo ' if (defined($options{sudo}));
        $sub_cmd .= $options{command_path} . '/' if (defined($options{command_path}));
        $sub_cmd .= $options{command} . ' ' if (defined($options{command}));
        $sub_cmd .= $options{command_options} if (defined($options{command_options}));
        ($lerror, $stdout, $exit_code) = backtick(
                                                 command => $cmd,
                                                 arguments => [@$args, $sub_cmd],
                                                 timeout => $options{options}->{timeout},
                                                 wait_exit => 1,
                                                 redirect_stderr => 1
                                                 );
    } else {
        $cmd = 'sudo ' if (defined($options{sudo}));
        $cmd .= $options{command_path} . '/' if (defined($options{command_path}));
        $cmd .= $options{command} . ' ' if (defined($options{command}));
        $cmd .= $options{command_options} if (defined($options{command_options}));
        
        ($lerror, $stdout, $exit_code) = backtick(
                                                 command => $cmd,
                                                 timeout => $options{options}->{timeout},
                                                 wait_exit => 1,
                                                 redirect_stderr => 1
                                                 );
    }

    if (defined($options{options}->{show_output}) && 
        ($options{options}->{show_output} eq '' || (defined($options{label}) && $options{label} eq $options{options}->{show_output}))) {
        print $stdout;
        exit $exit_code;
    }
    
    $stdout =~ s/\r//g;
    if ($lerror <= -1000) {
        $options{output}->output_add(severity => 'UNKNOWN', 
                                     short_msg => $stdout);
        $options{output}->display();
        $options{output}->exit();
    }
    
    if (defined($options{no_quit}) && $options{no_quit} == 1) {
        return ($stdout, $exit_code);
    }
    
    if ($exit_code != 0 && (!defined($options{no_errors}) || !defined($options{no_errors}->{$exit_code}))) {
        $stdout =~ s/\n/ - /g;
        $options{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command error: $stdout");
        $options{output}->display();
        $options{output}->exit();
    }
    
    return $stdout;
}

sub mymodule_load {
    my (%options) = @_;
    my $file;
    ($file = $options{module} . ".pm") =~ s{::}{/}g;
     
    eval {
        local $SIG{__DIE__} = 'IGNORE';
        require $file;
    };
    if ($@) {
        $options{output}->add_option_msg(long_msg => $@);
        $options{output}->add_option_msg(short_msg => $options{error_msg});
        $options{output}->option_exit();
    }
}

sub backtick {
    my %arg = (
        command => undef,
        arguments => [],
        timeout => 30,
        wait_exit => 0,
        redirect_stderr => 0,
        @_,
    );
    my @output;
    my $pid;
    my $return_code;
    
    my $sig_do;
    if ($arg{wait_exit} == 0) {
        $sig_do = 'IGNORE';
        $return_code = undef;
    } else {
        $sig_do = 'DEFAULT';
    }
    local $SIG{CHLD} = $sig_do;
    $SIG{TTOU} = 'IGNORE';
    $| = 1;

    if (!defined($pid = open( KID, "-|" ))) {
        return (-1001, "Cant fork: $!", -1);
    }

    if ($pid) {
        
        eval {
           local $SIG{ALRM} = sub { die "Timeout by signal ALARM\n"; };
           alarm( $arg{timeout} );
           while (<KID>) {
               chomp;
               push @output, $_;
           }

           alarm(0);
        };

        if ($@) {
            if ($pid != -1) {
                kill -9, $pid;
            }

            alarm(0);
            return (-1000, "Command too long to execute (timeout)...", -1);
        } else {
            if ($arg{wait_exit} == 1) {
                # We're waiting the exit code                
                waitpid($pid, 0);
                $return_code = ($? >> 8);
            }
            close KID;
        }
    } else {
        # child
        # set the child process to be a group leader, so that
        # kill -9 will kill it and all its descendents
        # We have ignore SIGTTOU to let write background processes
        setpgrp( 0, 0 );

        if ($arg{redirect_stderr} == 1) {
            open STDERR, ">&STDOUT";
        }
        if (scalar(@{$arg{arguments}}) <= 0) {
            exec($arg{command});
        } else {
            exec($arg{command}, @{$arg{arguments}});
        }
        # Exec is in error. No such command maybe.
        exit(127);
    }

    return (0, join("\n", @output), $return_code);
}

sub trim {
    my ($value) = $_[0];
    
    # Sometimes there is a null character
    $value =~ s/\x00$//;
    $value =~ s/^[ \t]+//;
    $value =~ s/[ \t]+$//;
    return $value;
}

sub powershell_encoded {
	my ($value) = $_[0];

	require Encode;
	require MIME::Base64;
	my $bytes = Encode::encode("utf16LE", $value);
	my $script = MIME::Base64::encode_base64($bytes, "\n");
	$script =~ s/\n//g;
	return $script;
}

sub powershell_escape {
    my ($value) = $_[0];
    $value =~ s/`/``/g;
    $value =~ s/#/`#/g;
    $value =~ s/'/`'/g;
    $value =~ s/"/`"/g;
    return $value;
}

sub minimal_version {
    my ($version_src, $version_dst) = @_;
    
    # No Version. We skip   
    if (!defined($version_src) || !defined($version_dst) || 
        $version_src !~ /^[0-9]+(?:\.[0-9\.])*$/ || $version_dst !~ /^[0-9x]+(?:\.[0-9x\.])*$/) {
        return 1;
    }
    
    my @version_src = split /\./, $version_src;
    my @versions = split /\./, $version_dst;
    for (my $i = 0; $i < scalar(@versions); $i++) {
        return 1 if ($versions[$i] eq 'x');
        return 1 if (!defined($version_src[$i]));
        $version_src[$i] =~ /^([0-9]*)/;
        next if ($versions[$i] == int($1));
        return 0 if ($versions[$i] > int($1));
        return 1 if ($versions[$i] < int($1));
    }
    
    return 1;
}

1;

__END__

