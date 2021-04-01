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

package apps::protocols::smtp::lib::smtp;

use strict;
use warnings;
use Email::Send::SMTP::Gmail;

my $smtp_handle;
my $connected = 0;

sub quit {
    if ($connected == 1) {
        $smtp_handle->bye;
    }
}

sub message {
    my ($self, %options) = @_;
    my %smtp_options = ();
    
    foreach my $option (@{$self->{option_results}->{smtp_send_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $smtp_options{-$1} = $2;
    }
    
    my $result;
    eval {
        local $SIG{ALRM} = sub { die 'timeout' };
        alarm($self->{option_results}->{timeout});
        $result = $smtp_handle->send(
            -to => $self->{option_results}->{smtp_to},
            -from => $self->{option_results}->{smtp_from},
            %smtp_options
        );
        alarm(0);
    };
    if ($@) {
        $self->{output}->output_add(
            severity => 'unknown',
            short_msg => 'Unable to send message: ' . $@
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($result == -1) {
        $self->{output}->output_add(
            severity => 'critical',
            short_msg => 'Unable to send message.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $self->{output}->output_add(
        severity => 'ok',
        short_msg => 'Message sent'
    );
}

sub connect {
    my ($self, %options) = @_;
    my %smtp_options = ();
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
    
    $smtp_options{-auth} = 'none';
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        $smtp_options{-login} = $self->{option_results}->{username};
        delete $smtp_options{-auth};
    }
    if (defined($self->{option_results}->{username}) && defined($self->{option_results}->{password})) {
        $smtp_options{-pass} = $self->{option_results}->{password};
    }
    
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $smtp_options{-port} = $self->{option_results}->{port} if (defined($self->{option_results}->{port}));
    foreach my $option (@{$self->{option_results}->{smtp_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $smtp_options{-$1} = $2;
    }
    
    my ($stdout, $error_msg);
    {
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            local *STDOUT;
            open STDOUT, '>', \$stdout;
            alarm($self->{option_results}->{timeout});
            ($smtp_handle, $error_msg) = Email::Send::SMTP::Gmail->new(
                -smtp=> $self->{option_results}->{hostname},
                %smtp_options
            );
            alarm(0);
        };
    }

    if ($@) {
        chomp $@;
        $self->{output}->output_add(
            severity => $connection_exit,
            short_msg => 'Unable to connect to SMTP: ' . $@
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($smtp_handle == -1) {
        chomp $stdout;
        $self->{output}->output_add(
            severity => $connection_exit,
            short_msg => 'Unable to connect to SMTP: ' . (defined($stdout) ? $stdout : $error_msg)
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $connected = 1;
}

1;
