package apps::hashicorp::consul::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    };
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    };

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'api-version:s'          => { name => 'api_version' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'auth-method:s'          => { name => 'auth_method', default => 'token' },
            'auth-path:s'            => { name => 'auth_path' },
            'auth-settings:s%'       => { name => 'auth_settings' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'consul-token:s'         => { name => 'consul_token'}
        });
    };
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (defined($options{option_results}->{auth_path})) {		
        $self->{auth_path} = lc($options{option_results}->{auth_path});
    };

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8200;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{auth_method} = lc($self->{option_results}->{auth_method});
    $self->{auth_settings} = defined($self->{option_results}->{auth_settings}) && $self->{option_results}->{auth_settings} ne '' ? $self->{option_results}->{auth_settings} : {};
    $self->{consul_token} = $self->{option_results}->{consul_token};
    $self->{api_version} = (defined($self->{option_results}->{api_version})) ? $self->{option_results}->{api_version} : 'v1';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 180;
    $self->{cache}->check_options(option_results => $self->{option_results});

    if (lc($self->{auth_method}) !~ m/azure|cert|github|ldap|okta|radius|userpass|token/ ) {
        $self->{output}->add_option_msg(short_msg => "Incorrect or unsupported authentication method set in --auth-method");
        $self->{output}->option_exit();
    };

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{basic} = 1;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');

    if (defined($self->{option_results}->{auth_method}) && $self->{option_results}->{auth_method} ne 'token') {
        $self->{consul_token} = $self->get_access_token(statefile => $self->{cache});
    };

    if (defined($self->{consul_token})) {
        $self->{http}->add_header(key => 'X-Consul-Token', value => $self->{consul_token});
    };

    $self->{http}->set_options(%{$self->{option_results}});


    $self->{settings_done} = 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_access_token {
    my ($self, %options) = @_;


    my $has_cache_file = $options{statefile}->read(statefile => 'consul_restapi_' . md5_hex($self->{hostname}) . '_' . md5_hex($self->{auth_method}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');
    if ( $has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10) ) {
        my $decoded;
        my $login = $self->parse_auth_method(method => $self->{auth_method}, settings => $self->{auth_settings});
        my $post_json = JSON::XS->new->utf8->encode($login);
        if (!defined($self->{auth_path}) || $self->{auth_path} eq '') {
            $self->{auth_path} = $self->{auth_method};
        }
        my $url_path = '/' . $self->{api_version} . '/auth/'. $self->{auth_path} . '/login/';
        $url_path .= $self->{auth_settings}->{username} if (defined($self->{auth_settings}->{username}) && $self->{auth_method} =~ 'userpass|login') ;

        my $content = $self->{http}->request(
            hostname => $self->{hostname},
            port => $self->{port},
            proto => $self->{proto},
            method => 'POST',
            header => ['Content-type: application/json'],
            query_form_post => $post_json,
            url_path => $url_path
        );

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        };

        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        };
        if (defined($decoded->{errors}[0])) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{errors}[0], debug => 1);
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{errors}[0] . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        };
        $access_token = $decoded->{auth}->{client_token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{access_token}, expires_on => time() + 3600 };
        $options{statefile}->write(data => $datas);
    };

    return $access_token;
}

sub parse_auth_method {
    my ($self, %options) = @_;

    my $login_settings;
    my $settings_mapping = {
        azure    => [ 'role', 'jwt' ],
        cert     => [ 'name' ],
        github   => [ 'token' ],
        ldap     => [ 'username', 'password' ],
        okta     => [ 'username', 'password', 'totp' ],
        radius   => [ 'username', 'password' ],
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

sub request_api {
    my ($self, %options) = @_;

    $self->settings(%options);
    my ($json, $response);

    $response = $self->{http}->request(
        method => 'GET',
        url_path => '/' . $self->{api_version} . '/' . $options{url_path}
    );
    $self->{output}->output_add(long_msg => $response, debug => 1);

    eval {
        $json = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode Consul JSON response: $@");
        $self->{output}->option_exit();
    };

    return $json;
}

1;

__END__

=head1 NAME

HashiCorp Consul Rest API

=head1 REST API OPTIONS

HashiCorp Consul Rest API

=over 8

=item B<--hostname>

HashiCorp Consul hostname.

=item B<--port>

Port used (default: 8200)

=item B<--proto>

Specify https if needed (default: 'http')

=item B<--api-version>

Specify the Consul API version (default: 'v1')

=item B<--consul-token>

Specify the Consul access token (only for the 'token' authentication method)

=item B<--auth-method>

Specify the Consul authentication method (default: 'token').
Can be: 'azure', 'cert', 'github', 'ldap', 'okta', 'radius', 'userpass', 'token'
If different from 'token' the "--auth-settings" options must be set.

=item B<--auth-settings>

Specify the Consul authentication specific settings.
Syntax: --auth-settings='<setting>=<value>'.Example for the 'userpass' method:
--auth-method='userpass' --auth-settings='username=my_account' --auth-settings='password=my_password'

=item B<--auth-path>

Authentication path for 'userpass'. Is an optional setting.

More information here: https://developer.hashicorp.com/consul/docs/auth/userpass#configuration

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
