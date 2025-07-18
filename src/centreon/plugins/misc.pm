#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use JSON::XS;

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

        if (defined($options{options}->{ssh_option_eol})) {
            foreach (@{$options{options}->{ssh_option_eol}}) {
                if (/^(.*?)(?:=(.*))?$/) {
                    push @$args, $1 if (defined($1));
                    push @$args, $2 if (defined($2));
                }
            }
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
        $cmd .= $options{command} if (defined($options{command}));
        $cmd .= ' ' . $options{command_options} if (defined($options{command_options}));

        if (defined($options{no_shell_interpretation}) and $options{no_shell_interpretation} ne '') {
            my @args = split(' ',$cmd);
            ($lerror, $stdout, $exit_code) = backtick(
                command         => $args[0],
                arguments       => [@args[1.. $#args]],
                timeout         => $options{options}->{timeout},
                wait_exit       => $wait_exit,
                redirect_stderr => $redirect_stderr
            );
        }
        else {
            ($lerror, $stdout, $exit_code) = backtick(
                command         => $cmd,
                timeout         => $options{options}->{timeout},
                wait_exit       => $wait_exit,
                redirect_stderr => $redirect_stderr
            );
        }
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

sub is_empty {
    my $value = shift;
    if (!defined($value) or $value eq '') {
        return 1;
    }
    return 0;
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
    my $sign = '';
    if ($options{value} < 0) {
        $sign = '-';
        $options{value} = abs($options{value});
    }
    
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
    return $sign . $str;
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

sub alert_triggered {
    my (%options) = @_;

    my ($rv_warn, $warning) = parse_threshold(threshold => $options{warning});
    my ($rv_crit, $critical) = parse_threshold(threshold => $options{critical});

    foreach ([$rv_warn, $warning], [$rv_crit, $critical]) {
        next if ($_->[0] == 0);

        if ($_->[1]->{arobase} == 0 && ($options{value} < $_->[1]->{start} || $options{value} > $_->[1]->{end})) {
            return 1;
        } elsif ($_->[1]->{arobase}  == 1 && ($options{value} >= $_->[1]->{start} && $options{value} <= $_->[1]->{end})) {
            return 1;
        }
    }

    return 0;
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

sub eval_ssl_options {
    my (%options) = @_;

    my $ssl_context = {};
    return $ssl_context if (!defined($options{ssl_opt}));
    
    my ($rv) = centreon::plugins::misc::mymodule_load(
        output => $options{output}, module => 'Safe',
        no_quit => 1
    );
    centreon::plugins::misc::mymodule_load(
        output => $options{output}, module => 'IO::Socket::SSL',
        no_quit => 1
    );

    my $safe;
    if ($rv == 0) {
        $safe = Safe->new();
        $safe->permit_only(':base_core', 'rv2gv', 'padany');
        $safe->share('$values');
        $safe->share('$assign_var');
        $safe->share_from('IO::Socket::SSL', [
            'SSL_VERIFY_NONE', 'SSL_VERIFY_PEER', 'SSL_VERIFY_FAIL_IF_NO_PEER_CERT', 'SSL_VERIFY_CLIENT_ONCE',
            'SSL_RECEIVED_SHUTDOWN', 'SSL_SENT_SHUTDOWN',
            'SSL_OCSP_NO_STAPLE', 'SSL_OCSP_MUST_STAPLE', 'SSL_OCSP_FAIL_HARD', 'SSL_OCSP_FULL_CHAIN', 'SSL_OCSP_TRY_STAPLE'
        ]);
    }
    
    foreach (@{$options{ssl_opt}}) {
        if (/(SSL_[A-Za-z_]+)\s+=>\s*(\S+)/) {
            my ($label, $eval) = ($1, $2);

            our $assign_var;
            if (defined($safe)) {
                $safe->reval("\$assign_var = $eval", 1);
                if ($@) {
                    die 'Unsafe code evaluation: ' . $@;
                }
            } else {
                eval "\$assign_var = $eval";
            }

            $ssl_context->{$label} = $assign_var;
        }
    }

    return $ssl_context;
}

sub slurp_file {
    my (%options) = @_;

    my $content = do {
        local $/ = undef;
        if (!open my $fh, '<', $options{file}) {
            $options{output}->add_option_msg(short_msg => "Could not open file $options{file}: $!");
            $options{output}->option_exit();
        }
        <$fh>;
    };

    return $content;
}

sub sanitize_command_param {
    my (%options) = @_;

    return if (!defined($options{value}));

    $options{value} =~ s/[`;!&|]//g;
    return $options{value};
}

my $security_file = '/etc/centreon-plugins/security.json';
my $whitelist_file = '/etc/centreon-plugins/whitelist.json';
if ($^O eq 'MSWin32') {
    $security_file = 'C:/Program Files/centreon-plugins/security.json';
    $whitelist_file = 'C:/Program Files/centreon-plugins/whitelist.json';
}

sub check_security_command {
    my (%options) = @_;

    return 0 if (!(
        (defined($options{command}) && $options{command} ne '') ||
        (defined($options{command_options}) && $options{command_options} ne '') ||
        (defined($options{command_path}) && $options{command_path} ne ''))
    );

    return 0 if (! -r "$security_file" || -z "$security_file");

    my $content = slurp_file(output => $options{output}, file => $security_file);

    my $security;
    eval {
        $security = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $options{output}->add_option_msg(short_msg => 'Cannot decode security file content');
        $options{output}->option_exit();
    }

    if (defined($security->{block_command_overload}) && $security->{block_command_overload} == 1) {
        $options{output}->add_option_msg(short_msg => 'Cannot overload command (security)');
        $options{output}->option_exit();
    }

    return 0;
}

sub check_security_whitelist {
    my (%options) = @_;

    my $command = $options{command};
    $command = $options{command_path} . '/' . $options{command} if (defined($options{command_path}) && $options{command_path} ne '');
    $command .= ' ' . $options{command_options} if (defined($options{command_options}) && $options{command_options} ne '');

    return 0 if (! -r "$security_file" || -z "$security_file");

    my $content = slurp_file(output => $options{output}, file => $security_file);

    my $security;
    eval {
        $security = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $options{output}->add_option_msg(short_msg => 'Cannot decode security file content');
        $options{output}->option_exit();
    }

    return 0 if (!defined($security->{whitelist_enabled}) || $security->{whitelist_enabled} !~ /^(?:1|true)$/i);

    if (! -r "$whitelist_file") {
        $options{output}->add_option_msg(short_msg => 'Cannot read whitelist security file content');
        $options{output}->option_exit();
    }

    if (-z "$whitelist_file") {
        $options{output}->add_option_msg(short_msg => 'Cannot execute command (security)');
        $options{output}->option_exit();
    }

    $content = slurp_file(output => $options{output}, file => $whitelist_file);

    my $whitelist;
    eval {
        $whitelist = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $options{output}->add_option_msg(short_msg => 'Cannot decode whitelist security file content');
        $options{output}->option_exit();
    }

    my $matched = 0;
    foreach (@$whitelist) {
        if ($command =~ /$_/) {
            $matched = 1;
            last;
        }
    }

    if ($matched == 0) {
        $options{output}->add_option_msg(short_msg => 'Cannot execute command (security)');
        $options{output}->option_exit();
    }

    return 0;
}

sub json_decode {
    my ($content, %options) = @_;

    $content =~ s/\r//mg;
    my $object;

    my $decoder = JSON::XS->new->utf8;
    # this option
    if ($options{booleans_as_strings}) {
        # boolean_values() is not available on old versions of JSON::XS (Alma 8 still provides v3.04)
        if (JSON::XS->can('boolean_values')) {
            $decoder = $decoder->boolean_values("false", "true");
        } else {
            # if boolean_values is not available, perform a dirty substitution of booleans
            $content =~ s/"(\w+)"\s*:\s*(true|false)(\s*,?)/"$1": "$2"$3/gm;
        }
    }

    eval {
        $object = $decoder->decode($content);
    };
    if ($@) {
        print STDERR "Cannot decode JSON string: $@" . "\n";
        return undef;
    }
    return $object;
}

sub json_encode {
    my ($object) = @_;

    $object =~ s/\r//mg;
    my $encoded;
    eval {
        $encoded = encode_json($object);
    };
    if ($@) {
        print STDERR 'Cannot encode object to JSON. Error message: ' . $@;
        return undef;
    }

    return $encoded;
}

# function to assess if a string has to be excluded given an include regexp and an exclude regexp
sub is_excluded {
    my ($string, $include_regexp, $exclude_regexp) = @_;
    return 1 unless defined($string);
    return 1 if (defined($exclude_regexp) && $exclude_regexp ne '' && $string =~ /$exclude_regexp/);
    return 0 if (!defined($include_regexp) || $include_regexp eq '' || $string =~ /$include_regexp/);

    return 1;
}

1;

__END__

=head1 NAME

centreon::plugins::misc - A collection of miscellaneous utility functions for Centreon plugins.

=head1 SYNOPSIS

    use centreon::plugins::misc;

    my $result = centreon::plugins::misc::execute(
        command => 'ls',
        command_options => '-l'
    );

=head1 DESCRIPTION

The `centreon::plugins::misc` module provides a variety of utility functions that can be used in Centreon plugins. These functions include command execution, string manipulation, file handling, and more.

=head1 METHODS

=head2 execute

    my $result = centreon::plugins::misc::execute(%options);

Executes a command and returns the result.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<command> - The command to execute.

=item * C<command_options> - Options for the command.

=item * C<timeout> - Timeout for the command execution.

=back

=back

=head2 windows_execute

    my ($stdout, $exit_code) = centreon::plugins::misc::windows_execute(%options);

Executes a command on Windows and returns the output and exit code.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<command> - The command to execute.

=item * C<command_options> - Options for the command.

=item * C<timeout> - Timeout for the command execution.

=back

=back

=head2 unix_execute

    my $stdout = centreon::plugins::misc::unix_execute(%options);

Executes a command on Unix and returns the output.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<command> - The command to execute.

=item * C<command_options> - Options for the command.

=item * C<timeout> - Timeout for the command execution.

=item * C<wait_exit> - bool.

=item * C<redirect_stderr> - bool.

=item * C<sudo> - bool prepend sudo to the command executed.

=item * C<no_shell_interpretation> - bool don't use sh interpolation on command executed


=back

=back

=head2 mymodule_load

    my $result = centreon::plugins::misc::mymodule_load(%options);

Loads a Perl module dynamically.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<module> - The module to load.

=item * C<error_msg> - Error message to display if the module cannot be loaded.

=back

=back

=head2 backtick

    my ($status, $output, $exit_code) = centreon::plugins::misc::backtick(%options);

Executes a command using backticks and returns the status, output, and exit code.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<command> - The command to execute.

=item * C<arguments> - Arguments for the command.

=item * C<timeout> - Timeout for the command execution.

=back

=back

=head2 is_empty

    my $is_empty = centreon::plugins::misc::is_empty($value);

Checks if a value is empty.

=over 4

=item * C<$value> - The value to check.

=back

=head2 trim

    my $trimmed_value = centreon::plugins::misc::trim($value);

Trims whitespace from a string.

=over 4

=item * C<$value> - The string to trim.

=back

=head2 powershell_encoded

    my $encoded = centreon::plugins::misc::powershell_encoded($value);

Encodes a string for use in PowerShell.

=over 4

=item * C<$value> - The string to encode.

=back

=head2 powershell_escape

    my $escaped = centreon::plugins::misc::powershell_escape($value);

Escapes special characters in a string for use in PowerShell.

=over 4

=item * C<$value> - The string to escape.

=back

=head2 minimal_version

    my $is_minimal = centreon::plugins::misc::minimal_version($version_src, $version_dst);

Checks if a version is at least a specified version.

=over 4

=item * C<$version_src> - The source version.

=item * C<$version_dst> - The destination version.

=back

=head2 change_seconds

    my $formatted_time = centreon::plugins::misc::change_seconds(%options);

Converts seconds into a human-readable format.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<value> - The number of seconds.

=item * C<start> - The starting unit.

=back

=back

=head2 scale_bytesbit

    my $scaled_value = centreon::plugins::misc::scale_bytesbit(%options);

Scales a value between bytes and bits.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<value> - The value to scale.

=item * C<src_unit> - The source unit.

=item * C<dst_unit> - The destination unit.

=back

=back

=head2 convert_bytes

    my $bytes = centreon::plugins::misc::convert_bytes(%options);

Converts a value to bytes.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<value> - The value to convert.

=item * C<unit> - The unit of the value.

=back

=back

=head2 convert_fahrenheit

    my $celsius = centreon::plugins::misc::convert_fahrenheit(%options);

Converts a temperature from Fahrenheit to Celsius.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<value> - The temperature in Fahrenheit.

=back

=back

=head2 expand_exponential

    my $expanded = centreon::plugins::misc::expand_exponential(%options);

Expands an exponential value to its full form.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<value> - The exponential value.

=back

=back

=head2 alert_triggered

    my $is_triggered = centreon::plugins::misc::alert_triggered(%options);

Checks if an alert is triggered based on thresholds.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<value> - The value to check.

=item * C<warning> - The warning threshold.

=item * C<critical> - The critical threshold.

=back

=back

=head2 parse_threshold

    my ($status, $threshold) = centreon::plugins::misc::parse_threshold(%options);

Parses a threshold string.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<threshold> - The threshold string.

=back

=back

=head2 get_threshold_litteral

    my $threshold_str = centreon::plugins::misc::get_threshold_litteral(%options);

Returns the literal representation of a threshold.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<arobase> - Indicates if the threshold is inclusive.

=item * C<start> - The start of the threshold.

=item * C<end> - The end of the threshold.

=back

=back

=head2 set_timezone

    my $timezone = centreon::plugins::misc::set_timezone(%options);

Sets the timezone.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<name> - The name of the timezone.

=back

=back

=head2 uniq

    my @unique = centreon::plugins::misc::uniq(@values);

Returns a list of unique values.

=over 4

=item * C<@values> - The list of values.

=back

=head2 eval_ssl_options

    my $ssl_context = centreon::plugins::misc::eval_ssl_options(%options);

Evaluates SSL options.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<ssl_opt> - The SSL options.

=back

=back

=head2 slurp_file

    my $content = centreon::plugins::misc::slurp_file(%options);

Reads the content of a file.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<file> - The file to read.

=back

=back

=head2 sanitize_command_param

    my $sanitized = centreon::plugins::misc::sanitize_command_param(%options);

Sanitizes a command parameter.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<value> - The value to sanitize.

=back

=back

=head2 check_security_command

    my $status = centreon::plugins::misc::check_security_command(%options);

Checks the security of a command.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<command> - The command to check.

=item * C<command_options> - Options for the command.

=back

=back

=head2 check_security_whitelist

    my $status = centreon::plugins::misc::check_security_whitelist(%options);

Checks if a command is in the security whitelist.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<command> - The command to check.

=item * C<command_options> - Options for the command.

=back

=back

=head2 json_decode

    my $decoded = centreon::plugins::misc::json_decode($content, %options);

Decodes a JSON string.

=over 4

=item * C<$content> - The JSON string to decode and transform into an object.

=item * C<%options> - Options passed to the function.

=over 4

=item * C<booleans_as_strings> - Defines whether booleans must be converted to C<true>/C<false> strings instead of
JSON:::PP::Boolean values. C<1> => strings, C<0> => booleans.

=back

=back

=head2 json_encode

    my $encoded = centreon::plugins::misc::json_encode($object);

Encodes an object to a JSON string.

=over 4

=item * C<$object> - The object to encode.

=back

=head2 is_excluded

    my $excluded = is_excluded($string, $include_regexp, $exclude_regexp);

Determines whether a string should be excluded based on include and exclude regular expressions.

=over 4

=item * C<$string> - The string to evaluate. If undefined, the function returns 1 (excluded).

=item * C<$include_regexp> - A regular expression to include the string.

=item * C<$exclude_regexp> - A regular expression to exclude the string. If defined and matches the string, the function returns 1 (excluded).

=back

Returns 1 if the string is excluded, 0 if it is included.
The string is excluded if $exclude_regexp is defined and matches the string, or if $include_regexp is defined and does
not match the string. The string will also be excluded if it is undefined.

=cut

=head1 AUTHOR

Centreon

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
