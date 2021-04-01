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

package apps::protocols::imap::lib::imap;

use strict;
use warnings;
use Net::IMAP::Simple;
use IO::Socket::SSL;

my $imap_handle;

sub quit {
    $imap_handle->quit;
}

sub search {
    my ($self, %options) = @_;

    if (!defined($imap_handle->select($self->{option_results}->{folder}))) {
        my $output = $imap_handle->errstr;
        $output =~ s/\r//g;
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Folder Select Error: ' . $output
        );
        quit();
        $self->{output}->display();
        $self->{output}->exit();
    }

    my @ids = $imap_handle->search($self->{option_results}->{search});

    if (defined($self->{option_results}->{delete})) {
        foreach my $msg_num (@ids) {
            $imap_handle->delete($msg_num);
        }
        $imap_handle->expunge_mailbox();
    }

    return scalar(@ids);
}

sub connect {
    my ($self, %options) = @_;
    my %imap_options = ();

    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $imap_options{port} = $self->{option_results}->{port} if (defined($self->{option_results}->{port}));
    $imap_options{use_ssl} = 1 if (defined($self->{option_results}->{use_ssl}));
    $imap_options{timeout} = $self->{option_results}->{timeout} if (defined($self->{option_results}->{timeout}));
    if ($self->{ssl_options} ne '') {
        $imap_options{ssl_options} = [ eval $self->{ssl_options} ];
    }

    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => 'Please set --password option.');
        $self->{output}->option_exit();
    }

    $imap_handle = Net::IMAP::Simple->new(
        $self->{option_results}->{hostname},
        %imap_options
    );

    if (!defined($imap_handle)) {
        $self->{output}->output_add(
            severity => $connection_exit,
            short_msg => 'Unable to connect to IMAP: ' . $Net::IMAP::Simple::errstr
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        if (!$imap_handle->login($self->{option_results}->{username}, $self->{option_results}->{password})) {
            # Exchange put '\r'...
            my $output = $imap_handle->errstr;
            $output =~ s/\r//g;
            $self->{output}->output_add(
                severity => $connection_exit,
                short_msg => 'Login failed: ' . $output
            );
            quit();
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
}

1;
