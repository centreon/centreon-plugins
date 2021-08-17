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

package centreon::plugins::passwordmgr::vault;

use strict;
use warnings;
use Data::Dumper;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use JSON::XS;

use vars qw($vault_connections);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class PasswordMgr: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class PasswordMgr: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    print Dumper(${options);
    $options{options}->add_options(arguments => {
        'authent-method:s' => { name => 'auth_method', default => 'token' },
        'engine-version:s' => { name => 'engine_version', default => 'v1'},
        'map-option:s@'    => { name => 'map_option' },
        'secret-path:s'    => { name => 'secret_path' },
        'vault-address:s'  => { name => 'vault_address' },
        'vault-password:s' => { name => 'vault_password'},
        'vault-port:s'     => { name => 'vault_port', default => '8200' },
        'vault-protocol:s' => { name => 'vault_protocol', default => 'http'},
        'vault-token:s'    => { name => 'vault_token'},
        'vault-username:s' => { name => 'vault_username'}
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'VAULT OPTIONS');

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, noptions => 1);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{option_results}->read(statefile => 'vault_' . md5_hex($self->{vault_address}) . '_' . md5_hex($self->{vault_username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');
    if ( $has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10) ) {
        my $login = { username => $self->{vault_username}, password => $self->{vault_password} };
        my $post_json = JSON::XS->new->utf8->encode($login);

        my $content = $self->{http}->request(
            hostname => $self->{vault_address},
            port => $self->{vault_port},
            proto => $self->{vault_protocol},
            method => 'POST',
            header => ['Content-type: application/json'],
            query_form_post => $post_json,
            url_path => $self->{vault_address} . '/v1/auth/userpass/login' . $self->{vault_username}
        );

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error_code})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{error_code} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{access_token}, expires_on => time() + 3600 };
        $options{statefile}->write(data => $datas);
    }

    return $access_token;
}

sub settings {
    my ($self, %options) = @_;

    $self->{request_endpoint} = '/v1/' . $options{option_results}->{secret_path};
    $self->{vault_address} = $options{option_results}->{vault_address};
    $self->{vault_port} = $options{option_results}->{vault_port};
    $self->{vault_protocol} = $options{option_results}->{vault_protocol};
    $self->{vault_username} = defined($options{option_results}->{vault_username}) && $options{option_results}->{vault_username} ne '' ? $options{option_results}->{vault_username} : undef;
    $self->{secret_path} = $options{option_results}->{secret_path};
    $self->{vault_token} = $options{option_results}->{vault_token};
    $self->{auth_method} = $options{option_results}->{auth_method};
    $self->{engine_version} = $options{option_results}->{engine_version};

    if (defined($options{option_results}->{auth_method}) && $options{option_results}->{auth_method} eq 'password') {
            $self->{vault_token} = $self->get_access_token(%options);
    };
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{vault_token})) {
        $self->{http}->add_header(key => 'X-Vault-Token', value => $self->{vault_token});
    }
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings(%options);

    my $response = $self->{http}->request(
        hostname => $self->{vault_address},
        port => $self->{vault_port},
        proto => $self->{vault_protocol},
        method => 'GET',
        url_path => $self->{request_endpoint}
    );
    $self->{output}->output_add(long_msg => $response, debug => 1);
    my $json;
    eval {
        $json = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode Vault JSON response: $@");
        $self->{output}->option_exit();
    }

    if ((defined($json->{data}->{metadata}->{deletion_time}) && $json->{data}->{metadata}->{deletion_time} ne '') || $json->{data}->{metadata}->{destroyed} eq 'true') {
        $self->{output}->add_option_msg(short_msg => "This token is not valid anymore");
        $self->{output}->option_exit();
    }

    foreach (keys %{$json->{data}->{data}}) {
        $self->{lookup_values}->{key} = $_;
        $self->{lookup_values}->{value} = $json->{data}->{data}->{$_};
    }

    return ($json, $response);

}

sub do_map {
    my ($self, %options) = @_;

    return if (!defined($options{option_results}->{map_option}));
    foreach (@{$options{option_results}->{map_option}}) {
        next if (! /^(.+?)=(.+)$/);
        print ref($options{option_results}->{$1}) . "\n";

        my ($option, $map) = ($1, $2);

        # Change %{xxx} options usage
        while ($map =~ /\%\{(.*?)\}/g) {
            my $sub = '';
            $sub = $self->{lookup_values}->{$1} if (defined($self->{lookup_values}->{$1}));
            $map =~ s/\%\{$1\}/$sub/g
        }
        $option =~ s/-/_/g;
        $options{option_results}->{$option} = $map;
    }
}

sub manage_options {
    my ($self, %options) = @_;

    my ($content, $debug) = $self->request_api(%options);
    if (!defined($content)) {
        $self->{output}->add_option_msg(short_msg => "Cannot read Vault information");
        $self->{output}->option_exit();
    }
    $self->do_map(%options);
    $self->{output}->output_add(long_msg => Data::Dumper::Dumper($debug), debug => 1) if ($self->{output}->is_debug());
}

1;

__END__

=head1 NAME

Keepass global

=head1 SYNOPSIS

keepass class

=head1 KEEPASS OPTIONS

=over 8

=item B<--keepass-endpoint>

Connection information to be used in keepass file.

=item B<--keepass-endpoint-file>

File with keepass connection informations.

=item B<--keepass-file>

Keepass file.

=item B<--keepass-password>

Keepass master password.

=item B<--keepass-search-value>

Looking for a value in the JSON keepass. Can use JSON Path and other option values.
Example: 
--keepass-search-value='password=$..entries.[?($_->{title} =~ /serveurx/i)].password'
--keepass-search-value='username=$..entries.[?($_->{title} =~ /serveurx/i)].username'
--keepass-search-value='password=$..entries.[?($_->{title} =~ /%{hostname}/i)].password'

=item B<--keepass-map-option>

Overload plugin option.
Example:
--keepass-map-option="password=%{password}"
--keepass-map-option="username=%{username}"

=back

=head1 DESCRIPTION

B<keepass>.

=cut
