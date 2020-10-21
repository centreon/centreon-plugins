#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package database::postgres::psqlcmd;

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class psqlcmd: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class psqlcmd: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'psql-cmd:s'        => { name => 'psql_cmd', default => '/usr/bin/psql' },
            'host:s@'           => { name => 'host' },
            'port:s@'           => { name => 'port' },
            'username:s@'       => { name => 'username' },
            'password:s@'       => { name => 'password' },
            'dbname:s@'         => { name => 'dbname' },
            'sql-errors-exit:s' => { name => 'sql_errors_exit', default => 'unknown' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'PSQLCMD OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{sqlmode_name} = $options{sqlmode_name};
    $self->{args} = undef;
    $self->{stdout} = undef;
    $self->{columns} = undef;
    $self->{version} = undef;

    $self->{host} = undef;
    $self->{port} = undef;
    $self->{username} = undef;
    $self->{password} = undef;
    $self->{dbname} = undef;

    $self->{record_separator} = '----====----';
    $self->{field_separator} = '-====-';

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

    $self->{host} = (defined($self->{option_results}->{host})) ? shift(@{$self->{option_results}->{host}}) : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : undef;
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : undef;
    $self->{dbname} = (defined($self->{option_results}->{dbname})) ? shift(@{$self->{option_results}->{dbname}}) : undef;
    $self->{sql_errors_exit} = $self->{option_results}->{sql_errors_exit};
    $self->{psql_cmd} = $self->{option_results}->{psql_cmd};

    # If we want a command line: password with variable "PGPASSWORD".
    #  psql -d template1 -A -R "----====-----" -F "-====-" -c "select code from films"
 
    if (!defined($self->{host}) || $self->{host} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify host argument.");
        $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
    }

    $self->{args} = ['-A', '-R', $self->{record_separator}, '-F', $self->{field_separator}, '--pset', 'footer=off', '-h', $self->{host}];
    if (defined($self->{port})) {
        push @{$self->{args}}, "-p", $self->{port};
    }
    if (defined($self->{username})) {
        push @{$self->{args}}, "-U", $self->{username};
    }
    if (defined($self->{password}) && $self->{password} ne '') {
        $ENV{PGPASSWORD} = $self->{password};
    }
    if (defined($self->{dbname}) && $self->{dbname} ne '') {
        push @{$self->{args}}, "-d", $self->{dbname};
    }

    if (scalar(@{$self->{option_results}->{host}}) == 0) {
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

    my $msg = $self->{host};
    if (defined($self->{port})) {
        $msg .= ":" . $self->{port};
    }
    return $msg;
}

sub get_unique_id4save {
    my ($self, %options) = @_;

    my $msg = $self->{host};
    if (defined($self->{port})) {
        $msg .= ":" . $self->{port};
    }
    return md5_hex($msg);
}

sub quote {
    my $self = shift;

    return undef;
}

sub command_execution {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        command => $self->{psql_cmd},
        command_options =>  join(' ', @{$self->{args}}) . ' -c "' . $options{request} . '"',
        wait_exit => 1,
        redirect_stderr => 1,
        no_quit => 1,
        options => { timeout => 30 }
    );

    return ($exit_code, $stdout); 
}

sub disconnect {}

# Connection initializer
sub connect {
    my ($self, %options) = @_;
    my $dontquit = (defined($options{dontquit}) && $options{dontquit} == 1) ? 1 : 0;
    
    (my $exit_code, $self->{stdout}) = $self->command_execution(request => "SELECT current_setting('server_version') as version");
    if ($exit_code != 0) {
        if ($dontquit == 0) {
            $self->{output}->add_option_msg(short_msg => "Cannot connect: " . $self->{stdout});
            $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
        }
        return (-1, "Cannot connect: " . $self->{stdout});
    }
    
    my $row = $self->fetchrow_hashref();
    $self->{version} = $row->{version};

    return 0;
}

sub fetchall_arrayref {
    my ($self, %options) = @_;
    my $array_ref = [];
    
    if (!defined($self->{columns})) {
        $self->{stdout} =~ s/^(.*?)\Q$self->{record_separator}\E//ms;
        @{$self->{columns}} = split(/\Q$self->{field_separator}\E/, $1);
    }
    foreach (split /\Q$self->{record_separator}\E/, $self->{stdout}) {
        push @$array_ref, [split(/\Q$self->{field_separator}\E/, $_)];
    }
    
    return $array_ref;
}

sub fetchall_hashref {
    my ($self, %options) = @_;
    my $array_ref = [];
    my $array_result = undef;

    if (!defined($self->{columns})) {
        $self->{stdout} =~ s/^(.*?)\Q$self->{record_separator}\E//ms;
        @{$self->{columns}} = split(/\Q$self->{field_separator}\E/, $1);
    }
    foreach (split /\Q$self->{record_separator}\E/, $self->{stdout}) {
        $array_result = {};
        my @values = split(/\Q$self->{field_separator}\E/, $_);
        for (my $i = 0; $i < scalar(@values); $i++) {
            my $value = $values[$i];
            $array_result->{$self->{columns}[$i]} = $value;
        }
        push @$array_ref, $array_result;
    }
    return $array_ref;
}

sub fetchrow_array {
    my ($self, %options) = @_;
    my @array_result = ();
    
    if (!defined($self->{columns})) {
        $self->{stdout} =~ s/^(.*?)\Q$self->{record_separator}\E//ms;
        @{$self->{columns}} = split(/\Q$self->{field_separator}\E/, $1);
    }
    if (($self->{stdout} =~ s/^(.*?)(\Q$self->{record_separator}\E|\Z)//ms)) {
        push @array_result, split(/\Q$self->{field_separator}\E/, $1);
    }
    
    return @array_result;
}

sub fetchrow_hashref {
    my ($self, %options) = @_;
    my $array_result = undef;
    
    if (!defined($self->{columns})) {
        $self->{stdout} =~ s/^(.*?)\Q$self->{record_separator}\E//ms;
        @{$self->{columns}} = split(/\Q$self->{field_separator}\E/, $1);
    }
    if ($self->{stdout} ne '' && $self->{stdout} =~ s/^(.*?)(\Q$self->{record_separator}\E|\Z)//ms) {
        $array_result = {};
        my @values = split(/\Q$self->{field_separator}\E/, $1);
        for (my $i = 0; $i < scalar(@values); $i++) {
            my $value = $values[$i];
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
        $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
    }

}

1;

__END__

=head1 NAME

psqlcmd global

=head1 SYNOPSIS

psqlcmd class

=head1 PSQLCMD OPTIONS

=over 8

=item B<--psql-cmd>

postgres command (Default: '/usr/bin/psql').

=item B<--host>

Database hostname.

=item B<--port>

Database port.

=item B<--dbname>

Database name to connect (default: postgres).

=item B<--username>

Database username.

=item B<--password>

Database password.

=item B<--sql-errors-exit>

Exit code for DB Errors (default: unknown)

=back

=head1 DESCRIPTION

B<>.

=cut
