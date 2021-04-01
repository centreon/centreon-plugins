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

package apps::protocols::ftp::lib::ftp;

use strict;
use warnings;
use centreon::plugins::misc;
use Net::FTP;

my $ftp_handle;

sub quit {
    $ftp_handle->quit;
}

sub message {
    return $ftp_handle->message;
}

sub execute {
    my ($self, %options) = @_;
    my $command = $options{command};
    
    return $ftp_handle->$command(@{$options{command_args}});
}

sub connect {
    my ($self, %options) = @_;
    my %ftp_options = ();
    
    my $ftp_class = 'Net::FTP'; 
    if (defined($self->{option_results}->{use_ssl})) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Net::FTPSSL',
                                               error_msg => "Cannot load module 'Net::FTPSSL'.");
        $ftp_class = 'Net::FTPSSL'; 
    }
    
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $ftp_options{Port} = $self->{option_results}->{port} if (defined($self->{option_results}->{port}));
    $ftp_options{Timeout} = $self->{option_results}->{timeout} if (defined($self->{option_results}->{timeout}));
    foreach my $option (@{$self->{option_results}->{ftp_options}}) {
        my ($key, $value) = split /=/, $option;
        if (defined($key) && defined($value)) {
            $ftp_options{$key} = $value;
        }
    }
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
    
    $ftp_handle = $ftp_class->new($self->{option_results}->{hostname},
        %ftp_options
    );
    
    
    if (!defined($ftp_handle)) {
        if (defined($self->{option_results}->{use_ssl})) {
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Unable to connect to FTP: ' . $Net::FTPSSL::ERRSTR);
        } else {
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Unable to connect to FTP: ' . $@);
        }
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        if (!$ftp_handle->login($self->{option_results}->{username}, $self->{option_results}->{password})) {
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Login failed: ' . $ftp_handle->message);
            quit();
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
}

1;
