#...
# Authors: Guillaume Carpentier <guillaume.carpentier@externes.justice.gouv.fr>

package apps::automation::ansible::tower::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw(encode_base64);

my %job_status_mapping = (
    'running' => 'UNKNOWN', # Running, should not be stuck too long in this state
    'successful' => 'OK', # This should be the only state we consider as OK
    'failed' => 'CRITICAL', # Something bad happened
    'canceled' => 'WARNING', # Not really critical because it was deliberate
    'pending' => 'UNKNOWN', # Just like running state
    'default' => 'UNKNOWN', # should not happen
);

my $exit_status = {
    'OK' => 0,
    'WARNING' => 1,
    'CRITICAL' => 2,
    'UNKNOWN' => 3
};

# From centreon/plugins/backend/http/curl.pm
# No info in lwp.pm which is the default backend and curl.pm needs Curl::Easy installation
# XXX Should be set in centreon/plugins/http.pm ???
my $http_code_explained = {
    100 => 'Continue',
    101 => 'Switching Protocols',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    306 => '(Unused)',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Requested Range Not Satisfiable',
    417 => 'Expectation Failed',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port'},
            'proto:s'           => { name => 'proto' },
            'api-username:s'    => { name => 'api_username' },
            'api-password:s'    => { name => 'api_password' },
            'api-token:s'       => { name => 'api_token' },
            'timeout:s'         => { name => 'timeout', default => 30 },
        });
    }
    
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{status} = 'OK';

    return $self;
}

sub get_job_status_severity {
    my ($self, %options) = @_;

    if (defined($options{status}) &&
        defined($job_status_mapping{$options{status}}) ) {
        return $job_status_mapping{$options{status}};
    } else {
        return $job_status_mapping{'default'};
    }
}

sub escalate_status {
    my ($self, %options) = @_;

    if (exists $exit_status->{$options{'status'}}) {
        if ($exit_status->{$options{'status'}} > $exit_status->{$self->{status}}) {
            $self->{status} = $options{'status'};
        }
    }
}

