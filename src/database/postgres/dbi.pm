#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package database::postgres::dbi;

use base qw(centreon::plugins::dbi);

use strict;
use warnings;

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
    my $connect_error;
    eval {
        $ENV{PGCONNECT_TIMEOUT} = $self->{timeout} if (defined($self->{timeout}));
        $self->{instance} = DBI->connect(
            "DBI:". $self->{data_source},
            $self->{username},
            $self->{password},
            { RaiseError => 0, PrintError => 0, AutoCommit => 1, %{$self->{connect_options_hash}} }
        );
    };
    if ($@) {
        $connect_error = $@;
    }

    $self->prepare_destroy();

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

    if (defined($self->{connect_query}) && $self->{connect_query} ne '') {
        $self->query(query => $self->{connect_query});
    }
    $self->set_version();
    return 0;
}

1;

__END__
