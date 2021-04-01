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

package centreon::plugins::misc;

use strict;
use warnings;
use utf8;

sub execute {
    my (%options) = @_;
    
    if ($^O eq 'MSWin32') {
        return windows_execute(%options, timeout => $options{options}->{timeout});
    } else {
        return unix_execute(%options);
    }
}

sub windows_execute {
    my (%options) = @_;
    my $result;
    my ($stdout, $pid, $ended) = ('');
    my ($exit_code, $cmd);

    $cmd = $options{command_path} . '/' if (defined($options{command_path}));
    $cmd .= $options{command} . ' ' if (defined($options{command}));
    $cmd .= $options{command_options} if (defined($options{command_options}));

    centreon::plugins::misc::mymodule_load(
        output => $options{output}, module => 'Win32::Job',
        error_msg => "Cannot load module 'Win32::Job'."
    );
    centreon::plugins::misc::mymodule_load(
        output => $options{output}, module => 'Time::HiRes',
        error_msg => "Cannot load module 'Time::HiRes'."
    );

    $| = 1;
    pipe FROM_CHILD, TO_PARENT or do {
        $options{output}->add_option_msg(short_msg => "Internal error: can't create pipe from child to parent: $!");
        $options{output}->option_exit();
    };
    my $job = Win32::Job->new;
    my $stderr = 'NUL';
    $stderr = \*TO_PARENT if ($options{output}->is_debug());
    if (!($pid = $job->spawn(undef, $cmd,
                       { stdin => 'NUL',
                         stdout => \*TO_PARENT,
                         stderr => $stderr }))) {
        $options{output}->add_option_msg(short_msg => "Internal error: execution issue: $^E");
        $options{output}->option_exit();
    }
    close TO_PARENT;

    my $ein = '';
    vec($ein, fileno(FROM_CHILD), 1) = 1;
    $job->watch(
        sub {            
            my ($buffer);
            my $time = $options{timeout};
            my $last_time = Time::HiRes::time();
            $ended = 0;
            while (select($ein, undef, undef, $options{timeout})) {
                if (sysread(FROM_CHILD, $buffer, 16384)) {
                    $buffer =~ s/\r//g;
                    $stdout .= $buffer;
                } else {
                    $ended = 1;
                    last;
                }
                $options{timeout} -= Time::HiRes::time() - $last_time;
                last if ($options{timeout} <= 0);         
                $last_time = Time::HiRes::time();
            }
            return 1 if ($ended == 0);
            return 0;
        },
        0.1
    );

    $result = $job->status;
    close FROM_CHILD;    

    if ($ended == 0) {
        $options{output}->add_option_msg(short_msg => 'Command too long to execute (timeout)...');
        $options{output}->option_exit();
    }
    chomp $stdout;
    
    if (defined($options{no_quit}) && $options{no_quit} == 1) {
        return ($stdout, $result->{$pid}->{exitcode});
    }

    if ($result->{$pid}->{exitcode} != 0) {
        $stdout =~ s/\n/ - /g;
        $options{output}->add_option_msg(short_msg => "Command error: $stdout");
        $options{output}->option_exit();
    }

    return ($stdout, $result->{$pid}->{exitcode});
}

sub unix_execute {
    my (%options) = @_;
    my $cmd = '';
    my $args = [];
    my ($lerror, $stdout, $exit_code);

    my $redirect_stderr = 1;
    $redirect_stderr = $options{redirect_stderr} if (defined($options{redirect_stderr}));
    my $wait_exit = 1;
    $wait_exit = $options{wait_exit} if (defined($options{wait_exit}));

    # Build command line
    # Can choose which command is done remotely (can filter and use local file)
    if (defined($options{options}->{remote}) && 
        ($options{options}->{remote} eq '' || !defined($options{label}) || $options{label} =~ /$options{options}->{remote}/)) {
        my $sub_cmd;

        $cmd = $options{options}->{ssh_path} . '/' if (defined($options{options}->{ssh_path}));
        $cmd .= $options{options}->{ssh_command} if (defined($options{options}->{ssh_command}));

        foreach (@{$options{options}->{ssh_option}}) {
            if (/^(.*?)(?:=(.*))?$/) {
                push @$args, $1 if (defined($1));
                push @$args, $2 if (defined($2));
            }
        }

        if (defined($options{options}->{ssh_address}) && $options{options}->{ssh_address} ne '') {
            push @$args, $options{options}->{ssh_address};
        } else {
            push @$args, $options{options}->{hostname};
        }

        $sub_cmd = 'sudo ' if (defined($options{sudo}));
        $sub_cmd .= $options{command_path} . '/' if (defined($options{command_path}));
        $sub_cmd .= $options{command} . ' ' if (defined($options{command}));
        $sub_cmd .= $options{command_options} if (defined($options{command_options}));
        # On some equipment. Cannot get a pseudo terminal
        if (defined($options{ssh_pipe}) && $options{ssh_pipe} == 1) {
            $cmd = "echo '" . $sub_cmd . "' | " . $cmd . ' ' . join(' ', @$args);
            ($lerror, $stdout, $exit_code) = backtick(
                command => $cmd,
                timeout => $options{options}->{timeout},
                wait_exit => $wait_exit,
                redirect_stderr => $redirect_stderr
            );
        } else {
            ($lerror, $stdout, $exit_code) = backtick(
                command => $cmd,
                arguments => [@$args, $sub_cmd],
                timeout => $options{options}->{timeout},
                wait_exit => $wait_exit,
                redirect_stderr => $redirect_stderr
            );
        }
    } else {
        $cmd = 'sudo ' if (defined($options{sudo}));
        $cmd .= $options{command_path} . '/' if (defined($options{command_path}));
        $cmd .= $options{command} . ' ' if (defined($options{command}));
        $cmd .= $options{command_options} if (defined($options{command_options}));

        ($lerror, $stdout, $exit_code) = backtick(
            command => $cmd,
            timeout => $options{options}->{timeout},
            wait_exit => $wait_exit,
            redirect_stderr => $redirect_stderr
        );
    }

    if (defined($options{options}->{show_output}) && 
        ($options{options}->{show_output} eq '' || (defined($options{label}) && $options{label} eq $options{options}->{show_output}))) {
        print $stdout;
        exit $exit_code;
    }

    $stdout =~ s/\r//g;
    if ($lerror <= -1000) {
        $options{output}->add_option_msg(short_msg => $stdout);
        $options{output}->option_exit();
    }

    if (defined($options{no_quit}) && $options{no_quit} == 1) {
        return ($stdout, $exit_code);
    }

    if ($exit_code != 0 && (!defined($options{no_errors}) || !defined($options{no_errors}->{$exit_code}))) {
        $stdout =~ s/\n/ - /g;
        $options{output}->add_option_msg(short_msg => "Command error: $stdout");
        $options{output}->option_exit();
    }

    return $stdout;
}