sub get_status {
    my ($self, %options) = @_;

    return $self->{status};
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : undef;
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : undef;
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : undef;

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{api_token})) {
        if (!defined($self->{api_username}) || $self->{api_username} eq '') {
            $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
            $self->{output}->option_exit();
        }
        if (!defined($self->{api_password}) || $self->{api_password} eq '') {
            $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
            $self->{output}->option_exit();
        }
    } elsif ($self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-token option.");
        $self->{output}->option_exit();
    }
    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();

    # When using session authentication, we must set www-form-urlencoded as content-type
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json;charset=UTF-8');
    $self->{http}->add_header(key => 'Accept', value => 'application/json;charset=UTF-8');
    if (defined $self->{api_token}) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{api_token});
    } elsif (defined($self->{api_username}) && defined($self->{api_password})) {
        # XXX store base64 encoded info as an object property ?
        $self->{http}->add_header(key => 'Authorization', value => 'Basic ' . encode_base64($self->{api_username} . ':' . $self->{api_password}, ''));  
    } else {
        # XXX Do we really want session authentication wwith cookies ?
        $self->session_authentication();
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

# XXX regex pattern could be an arg
sub str_to_hash {
    my ($self, %options) = @_;

    my $hash = {};
    my ($value, $key);
    if (defined($options{str}) && length $options{str} > 0) {
        for my $elt (split(/,/, $options{str})) {
            if ($elt =~ /(?<key>[\w_\.]+)=(?<value>[\w_\.]+)/) {
                $key = $+{key};
                $value = $+{value};
                # Fix JSON encode with numerics and ints
                if ($value =~ /^[\d]+(?:\.[\d]+)?$/) {
                    $hash->{$key} = $value + 0;
                } else {
                    $hash->{$key} = $value;
                }
            }
        }
    }

    return $hash;
}

# XXX Unused ! Works only with GET requests
# XXX manage cookies file in a better way
sub session_authentication() {
    my ($self, %options) = @_;

    my $state_file = 'automation_ansible_tower_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username});
    my $cookies_file = 'automation_ansible_tower_api_cookie_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username});

    # my $has_cache_file = $options{statefile}->read(statefile => $state_file);
    # my $session_id = $options{statefile}->get(name => 'session_id');

    # cookies file is managed by lwp backend when defined and != '' otherwise does not work well
    if (! -e $cookies_file && 0) { # || !defined($session_id) ) {
        my $content = $self->{http}->request(method => 'GET',
            url_path => '/api/login/',
            cookies_file => $cookies_file,
            warning_status => '', unknown_status => '', critical_status => '');
        my $csrf_cookie = $self->{http}->get_header(name => 'Set-Cookie');
        if ($csrf_cookie !~ /^csrftoken=(?<csrftoken>[a-zA-Z0-9]+);/) {
            $self->{output}->add_option_msg(short_msg => "No valid csrf token found.");
            $self->{output}->option_exit();
        }
        $self->{csrftoken} = $+{csrftoken};

        # Must not set content type otherwise post_params is not interpreted (seriously ?)
        # $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
        $self->{http}->add_header(key => 'X-CSRFToken', value => $self->{csrftoken});

        my $response = $self->{http}->request(
                                method => 'POST',
                                url_path => '/api/login/',
                                cookies_file => $cookies_file,
                                post_params => { 'username' => $self->{api_username}, 'password' => $self->{api_password}},
                                warning_status => '', unknown_status => '', critical_status => '',
                                );
        if ($self->{http}->get_code() != 302 && $self->{http}->get_code() != 404) {
            $self->{output}->add_option_msg(short_msg => "Login error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $session_id_cookie = $self->{http}->get_header(name => 'Set-Cookie');
        if ($session_id_cookie !~ /^sessionid=(?<session_id>[a-zA-Z0-9]+);/) {
            $self->{output}->add_option_msg(short_msg => "No session id found.");
            $self->{output}->option_exit();
        }
        my $session_id = $+{session_id};
        my $datas = { last_timestamp => time(), session_id => $session_id };
        # $options{statefile}->write(data => $datas);
        $self->{session_id} = $session_id;
    }
    # $self->{http}->add_header(key => 'sessionid', value => $self->{session_id});
    $self->{cookies_file} = $cookies_file;
}

sub request_api() {
    my ($self, %options) = @_;

    $self->settings();

    # XXX Set default request options with HASH struct ?
    my $response = $self->{http}->request(
            method => (defined($options{method})?$options{method}:'GET'),
            url_path => (defined($options{url_path})?$options{url_path}:'/'),
            query_form_post => (defined($options{query_form_post})?$options{query_form_post}:undef),
            critical_status => (defined($options{critical_status})?$options{critical_status}:''),
            warning_status => (defined($options{warning_status})?$options{warning_status}:''),
            unknown_status => (defined($options{unknown_status})?$options{unknown_status}:'')
            );
    
    # Set 200 as default status code if not provided
    my $status_code = defined($options{status_code}) ? $options{status_code} : 200;
    my $decoded = $self->json_decode(content => $response);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    if ($self->{http}->get_code() != $status_code) {
        if (defined($decoded) && !defined($decoded->{type})) {
            $self->{output}->add_option_msg(short_msg => '[' . $self->{http}->get_code() . '] - ' .
                            $http_code_explained->{$self->{http}->get_code()} . ' for url_path:' .
                            $options{url_path} . ' message:'.$response);
        } else {
            $self->{output}->add_option_msg(short_msg => 'Api request error: ' . (defined($decoded->{type}) ? $decoded->{type} : 'unknown'));
        }
        $self->{output}->option_exit();
    }
    
    return $decoded;
}

# XXX add long_message ?
sub plugin_exit() {
    my ($self, %options) = @_;
    my $force_ignore_perfdata = defined($options{force_ignore_perfdata}) ? $options{force_ignore_perfdata} : 1;
    my $force_long_output = defined($options{force_long_output}) ? $options{force_long_output} : 1;

    $self->{output}->output_add(severity => $self->{status},
        short_msg => $options{short_message});
    $self->{output}->display(force_ignore_perfdata => $force_ignore_perfdata, force_long_output => $force_long_output);
    $self->{output}->exit();
}

1;


__END__

=head1 NAME

AWX Rest API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Set hostname or IP of vsca.

=item B<--port>

Set port (Default: '443').

=item B<--proto>

Specify https if needed (Default: 'https').

=item B<--api-username>

Set username.

=item B<--api-password>

Set password.

=item B<--timeout>

Threshold for HTTP timeout (Default: '30').

=back

=cut
