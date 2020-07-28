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

package centreon::plugins::dbi;

use strict;
use warnings;
use DBI;
use Digest::MD5 qw(md5_hex);

my %handlers = ( ALRM => {} );

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

    if (!defined($options{output})) {
        print "Class DBI: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class DBI: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'datasource:s@'      => { name => 'data_source' },
            'username:s@'        => { name => 'username' },
            'password:s@'        => { name => 'password' },
            'connect-options:s@' => { name => 'connect_options' },
            'sql-errors-exit:s'  => { name => 'sql_errors_exit', default => 'unknown' },
            'timeout:s'          => { name => 'timeout' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'DBI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{sqlmode_name} = $options{sqlmode_name};
    $self->{instance} = undef;
    $self->{statement_handle} = undef;
    $self->{version} = undef;
    
    $self->{data_source} = undef;
    $self->{username} = undef;
    $self->{password} = undef;
    $self->{connect_options} = undef;
    $self->{connect_options_hash} = {};
    
    # Sometimes, we need to set ENV
    $self->{env} = undef;
    
    return $self;
}

sub prepare_destroy {
    my ($self) = @_;

    %handlers = ();
}

sub set_signal_handlers {
    my $self = shift;

    $SIG{ALRM} = \&class_handle_ALRM;
    $handlers{ALRM}->{$self} = sub { $self->handle_ALRM() };
}

sub class_handle_ALRM {
    foreach (keys %{$handlers{ALRM}}) {
        &{$handlers{ALRM}->{$_}}();
    }
}

sub handle_ALRM {
    my $self = shift;

    $self->prepare_destroy();
    $self->disconnect();
    $self->{output}->output_add(
        severity => $self->{sql_errors_exit},
        short_msg => 'Timeout'
    );
    $self->{output}->display();
    $self->{output}->exit();
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
    
    $self->{data_source} = (defined($self->{option_results}->{data_source})) ? shift(@{$self->{option_results}->{data_source}}) : undef;
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : undef;
    $self->{connect_options} = (defined($self->{option_results}->{connect_options})) ? shift(@{$self->{option_results}->{connect_options}}) : undef;
    $self->{env} = (defined($self->{option_results}->{env})) ? shift(@{$self->{option_results}->{env}}) : undef;
    $self->{sql_errors_exit} = $self->{option_results}->{sql_errors_exit};
    
    $self->{timeout} = 10;
    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ &&
        $self->{option_results}->{timeout} > 0) {
        $self->{timeout} = $self->{option_results}->{timeout};
    }
    
    if (!defined($self->{data_source}) || $self->{data_source} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify data_source arguments.');
        $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
    }
    if (defined($self->{connect_options}) && $self->{connect_options} ne '') {
        foreach my $entry (split /,/, $self->{connect_options}) {
            if ($entry !~ /^\s*([^=]+)=([^=]+)\s*$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong format for --connect-options '" . $entry . "'.");
                $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
            }
            $self->{connect_options_hash}->{$1} = $2;
        }
    }
    
    if (scalar(@{$self->{option_results}->{data_source}}) == 0) {
        return 0;
    }
    return 1;
}

sub quote {
    my $self = shift;

    if (defined($self->{instance})) {
        return $self->{instance}->quote($_[0]);
    }
    return undef;
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

sub set_version {
    my ($self) = @_;
    
    $self->{version} = $self->{instance}->get_info(18); # SQL_DBMS_VER
}

sub disconnect {
    my ($self) = @_;
    
    if (defined($self->{instance})) {
        $self->{statement_handle} = undef;
        $self->{instance}->disconnect();
        $self->{instance} = undef;
    }
}
    
sub connect {
    my ($self, %options) = @_;
    my $dontquit = (defined($options{dontquit}) && $options{dontquit} == 1) ? 1 : 0;

    return if (defined($self->{instance}));
    
    # Set ENV
    if (defined($self->{env})) {
        foreach (keys %{$self->{env}}) {
            $ENV{$_} = $self->{env}->{$_};
        }
    }

    $self->set_signal_handlers();
    alarm($self->{timeout}) if (defined($self->{timeout}));
    $self->{instance} = DBI->connect(
        "DBI:". $self->{data_source},
        $self->{username},
        $self->{password},
        { RaiseError => 0, PrintError => 0, AutoCommit => 1, %{$self->{connect_options_hash}} }
    );
    alarm(0) if (defined($self->{timeout}));
    $self->prepare_destroy();

    if (!defined($self->{instance})) {
        my $err_msg = sprintf('Cannot connect: %s', defined($DBI::errstr) ? $DBI::errstr : '(no error string)');
        if ($dontquit == 0) {
            $self->{output}->add_option_msg(short_msg => $err_msg);
            $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
        }
        return (-1, $err_msg);
    }
    
    $self->set_version();
    return 0;
}

sub get_id {
    my ($self, %options) = @_;
    
    return $self->{data_source};
}

sub get_unique_id4save {
    my ($self, %options) = @_;

    return md5_hex($self->{data_source});
}

sub fetchall_arrayref {
    my ($self, %options) = @_;
    
    return $self->{statement_handle}->fetchall_arrayref();
}

sub fetchrow_array {
    my ($self, %options) = @_;
    
    return $self->{statement_handle}->fetchrow_array();
}

sub fetchrow_hashref {
    my ($self, %options) = @_;
    
    return $self->{statement_handle}->fetchrow_hashref();
}

sub query {
    my ($self, %options) = @_;
    my $continue_error = defined($options{continue_error}) && $options{continue_error} == 1 ? 1 : 0;
    
    $self->{statement_handle} = $self->{instance}->prepare($options{query});
    if (!defined($self->{statement_handle})) {
        return 1 if ($continue_error == 1);
        $self->{output}->add_option_msg(short_msg => 'Cannot execute query: ' . $self->{instance}->errstr);
        $self->disconnect();
        $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
    }

    my $rv = $self->{statement_handle}->execute;
    if (!$rv) {
        return 1 if ($continue_error == 1);
        $self->{output}->add_option_msg(short_msg => 'Cannot execute query: ' . $self->{statement_handle}->errstr);
        $self->disconnect();
        $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
    }
    
    return 0;
}

1;

__END__

=head1 NAME

DBI global

=head1 SYNOPSIS

dbi class

=head1 DBI OPTIONS

=over 8

=item B<--datasource>

Datasource (required. Depends of database server).

=item B<--username>

Database username.

=item B<--password>

Database password.

=item B<--connect-options>

Add options in database connect.
Format: name=value,name2=value2,...

=item B<--sql-errors-exit>

Exit code for DB Errors (default: unknown)

=item B<--timeout>

Timeout in seconds for connection

=back

=head1 DESCRIPTION

B<snmp>.

=cut