sub mymodule_load {
    my (%options) = @_;
    my $file;
    ($file = ($options{module} =~ /\.pm$/ ? $options{module} : $options{module} . '.pm')) =~ s{::}{/}g;

    eval {
        local $SIG{__DIE__} = 'IGNORE';
        require $file;
        $file =~ s{/}{::}g;
        $file =~ s/\.pm$//;
    };
    if ($@) {
        return 1 if (defined($options{no_quit}) && $options{no_quit} == 1);
        $options{output}->add_option_msg(long_msg => $@);
        $options{output}->add_option_msg(short_msg => $options{error_msg});
        $options{output}->option_exit();
    }
    return wantarray ? (0, $file) : 0;
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
            return (-1000, 'Command too long to execute (timeout)...', -1);
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
            open STDERR, '>&STDOUT';
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
    $value =~ s/^[ \t\n]+//;
    $value =~ s/[ \t\n]+$//;
    return $value;
}

sub powershell_encoded {
    require Encode;
    require MIME::Base64;
    my $bytes = Encode::encode('utf16LE', $_[0]);
    return MIME::Base64::encode_base64($bytes, '');
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
        $version_src !~ /^[0-9]+(?:\.[0-9\.]+)*$/ || $version_dst !~ /^[0-9x]+(?:\.[0-9x]+)*$/) {
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

sub change_seconds {
    my %options = @_;
    my ($str, $str_append) = ('', '');
    my $periods = [
        { unit => 'y', value => 31556926 },
        { unit => 'M', value => 2629743 },
        { unit => 'w', value => 604800 },
        { unit => 'd', value => 86400 },
        { unit => 'h', value => 3600 },
        { unit => 'm', value => 60 },
        { unit => 's', value => 1 },
    ];
    my %values = ('y' => 1, 'M' => 2, 'w' => 3, 'd' => 4, 'h' => 5, 'm' => 6, 's' => 7);

    foreach (@$periods) {
        next if (defined($options{start}) && $values{$_->{unit}} < $values{$options{start}});
        my $count = int($options{value} / $_->{value});

        next if ($count == 0);
        $str .= $str_append . $count . $_->{unit};
        $options{value} = $options{value} % $_->{value};
        $str_append = ' ';
    }

    if ($str eq '') {
        $str = $options{value};
        $str .= $options{start} if (defined($options{start}));
    }
    return $str;
}

sub scale_bytesbit {
    my (%options) = @_;
    
    my $base = 1024;
    if (defined($options{dst_unit}) && defined($options{src_unit})) {
        $options{value} *= 8 if ($options{dst_unit} =~ /b/ && $options{src_unit} =~ /B/);
        $options{value} /= 8 if ($options{dst_unit} =~ /B/ && $options{src_unit} =~ /b/);
        if ($options{dst_unit} =~ /b/) {
            $base = 1000;
        }
    }
        
    my %expo = ('' => 0, k => 1, m => 2, g => 3, t => 4, p => 5, e => 6);
    my ($src_expo, $dst_expo) = (0, 0);
    $src_expo = $expo{lc($options{src_quantity})} if (defined($options{src_quantity}) && $options{src_quantity} =~ /[kmgtpe]/i);
    if ($options{dst_unit} eq 'auto') {
        my @auto = ('', 'k', 'm', 'g', 't', 'p', 'e');
        my $i = defined($options{src_quantity}) ? $expo{$options{src_quantity}} : 0;
        for (; $i < scalar(@auto); $i++) {
            last if ($options{value} < $base);
            $options{value} = $options{value} / $base;
        }

        return ($options{value}, $auto[$i], $options{src_unit});
    } elsif (defined($options{dst_quantity}) && ($options{dst_quantity} eq '' || $options{dst_quantity} =~ /[kmgtpe]/i )) {
        my $dst_expo = $expo{lc($options{dst_quantity})};
        if ($dst_expo - $src_expo > 0) {
            $options{value} = $options{value} / ($base ** ($dst_expo - $src_expo));
        } elsif ($dst_expo - $src_expo < 0) {
            $options{value} = $options{value} * ($base ** (($dst_expo - $src_expo) * -1));
        }
    }
    
    return $options{value};
}

sub convert_bytes {
    my (%options) = @_;

    my %expo = (k => 1, m => 2, g => 3, t => 4, p => 5);
    my ($value, $unit) = ($options{value}, $options{unit});
    if (defined($options{pattern})) {
        return undef if ($value !~ /$options{pattern}/);
        $value = $1;
        $unit = $2;
    }
    
    my $base = defined($options{network}) ? 1000 : 1024;    
    if ($unit =~ /([kmgtp])i?b/i) {
        $value = $value * ($base ** $expo{lc($1)});
    }

    return $value;
}

sub convert_fahrenheit {
    my (%options) = @_;

    return ($options{value} - 32) / 1.8;
}

sub expand_exponential {
    my (%options) = @_;
    
    return $options{value} unless ($options{value} =~ /^(.*)e([-+]?)(.*)$/);
    my ($num, $sign, $exp) = ($1, $2, $3);
    my $sig = $sign eq '-' ? "." . ($exp - 1 + length $num) : '';
    return sprintf("%${sig}f", $options{value});
}

sub parse_threshold {
    my (%options) = @_;

    my $perf = trim($options{threshold});
    my $perf_result = { arobase => 0, infinite_neg => 0, infinite_pos => 0, start => '', end => '' };

    my $global_status = 1;    
    if ($perf =~ /^(\@?)((?:~|(?:\+|-)?\d+(?:[\.,]\d+)?(?:[KMGTPE][bB])?|):)?((?:\+|-)?\d+(?:[\.,]\d+)?(?:[KMGTPE][bB])?)?$/) {
        $perf_result->{start} = $2 if (defined($2));
        $perf_result->{end} = $3 if (defined($3));
        $perf_result->{arobase} = 1 if (defined($1) && $1 eq '@');
        $perf_result->{start} =~ s/[\+:]//g;
        $perf_result->{end} =~ s/\+//;
        if ($perf_result->{start} =~ s/([KMGTPE])([bB])//) {
            $perf_result->{start} = scale_bytesbit(
                value => $perf_result->{start},
                src_unit => $2, dst_unit => $2,
                src_quantity => $1, dst_quantity => '',
            );
        }
        if ($perf_result->{end} =~ s/([KMGTPE])([bB])//) {
            $perf_result->{end} = scale_bytesbit(
                value => $perf_result->{end},
                src_unit => $2, dst_unit => $2,
                src_quantity => $1, dst_quantity => '',
            );
        }
        if ($perf_result->{end} eq '') {
            $perf_result->{end} = 1e500;
            $perf_result->{infinite_pos} = 1;
        }
        $perf_result->{start} = 0 if ($perf_result->{start} eq '');      
        $perf_result->{start} =~ s/,/\./;
        $perf_result->{end} =~ s/,/\./;
        
        if ($perf_result->{start} eq '~') {
            $perf_result->{start} = -1e500;
            $perf_result->{infinite_neg} = 1;
        }
    } else {
        $global_status = 0;
    }

    return ($global_status, $perf_result);
}

sub get_threshold_litteral {
    my (%options) = @_;
    
    my $perf_output = ($options{arobase} == 1 ? '@' : '') . 
                      (($options{infinite_neg} == 0) ? $options{start} : '~') . 
                      ':' . 
                      (($options{infinite_pos} == 0) ? $options{end} : '');
    return $perf_output;
}

sub set_timezone {
    my (%options) = @_;
    
    return {} if (!defined($options{name}) || $options{name} eq '');
     
    centreon::plugins::misc::mymodule_load(
        output => $options{output}, module => 'DateTime::TimeZone',
        error_msg => "Cannot load module 'DateTime::TimeZone'."
    );
    if (DateTime::TimeZone->is_valid_name($options{name})) {
        return { time_zone => DateTime::TimeZone->new(name => $options{name}) };
    }
    
    # try to manage syntax (:Pacific/Noumea for example)
    if ($options{name} =~ /^:(.*)$/ && DateTime::TimeZone->is_valid_name($1)) {
        return { time_zone => DateTime::TimeZone->new(name => $1) };
    }

    return {};
}

sub uniq {
    my %seen;

    return grep { !$seen{$_}++ } @_;
}

1;

__END__
