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

package database::db2::dbi;

use base qw(centreon::plugins::dbi);

use strict;
use warnings;
use POSIX qw(:signal_h);

sub connect_db2 {
    my ($self, %options) = @_;
    
    $self->{instance} = DBI->connect(
        'DBI:' . $self->{data_source},
        $self->{username},
        $self->{password},
        { RaiseError => 0, PrintError => 0, AutoCommit => 1, %{$self->{connect_options_hash}} }
    );
}

sub connect {
    my ($self, %options) = @_;
    my $dontquit = (defined($options{dontquit}) && $options{dontquit} == 1) ? 1 : 0;

    if ($self->{data_source} =~ /PROTOCOL=TCPIP/) {
        $self->{data_source} .= 'UID=' . $self->{username} . ';'
            if ($self->{data_source} !~ /UID/ && defined($self->{username}));
        $self->{data_source} .= 'PWD=' . $self->{password} . ';'
            if ($self->{data_source} !~ /PWD/ && defined($self->{password}));
    }

    # Set ENV
    if (defined($self->{env})) {
        foreach (keys %{$self->{env}}) {
            $ENV{$_} = $self->{env}->{$_};
        }
    }

    my $connect_error;
    if (defined($self->{timeout})) {
        my $mask = POSIX::SigSet->new(SIGALRM);
        my $action = POSIX::SigAction->new(
            sub { $self->handle_ALRM() },
            $mask,
        );
        my $oldaction = POSIX::SigAction->new();
        sigaction(SIGALRM, $action, $oldaction);
        eval {
            eval {
                alarm($self->{timeout});
                $self->connect_db2();
            };
            alarm(0);
            if ($@) {
                $connect_error = $@;
            }
        };
        sigaction(SIGALRM, $oldaction);
    } else {
        eval {
            $self->connect_db2();
        };
        if ($@) {
            $connect_error = $@;
        }
    }

    if (!defined($self->{instance})) {
        my $err_msg = sprintf(
            'Cannot connect: %s',
            defined($DBI::errstr) ? $DBI::errstr : 
                (defined($connect_error) ? $connect_error : '(no error string)')
        );
        if ($dontquit == 0) {
            $self->{output}->add_option_msg(short_msg => $err_msg);
            $self->{output}->option_exit(exit_litteral => $self->{sql_errors_exit});
        }
        return (-1, $err_msg);
    }

    $self->set_version();
    return 0;
}

sub get_dbh {
    my ($self, %options) = @_;

    return $self->{instance};
}

sub fetchrow_arrayref {
    my ($self, %options) = @_;

    return $self->{statement_handle}->fetchrow_arrayref();
}

sub get_database_name {
    my ($self, %options) = @_;

    my $dbname = 'unknown';
    $dbname = $1 if ($self->{data_source} =~ /DATABASE=([^;]*)/i);
    $dbname = $1 if ($self->{data_source} =~ /DBI:DB2:(.*)/);
    $dbname =~ s/^\s+//g;
    $dbname =~ s/\s+$//g;
    return $dbname;
}

1;

__END__
