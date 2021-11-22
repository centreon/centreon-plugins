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

package apps::protocols::sftp::lib::sftp;

use strict;
use warnings;
use centreon::plugins::misc;
use Net::SFTP::Foreign;

my $sftp_handle;

sub quit {
    $sftp_handle->disconnect;
}

sub message {
    return $sftp_handle->error;
}

sub execute {
    my ($self, %options) = @_;
    my $command = $options{command};

    return $sftp_handle->$command(@{$options{command_args}});
}

sub connect {
    my ($self, %options) = @_;
    my %sftp_options = ();

    my $sftp_class = 'Net::SFTP::Foreign';

    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $sftp_options{port} = $self->{option_results}->{port} if (defined($self->{option_results}->{port}));
    $sftp_options{timeout} = $self->{option_results}->{timeout} if (defined($self->{option_results}->{timeout}));
    $sftp_options{user} = $self->{option_results}->{username} if (defined($self->{option_results}->{username}));
    $sftp_options{password} = $self->{option_results}->{password} if (defined($self->{option_results}->{password}));
    $sftp_options{key_path} = $self->{option_results}->{ssh_priv_key} if (defined($self->{option_results}->{ssh_priv_key}));
    $sftp_options{passphrase} = $self->{option_results}->{passphrase} if (defined($self->{option_results}->{passphrase}));
    my @ssh_options;
    foreach my $option (@{$self->{option_results}->{ssh_options}}) {
      my ($key, $value) = split / /, $option;
      if (defined($value)) {
        push @ssh_options, ( $key => $value );
      } else {
        push @ssh_options, "$key";
      }
    }

    $sftp_handle = $sftp_class->new($self->{option_results}->{hostname},more=>[@ssh_options],
        %sftp_options
    );
    if ($sftp_handle->error) {
      $self->{output}->output_add(severity => $connection_exit,
                                  short_msg => 'Unable to connect to FTP: ' . $sftp_handle->error);
      $self->{output}->display();
      $self->{output}->exit();
    }
}

1;
