#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package database::oracle::sqlpluscmd;

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);
use File::Temp qw(tempfile);
use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer
    
    if (!defined($options{output})) {
        print "Class sqlpluscmd: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class sqlpluscmd: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
                'sqlplus-cmd:s'          => { name => 'sqlplus_cmd'},
                'oracle-home:s'          => { name => 'oracle_home' },
                'tnsadmin-home:s'        => { name => 'tnsadmin_home' },
                'tnsnames-sid:s'         => { name => 'tnsnames_sid'},
                'tnsnames-servicename:s' => { name => 'tnsnames_servicename'},
                'username:s'             => { name => 'username' },
                'password:s'             => { name => 'password' },
                'local-connexion'        => { name => 'local_connexion', default => 0 }, 
                'sysdba'                 => { name => 'sysdba', default => 0 }, 
                'sql-errors-exit:s'      => { name => 'sql_errors_exit', default => 'unknown' },
                'tempdir:s'              => { name => 'tempdir', default => '/tmp' }
            }
        );
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'sqlpluscmd OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{sqlmode_name} = $options{sqlmode_name};
    $self->{args} = undef;
    $self->{stdout} = undef;
    $self->{columns} = undef;
    $self->{version} = undef;
    
    $self->{sid} = undef;
    $self->{oracle_home} = undef;
    $self->{tnsadmin_home} = undef;
    $self->{local_connexion} = undef;
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{sqlmode_name}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    $self->{sid} = defined($self->{option_results}->{sid}[0]) ? $self->{option_results}->{sid}[0] : $self->{option_results}->{tnsnames_sid};
    $self->{service_name} = defined($self->{option_results}->{service_name}[0]) ? $self->{option_results}->{service_name}[0] : $self->{option_results}->{tnsnames_servicename};
    $self->{oracle_home} = defined($self->{option_results}->{oracle_home}) ? $self->{option_results}->{oracle_home} : $ENV{'ORACLE_HOME'};
    $self->{tnsadmin_home} = defined($self->{option_results}->{tnsadmin_home}) ? $self->{option_results}->{tnsadmin_home} : $ENV{'TNSADMIN'};
    $self->{local_connexion} = $self->{option_results}->{local_connexion};
    $self->{sqlplus_cmd} = $self->{option_results}->{sqlplus_cmd};
    $self->{container} = defined($self->{option_results}->{container}[0]) ? $self->{option_results}->{container}[0] : undef;
        
    $self->{output}->output_add(long_msg => "*** DEBUG MODE****\n", debug => 1);
    $self->{output}->output_add(long_msg => Data::Dumper::Dumper($self->{option_results}), debug => 1);
 
    if ((!defined($self->{sid}) || $self->{sid} eq '') &&
        (!defined($self->{service_name}) || $self->{service_name} eq '')) {
        $self->{output}->add_option_msg(short_msg => "Need to specify sid or servicename argument.");
        $self->{output}->option_exit(exit_litteral => $self->{option_results}->{sql_errors_exit});
    }
    
    # check the ORACLE_HOME variable
    if (!defined($self->{oracle_home}) || $self->{oracle_home} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify oracle-home argument.");
        $self->{output}->option_exit(exit_litteral => $self->{option_results}->{sql_errors_exit});
    }
    
    # construct the TNSADMIN variable if not available
    if(!defined($self->{tnsadmin_home})) {
        $self->{tnsadmin_home} = $self->{oracle_home} . "/network/admin";
    }
    
    # check the SQLPLUS command to use
    if(!$self->{sqlplus_cmd}) {
        $self->{sqlplus_cmd} = $self->{oracle_home} . "/bin/sqlplus";
    }
    
    $self->{args} = ['-L', '-S'];
    my $connection_string = "";
    if ($self->{option_results}->{sysdba} == 1) {
        $self->{output}->output_add(long_msg => "*** SYDBA MODE****", debug => 1);
        $connection_string="/ as sysdba";
        $self->{local_connexion} = 1;
    } elsif (defined($self->{option_results}->{username}) && defined($self->{option_results}->{password})) {
        $connection_string=$self->{option_results}->{username} . "/" . $self->{option_results}->{password};
    } else {
        $self->{output}->add_option_msg(short_msg => "Need to specify username/password arguments or sysdba option.");
        $self->{output}->option_exit(exit_litteral => $self->{option_results}->{sql_errors_exit});
    }

    if ($self->{local_connexion} == 0) {
        if (defined($self->{option_results}->{hostname})) {
            my $port = defined($self->{option_results}->{port}) ? $self->{option_results}->{port}[0] : 1521;
            $connection_string .= "\@//" . $self->{option_results}->{hostname}[0] . ':' . $port . '/' . ((defined($self->{sid}) && $self->{sid} ne '') ? $self->{sid} : $self->{service_name});
        } else {
            $connection_string .= "\@" . ((defined($self->{sid}) && $self->{sid} ne '') ? $self->{sid} : $self->{service_name});
        }
    } else {
        $self->{output}->output_add(long_msg => "*** LOCAL CONNEXION MODE****", debug => 1);
        if (defined($self->{sid}) && $self->{sid} ne '') {
            $ENV{ORACLE_SID} = $self->{sid};
        } else {
            $ENV{TWO_TASK} = '/' . $self->{service_name};
        }
    }
    
    # register a false data_source to be compliant with tnsping mode
    if (defined($self->{sid}) && $self->{sid} ne '') {
        $self->{data_source} = "sid=" . $self->{sid};
    } else {
        $self->{data_source} = "service_name=" . $self->{service_name};
    }
    
    push @{$self->{args}}, $connection_string;
    
    # set oracle env variable
    $ENV{ORACLE_HOME} = $self->{oracle_home};
    $ENV{TNSADMIN} = $self->{tnsadmin_home};
    
    if (defined($self->{option_results}->{sid})) {
        return 0;
    }
    return 1;
}

