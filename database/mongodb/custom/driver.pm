#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package database::mongodb::custom::driver;

use strict;
use warnings;
use DateTime;
use MongoDB;
use Hash::Ordered;
use URI::Encode;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            "hostname:s"    => { name => 'hostname' },
            "port:s"        => { name => 'port' },
            "protocol:s"    => { name => 'protocol' },
            "username:s"    => { name => 'username' },
            "password:s"    => { name => 'password' },
            "timeout:s"     => { name => 'timeout' },
            "ssl-opt:s@"    => { name => 'ssl_opt' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'DRIVER OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : '';
    $self->{protocol} = (defined($self->{option_results}->{protocol})) ? $self->{option_results}->{protocol} : 'mongodb';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }

    foreach (@{$self->{option_results}->{ssl_opt}}) {
        $_ =~ /(\w+)\s*=>\s*(\w+)/;
        $self->{ssl_opts}->{$1} = $2;
    }

    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub connect {
    my ($self, %options) = @_;

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $encoded_username = $uri->encode($self->{username});
    my $encoded_password = $uri->encode($self->{password});

    $uri = $self->{protocol} . '://';
    $uri .= $encoded_username . ':' . $encoded_password . '@' if ($encoded_username ne '' && $encoded_password ne '');
    $uri .= $self->{hostname} if ($self->{hostname} ne '');
    $uri .= ':' . $self->{port} if ($self->{port} ne '');

    $self->{output}->output_add(long_msg => 'Connection URI: ' . $uri, debug => 1);
    
    my $ssl = (defined($self->{ssl_opts})) ? $self->{ssl_opts} : 0;
    $self->{client} = MongoDB::MongoClient->new(host => $uri, ssl => $ssl);
    $self->{client}->connect();

    eval {
        my $conn_status = $self->run_command(
            database => 'admin',
            command => $self->ordered_hash(ping => 1),
        );
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $@, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Connection error (add --debug option to display error message)");
        $self->{output}->option_exit();
    }
}

sub ordered_hash {
    my ($self, %options) = @_;

    tie my %hash, 'Hash::Ordered';
    my $oh = tied %hash;
    $oh->push(%options);
    return \%hash;
}

sub run_command {
    my ($self, %options) = @_;

    if (!defined($self->{client})) {
        $self->connect();
    }
        
    my $db = $self->{client}->get_database($options{database});
    return $db->run_command($options{command});
}

sub list_databases {
    my ($self, %options) = @_;

    if (!defined($self->{client})) {
        $self->connect();
    }

    my @dbs = $self->{client}->database_names;

    return \@dbs;
}

sub list_collections {
    my ($self, %options) = @_;

    if (!defined($self->{client})) {
        $self->connect();
    }

    my $db = $self->{client}->get_database($options{database});
    my @cls = $db->collection_names;

    return \@cls;
}

1;

__END__

=head1 NAME

MongoDB driver

=head1 DRIVER OPTIONS

MongoDB driver

=over 8

=item B<--hostname>

MongoDB server hostname.

=item B<--port>

Port used by MongoDB.

=item B<--protocol>

Protocol used (Default: mongodb)
DNS Seedlist Connection Format can be specified, i.e. 'mongodb+srv'

=item B<--username>

MongoDB username.

=item B<--password>

MongoDB password.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => TLSv1" --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE").

=back

=head1 DESCRIPTION

B<custom>.

=cut
