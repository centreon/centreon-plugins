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

package centreon::plugins::passwordmgr::delineasecretserver;

use strict;
use warnings;
use Data::Dumper;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use JSON::Path;
use JSON::XS;

use vars qw($secretserver_connections);

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

    $options{options}->add_options(arguments => {
        'secretserver-endpoint-file:s'  => { name => 'secretserver_endpoint_file' },
        'secretserver-endpoint:s'       => { name => 'secretserver_endpoint' },
        'secretserver-address:s'        => { name => 'secretserver_address'},
        'secretserver-port:s'           => { name => 'secretserver_port' },
        'secretserver-protocol:s'       => { name => 'secretserver_protocol' },
        'secretserver-auth-method:s'    => { name => 'secretserver_auth_method' },
        'secretserver-auth-settings:s%' => { name => 'secretserver_auth_settings' },
        'secretserver-secret-id:s'      => { name => 'secretserver_secret_id' },
        'secretserver-search-value:s@'  => { name => 'secretserver_search_value' },
        'secretserver-map-option:s@'    => { name => 'secretserver_map_option' }
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'SECRETSERVER OPTIONS');

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, noptions => 1, default_backend => 'curl');
    $self->{statefile} = centreon::plugins::statefile->new(%options);
    $JSON::Path::Safe = 0;

    return $self;
}

sub parse_auth_method {
    my ($self, %options) = @_;

    my $login_settings;
    my $settings_mapping = {
        userpass => [ 'username', 'password' ]
    };

    foreach (@{$settings_mapping->{$options{method}}}) {
        if (!defined($options{settings}->{$_})) {
            $self->{output}->add_option_msg(short_msg => 'Missing authentication setting: ' . $_);
            $self->{output}->option_exit();
        }
        $login_settings->{$_} = $options{settings}->{$_};
    };

    return $login_settings;
}

