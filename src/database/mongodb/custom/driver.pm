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

package database::mongodb::custom::driver;

use strict;
use warnings;
use DateTime;
use MongoDB;
use Hash::Ordered;
use URI::Encode;
use centreon::plugins::misc;

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
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port' },
            'protocol:s' => { name => 'protocol' },
            'username:s' => { name => 'username' },
            'password:s' => { name => 'password' },
            'auth-source:s' => { name => 'auth_source' },
            'replica-set:s' => { name => 'replica_set' },
            'timeout:s'  => { name => 'timeout' },
            'ssl-opt:s@' => { name => 'ssl_opt' },
            'no-ssl'     => { name => 'no_ssl' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'DRIVER OPTIONS', once => 1);

    $self->{output} = $options{output};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : '';
    $self->{protocol} = (defined($self->{option_results}->{protocol})) ? $self->{option_results}->{protocol} : 'mongodb';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{auth_source} = (defined($self->{option_results}->{auth_source})) ? $self->{option_results}->{auth_source} : '';
    $self->{replica_set} = (defined($self->{option_results}->{replica_set})) ? $self->{option_results}->{replica_set} : '';
    $self->{no_ssl} = (defined($self->{option_results}->{no_ssl})) ? 1 : 0;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }

    $self->{ssl_opts} = centreon::plugins::misc::eval_ssl_options(
        output => $self->{output},
        ssl_opt => $self->{option_results}->{ssl_opt}
    );

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

sub build_uri {
    my ($self, %options) = @_;

    my $encoder = URI::Encode->new({encode_reserved => 1});
    my $encoded_username = $encoder->encode($self->{username});
    my $encoded_password = $encoder->encode($self->{password});

    my $host = defined($options{host}) && $options{host} ne '' ? $options{host} : $self->{hostname};
    my $port = defined($options{port}) ? $options{port} : $self->{port};

    my $uri = $self->{protocol} . '://';
    $uri .= $encoded_username . ':' . $encoded_password . '@' if ($encoded_username ne '' && $encoded_password ne '');
    $uri .= $host if ($host ne '');
    $uri .= ':' . $port if ($port ne '' && $host !~ /:\d+$/ && $self->{protocol} ne 'mongodb+srv');

    my @params = ();
    push @params, 'authSource=' . $encoder->encode($self->{auth_source}) if ($self->{auth_source} ne '');
    push @params, 'replicaSet=' . $encoder->encode($self->{replica_set}) if ($self->{replica_set} ne '');
    # MongoDB URI parser requires a '/' between the host list and the
    # query string, even when no default database is specified.
    $uri .= '/?' . join('&', @params) if (scalar(@params) > 0);

    return $uri;
}

sub redact_uri {
    my ($self, $uri) = @_;

    # Hide the password between ':' and '@' in 'scheme://user:password@host...'
    # so that --debug never leaks credentials.
    $uri =~ s{(://[^:/@]+):[^@]+@}{$1:***\@};
    return $uri;
}

sub build_mongodb_options {
    my ($self, %options) = @_;

    my %mongodb_options = ();
    if ($self->{no_ssl} == 0) {
        $mongodb_options{ssl} = (defined($self->{ssl_opts}) && scalar(keys %{$self->{ssl_opts}}) > 0) ? $self->{ssl_opts} : 1;
    }

    return %mongodb_options;
}

sub connect {
    my ($self, %options) = @_;

    my $uri = $self->build_uri();
    $self->{output}->output_add(long_msg => 'Connection URI: ' . $self->redact_uri($uri), debug => 1);

    my %mongodb_options = $self->build_mongodb_options();
    $self->{client} = MongoDB::MongoClient->new(host => $uri, %mongodb_options);
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

sub run_command_on_host {
    my ($self, %options) = @_;

    my $uri = $self->build_uri(host => $options{host}, port => $options{port});
    $self->{output}->output_add(long_msg => 'Connection URI: ' . $self->redact_uri($uri), debug => 1);

    my %mongodb_options = $self->build_mongodb_options();
    my $client = MongoDB::MongoClient->new(host => $uri, %mongodb_options);
    $client->connect();

    my $db = $client->get_database($options{database});
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
    my @cls = $db->collection_names({ type => 'collection' });

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

Protocol used (default: mongodb)
DNS Seedlist Connection Format can be specified, i.e. 'mongodb+srv'

=item B<--username>

MongoDB username.

=item B<--password>

MongoDB password.

=item B<--auth-source>

Authentication database (authSource connection string option).

=item B<--replica-set>

Replica set name (replicaSet connection string option).

=item B<--timeout>

Set timeout in seconds (default: 10).

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => 'TLSv1'" --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE").

=item B<--no-ssl>

Don't use ssl connection.

=back

=head1 DESCRIPTION

B<custom>.

=cut