sub is_version_minimum {
    my ($self, %options) = @_;
    # $options{version} = string version to check
    
    my @version_src = split /\./, $self->{version};
    my @versions = split /\./, $options{version};
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

sub get_id {
    my ($self, %options) = @_;
    
    my $msg = $self->{sid};
    return $msg;
}


sub get_unique_id4save {
    my ($self, %options) = @_;

    my $msg = $self->{sid};
    return md5_hex($msg);
}

sub quote {
    my $self = shift;

    return undef;
}

sub command_execution {
    my ($self, %options) = @_;
    
    my ($fh, $tempfile) = tempfile(DIR => $self->{option_results}->{tempdir}, SUFFIX => ".sql", UNLINK => 1);
    print $fh "set echo off
-- set heading off
set feedback off
set linesize 16000
set pagesize 50000
set colsep '#&!#'
set numwidth 15
$options{request};
exit;";
    
    $self->{output}->output_add(long_msg => "*** COMMAND: " . $self->{sqlplus_cmd} . ' ' . join(' ', (@{$self->{args}}, '@', $tempfile)), debug => 1);
    $self->{output}->output_add(long_msg => "*** REQUEST: " . $options{request}, debug => 1);
    my ($lerror, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                                 command => $self->{sqlplus_cmd},
                                                 arguments =>  [@{$self->{args}}, '@', $tempfile],
                                                 timeout => 30,
                                                 wait_exit => 1,
                                                 redirect_stderr => 1
                                                 );
    $self->{output}->output_add(long_msg => "REQ. STDOUT: '$stdout'", debug => 1);
    $self->{output}->output_add(long_msg => "REQ. EXIT_CODE: $exit_code", debug => 1);
    
    # search oracle error lines
    $exit_code = -1 if($stdout =~ /^(ORA\-\d+|TNS\-\d+|SP\d\-\d+)/);
    
    if ($exit_code <= -1000) {
        if ($exit_code == -1000) {
            $self->{output}->output_add(severity => 'UNKNOWN', 
                                        short_msg => $stdout);
        }
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    return ($exit_code, $stdout); 
}

sub disconnect {}

# Connection initializer
sub connect {
    my ($self, %options) = @_;
    my $dontquit = (defined($options{dontquit}) && $options{dontquit} == 1) ? 1 : 0;

    (my $exit_code, $self->{stdout}) = $self->command_execution(request => "select version from v\$instance");
    if ($exit_code != 0) {
        if ($dontquit == 0) {
            $self->{output}->add_option_msg(short_msg => "Cannot connect: " . $self->{stdout});
            $self->{output}->option_exit(exit_litteral => $self->{option_results}->{sql_errors_exit});
        }
        return (-1, "Cannot connect: " . $self->{stdout});
    }
    
    $self->{version} = $self->fetchrow_array();
    $self->{output}->output_add(long_msg => "VERSION: " . $self->{version}, debug => 1);
    if (defined($self->{container}) and $self->{container} ne '') {
        $self->query(query => "alter session set container=$self->{container}");
    }
    return 0;
}

sub fetchall_arrayref {
    my ($self, %options) = @_;
    my $array_ref = [];
    
    if($self->{stdout} eq '') {
        $self->{output}->output_add(long_msg => "fetchall_arrayref: no data returned (no rows selected)", debug => 1);
        return $array_ref;
    }
    
    if (!defined($self->{columns})) {
        $self->{stdout} =~ s/^\s*\n(.*?)(\n|$)//;
        my $line = $1;
        $self->{output}->output_add(long_msg => "fetchall_arrayref COLUMNS: $line", debug => 1) if(defined($line));
        @{$self->{columns}} = split(/#&!#/, $line);
        map { s/^\s+|\s+$//g; } @{$self->{columns}};
        $self->{stdout} =~ s/[\-#&!]+(\n|$)//;
    }
    foreach (split /\n/, $self->{stdout}) {
        my $line = $_;
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/#&!#\s+/#&!#/g;
        $line =~ s/\s+#&!#/#&!#/g;
        
        $self->{output}->output_add(long_msg => "fetchall_arrayref VALUE: " . $line, debug => 1);
        push @$array_ref, [map({ s/\\n/\x{0a}/g; s/\\t/\x{09}/g; s/\\/\x{5c}/g; $_; } split(/#&!#/, $line))];
    }
    return $array_ref;
}

sub fetchrow_array {
    my ($self, %options) = @_;
    my @array_result = ();
    
    if($self->{stdout} eq '') {
        $self->{output}->output_add(long_msg => "fetchrow_array: no data returned (no rows selected)", debug => 1);
        return @array_result;
    }
    
    if (!defined($self->{columns})) {
        $self->{stdout} =~ s/^\s*\n(.*?)(\n|$)//;
        my $line = $1;
        $self->{output}->output_add(long_msg => "fetchrow_array COLUMNS: $line", debug => 1);
        @{$self->{columns}} = split(/#&!#/, $line);
        map { s/^\s+|\s+$//g; } @{$self->{columns}};
        $self->{stdout} =~ s/[\-#&!]+(\n|$)//;
    }
    $self->{output}->output_add(long_msg => "fetchrow_array STDOUT: '" . $self->{stdout} . "'", debug => 1);
    if (($self->{stdout} =~ s/^(.*?)(\n|$)//)) {
        my $line = $1;
        $self->{output}->output_add(long_msg => "fetchrow_array VALUE: '" . $line . "'", debug => 1);
        push @array_result, map({ s/\\n/\x{0a}/g; s/\\t/\x{09}/g; s/\\/\x{5c}/g; $_; } split(/#&!#/, $line));
        map { s/^\s+|\s+$//g; } @array_result;
        $self->{output}->output_add(long_msg => "ARRAY: " . Data::Dumper::Dumper(@array_result), debug => 1);
    }
    
    $self->{output}->output_add(long_msg => "RETURN: " . Data::Dumper::Dumper(@array_result), debug => 1);
    return scalar(@array_result) == 1 ? $array_result[0] : @array_result;
}

sub fetchrow_hashref {
    my ($self, %options) = @_;
    my $array_result = undef;
    
    if($self->{stdout} eq '') {
        $self->{output}->output_add(long_msg => "fetchrow_hashref: no data returned (no rows selected)", debug => 1);
        return $array_result;
    }
    
    if (!defined($self->{columns})) {
        $self->{stdout} =~ s/^\s*\n(.*?)(\n|$)//;
        my $line = $1;
        $self->{output}->output_add(long_msg => "fetchrow_hashref COLUMNS: $line", debug => 1);
        @{$self->{columns}} = split(/#&!#/, $line);
        map { s/^\s+|\s+$//g; } @{$self->{columns}};
        $self->{stdout} =~ s/[\-#&!]+(\n|$)//;
    }
    if ($self->{stdout} ne '' && $self->{stdout} =~ s/^(.*?)(\n|$)//) {
        my $line = $1;
        $self->{output}->output_add(long_msg => "fetchrow_hashref VALUE: " . $line, debug => 1);
        $array_result = {};
        my @values = split(/#&!#/, $line);
        for (my $i = 0; $i < scalar(@values); $i++) {
            my $value = $values[$i];
            $value =~ s/^\s+|\s+$//g;
            $value =~ s/\\n/\x{0a}/g;
            $value =~ s/\\t/\x{09}/g;
            $value =~ s/\\/\x{5c}/g;
            $self->{output}->output_add(long_msg => "fetchrow_hashref RES: '" . $self->{columns}[$i] . "' = '$value'", debug => 1);
            $array_result->{$self->{columns}[$i]} = $value;
        }
    }
    
    return $array_result;
}

sub query {
    my ($self, %options) = @_;
    
    $self->{columns} = undef;
    (my $exit_code, $self->{stdout}) = $self->command_execution(request => $options{query});
    if ($exit_code != 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot execute query: " . $self->{stdout});
        $self->{output}->option_exit(exit_litteral => $self->{option_results}->{sql_errors_exit});
    }
}

1;

__END__

=head1 NAME

sqlpluscmd global

=head1 SYNOPSIS

sqlpluscmd class

=head1 sqlpluscmd OPTIONS

=over 8

=item B<--sqlplus-cmd>

sqlplus command (Default: 'sqlplus').

=item B<--oracle-home>

Oracle Database Server Home.

=item B<--tnsadmin-home>

Oracle TNS Admin Home. Where to locate tnsnames.ora file (default: ${ORACLE_HOME}/network/admin)

=item B<--tnsnames-sid>

Oracle SID defined in tnsnames.ora.

=item B<--tnsnames-servicename>

Oracle Service Name defined in tnsnames.ora. 

=item B<--username>

Database username.

=item B<--password>

Database password.

=item B<--sysdba>

Use a sysdba connexion, need to be execute under the oracle local user on the server, and use a local connexion.

=item B<--local-connexion>

Use a local connexion, don't need listener.

=item B<--sql-errors-exit>

Exit code for DB Errors (default: unknown)

=back

=head1 DESCRIPTION

B<sql>.

=cut