sub get_access_token {
    my ($self, %options) = @_;
    
    my $login = $self->parse_auth_method(method => $self->{connection_info}->{auth_method}, settings => $self->{connection_info}->{auth_settings});
    
    my $has_cache_file = $options{statefile}->read(statefile => 'dss_' . md5_hex($self->{connection_info}->{address}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');
    my $refresh_token = $options{statefile}->get(name => 'refresh_token');
    
    if ($has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        my $post_data;
        if (defined($refresh_token) && $refresh_token ne "") {
            $post_data = 'grant_type=refresh_token' . 
                '&refresh_token=' . $refresh_token;
        } else {
            $post_data = 'grant_type=password' . 
                '&username=' . $login->{username} .
                '&password=' . $login->{password};
        }
        my $url_path = '/oauth2/token';

        my $content = $self->{http}->request(
            hostname => $self->{connection_info}->{address},
            port => $self->{connection_info}->{port},
            proto => $self->{connection_info}->{protocol},
            method => 'POST',
            header => ['Content-type: application/x-www-form-urlencoded'],
            query_form_post => $post_data,
            url_path => $url_path
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
        if (defined($decoded->{error})) {
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint return error code '" . $decoded->{error} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = {
            last_timestamp => time(),
            access_token => $decoded->{access_token},
            refresh_token => $decoded->{refresh_token},
            expires_on => time() + $decoded->{expires_in}
        };
        $options{statefile}->write(data => $datas);
    }
    
    return $access_token;
}

sub build_api_args {
    my ($self, %options) = @_;
    
    $self->{connection_info} = { address => undef, port => undef, protocol => undef, auth_method => undef, auth_settings => undef };
    if (defined($options{option_results}->{secretserver_endpoint_file}) && $options{option_results}->{secretserver_endpoint_file} ne '') {
        if (! -f $options{option_results}->{secretserver_endpoint_file} or ! -r $options{option_results}->{secretserver_endpoint_file}) {
            $self->{output}->add_option_msg(short_msg => "Cannot read secretserver file: $!");
            $self->{output}->option_exit();
        }
        
        require $options{option_results}->{secretserver_endpoint_file};
        if (defined($secretserver_connections) && defined($options{option_results}->{secretserver_endpoint}) && $options{option_results}->{secretserver_endpoint} ne '') {
            if (!defined($secretserver_connections->{$options{option_results}->{secretserver_endpoint}})) {
                $self->{output}->add_option_msg(short_msg => "Endpoint $options{option_results}->{secretserver_endpoint} doesn't exist in secretserver file");
                $self->{output}->option_exit();
            }
            
            $self->{connection_info} = $secretserver_connections->{$options{option_results}->{secretserver_endpoint}};
        }
    }
    
    foreach (['secretserver_address', 'address'], ['secretserver_port', 'port'], ['secretserver_protocol', 'protocol'],
        ['secretserver_auth_method', 'auth_method'], ['secretserver_auth_settings', 'auth_settings']) {
        if (defined($options{option_results}->{$_->[0]}) && $options{option_results}->{$_->[0]} ne '') {
            $self->{connection_info}->{$_->[1]} = $options{option_results}->{$_->[0]};
        }
    }
}

sub settings {
    my ($self, %options) = @_;
    
    $self->build_api_args(%options);

    if (!defined($options{option_results}->{secretserver_secret_id}) || $options{option_results}->{secretserver_secret_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set the --secretserver-secret-id option");
        $self->{output}->option_exit();
    }

    $self->{secret_id} = $options{option_results}->{secretserver_secret_id};

    $self->{statefile}->check_options(%options);

    if (!defined($self->{option_results}->{curl_opt})) {
        $self->{option_results}->{curl_opt} = ['CURLOPT_SSL_VERIFYPEER => 0', 'CURLOPT_SSL_VERIFYHOST => 0'];
    }

    $self->{http}->set_options(%{$self->{option_results}});

    if (lc($self->{connection_info}->{auth_method}) !~ m/userpass|token/ ) {
        $self->{output}->add_option_msg(short_msg => "Incorrect or unsupported authentication method set in --auth-method");
        $self->{output}->option_exit();
    }

    if (defined($self->{connection_info}->{auth_method}) && $self->{connection_info}->{auth_method} ne 'token') {
        $self->{connection_info}->{auth_settings}->{token} = $self->get_access_token(statefile => $self->{statefile});
    };

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{connection_info}->{auth_settings}->{token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{connection_info}->{auth_settings}->{token});
    }
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings(%options);
    
    my $url_path = '/api/v1/secrets/';

    my $content = $self->{http}->request(
        hostname => $self->{connection_info}->{address},
        port => $self->{connection_info}->{port},
        proto => $self->{connection_info}->{protocol},
        method => 'GET',
        url_path => $url_path . $self->{secret_id}
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "Secrets endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
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
    if (defined($decoded->{error})) {
        $self->{output}->add_option_msg(short_msg => "Secrets endpoint return error code '" . $decoded->{error} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return ($decoded, $content);
}

sub do_lookup {
    my ($self, %options) = @_;
    
    $self->{lookup_values} = {};
    return if (!defined($options{option_results}->{secretserver_search_value}));
    
    foreach (@{$options{option_results}->{secretserver_search_value}}) {
        next if (! /^(.+?)=(.+)$/);
        my ($map, $lookup) = ($1, $2);
                
        # Change %{xxx} options usage
        while ($lookup =~ /\%\{(.*?)\}/g) {
            my $sub = '';
            $sub = $options{option_results}->{$1} if (defined($options{option_results}->{$1}));
            $lookup =~ s/\%\{$1\}/$sub/g
        }
        
        my $jpath = JSON::Path->new($lookup);
        my $result = $jpath->value($options{json});
        $self->{output}->output_add(long_msg => 'lookup = ' . $lookup. ' - response = ' . Data::Dumper::Dumper($result), debug => 1);
        $self->{lookup_values}->{$map} = $result;
    }
}

sub do_map {
    my ($self, %options) = @_;
    
    return if (!defined($options{option_results}->{secretserver_map_option}));
    foreach (@{$options{option_results}->{secretserver_map_option}}) {
        next if (! /^(.+?)=(.+)$/);

        my ($option, $map) = ($1, $2);
        
        # Change %{xxx} options usage
        while ($map =~ /\%\{(.*?)\}/g) {
            my $sub = '';
            $sub = $self->{lookup_values}->{$1} if (defined($self->{lookup_values}->{$1}));
            $map =~ s/\%\{$1\}/$sub/g
        }

        $option =~ s/-/_/g;
        if ($option =~ /\@(.*)/) {
            push @{$options{option_results}->{$1}}, $map;
        } elsif ($option =~ /\%(.*)/) {
            my $opt = $1;
            next if ($map !~ /^(.+?)=(.+)$/);
            $options{option_results}->{$opt}->{$1} = $2;
        } else {
            $options{option_results}->{$option} = $map;
        }
    }
}

sub manage_options {
    my ($self, %options) = @_;

    my ($json, $debug) = $self->request_api(%options);
    if (!defined($json)) {
        $self->{output}->add_option_msg(short_msg => "Cannot read Secret Server information");
        $self->{output}->option_exit();
    }
    $self->do_lookup(%options, json => $json);
    $self->do_map(%options);
    $self->{output}->output_add(long_msg => Data::Dumper::Dumper($debug), debug => 1) if ($self->{output}->is_debug());
}

1;

__END__

=head1 NAME

Delinea Secret Server

=head1 SYNOPSIS

Delinea Secret Server class

=head1 SECRETSERVER OPTIONS

Use either a connection file with --secretserver-endpoint-file and
--secretserver-endpoint options like :

=over 4

--secretserver-endpoint-file='/var/lib/centreon-engine/.secret/myfile.pm'
--secretserver-endpoint='myendpoint'

=back

With 'myfile.pm' built like :

=over 4

=begin text

$secretserver_connections = {
    'myendpoint' => {
        'address' => 'tenant.secretservercloud.eu',
        'port' => '443',
        'protocol' => 'https',
        'auth_method' => 'userpass',
        'auth_settings' => {
            'username' => 'myuser',
            'password' => 'MyPa$$W0rd'
        }
    }
}

=end text

=back

Or define address, port, protocol, auth method and settings with the
dedicated options like :

=over 4

--secretserver-address='tenant.secretservercloud.eu' --secretserver-port=443
--secretserver-protocol=https --secretserver-auth-method=userpass
--secretserver-auth-settings='username=myuser'
--secretserver-auth-settings='password=MyPa$$W0rd'

=back

Token retrieved at authentication will be stored in a cache file. You
might want to define the directory so it will be in a safe place :

=over 4

--statefile-dir='/var/lib/centreon-engine/.secret/'

=back

=over 8

=item B<--secretserver-endpoint-file>

File with Secret Server connection information.

=item B<--secretserver-endpoint>

Connection information object to be used in file (mandatory if --secretserver-endpoint-file is used).

=item B<--secretserver-address>

IP address of the Secret Server server.

=item B<--secretserver-port>

Port of the Secret Server server.

=item B<--secretserver-protocol>

HTTP of the Secret Server server.
Can be: 'http', 'https'.

=item B<--secretserver-auth-method>

Authentication method to log in against the Vault server.
Can be: 'token', 'userpass'.

=item B<--secretserver-auth-settings>

Required information to log in according to the selected method.

Examples:

for 'userpass': --secretserver-auth-settings='username=user1' --secretserver-auth-settings='password=my_password'

for 'token': --secretserver-auth-settings='token=my_token'

=item B<--secretserver-secret-id>

ID of the secret to retrieve (mandatory).

=item B<--secretserver-search-value>

Looking for a value in the JSON Secret Server response. Can use JSON Path and other option values.

Example: 

--secretserver-search-value='username=$.items[?($_->{slug} =~ /username/i)].itemValue'
--secretserver-search-value='password=$.items[?($_->{slug} =~ /password/i)].itemValue'

=item B<--secretserver-map-option>

Overload plugin option.

Example:

--secretserver-map-option="username=%{username}"
--secretserver-map-option="password=%{password}"

=back

=head1 DESCRIPTION

B<delineasecretserver>.

=cut
