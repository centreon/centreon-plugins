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

package centreon::plugins::backend::http::curl;

use strict;
use warnings;
use URI;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{noptions}) || $options{noptions} != 1) {
        $options{options}->add_options(arguments => {
            'curl-opt:s@' => { name => 'curl_opt' }
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'BACKEND CURL OPTIONS', once => 1);
    }

    $self->{output} = $options{output};

    $self->{curl_log} = $options{curl_logger};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Net::Curl::Easy',
        error_msg => "Cannot load module 'Net::Curl::Easy'."
    );
    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'centreon::plugins::backend::http::curlconstants',
        error_msg => "Cannot load module 'centreon::plugins::backend::http::curlconstants'."
    );
    $self->{constant_cb} = \&centreon::plugins::backend::http::curlconstants::get_constant_value;

    foreach (('unknown_status', 'warning_status', 'critical_status')) {
        if (defined($options{request}->{$_})) {
            $options{request}->{$_} =~ s/%\{http_code\}/\$values->{code}/g;
        }
    }

    if (!defined($options{request}->{curl_opt})) {
        $options{request}->{curl_opt} = [];
    }
}

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
    450 => 'Timeout reached', # custom code
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported'
};

sub cb_debug {
    my ($easy, $type, $data, $uservar) = @_;

    my $msg = '';
    if ($type == $uservar->{constant_cb}->(name => 'CURLINFO_TEXT')) {
        $msg = sprintf("== Info: %s", $data);
    }
    if ($type == $uservar->{constant_cb}->(name => 'CURLINFO_HEADER_OUT')) {
        $msg = sprintf("=> Send header: %s", $data);
    }
    if ($type == $uservar->{constant_cb}->(name => 'CURLINFO_DATA_OUT')) {
        $msg = sprintf("=> Send data: %s", $data);
    }
    if ($type == $uservar->{constant_cb}->(name => 'CURLINFO_HEADER_IN')) {
        $msg = sprintf("=> Recv header: %s", $data);
    }
    if ($type == $uservar->{constant_cb}->(name => 'CURLINFO_DATA_IN')) {
        $msg = sprintf("=> Recv data: %s", $data);
    }
    return 0 if ($type == $uservar->{constant_cb}->(name => 'CURLINFO_SSL_DATA_OUT'));
    return 0 if ($type == $uservar->{constant_cb}->(name => 'CURLINFO_SSL_DATA_IN'));

    $uservar->{output}->output_add(long_msg => $msg, debug => 1);
    return 0;
}

sub curl_setopt {
    my ($self, %options) = @_;

    eval {
        $self->{curl_easy}->setopt($options{option}, $options{parameter});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "curl setopt error: '" . $@ . "'.");
        $self->{output}->option_exit();
    }
}

sub set_method {
    my ($self, %options) = @_;

    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_CUSTOMREQUEST'), parameter => undef);
    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_POSTFIELDS'), parameter => undef);
    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HTTPGET'), parameter => 1);

    my $skip_log_post = 0;
    # POST inferred by CURLOPT_POSTFIELDS
    if ($options{content_type_forced} == 1) {
        if (defined($options{request}->{query_form_post})) {
            $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_POSTFIELDS'), parameter => $options{request}->{query_form_post});
            $self->{curl_log}->log("--data-raw", $options{request}->{query_form_post});
            $skip_log_post = 1;
        }
    } elsif (defined($options{request}->{post_params})) {
        my $uri_post = URI->new();
        $uri_post->query_form($options{request}->{post_params});
        my $urlencodedheader = 'Content-Type: application/x-www-form-urlencoded';
        push @{$options{headers}}, $urlencodedheader;

        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_POSTFIELDS'), parameter => $uri_post->query);
        $self->{curl_log}->log("-H", $urlencodedheader);

        $self->{curl_log}->log("--data-raw", $uri_post->query);
        $skip_log_post = 1;
    }

    if ($options{request}->{method} eq 'GET') {
        # no curl_log call because GET is the default value
        return;
    }

    if ($options{request}->{method} eq 'POST') {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_POST'), parameter => 1);
        $self->{curl_log}->log('-X', $options{request}->{method}) unless $skip_log_post;
        return;
    }

    $self->{curl_log}->log('-X', $options{request}->{method});
    if ($options{request}->{method} eq 'PUT') {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_CUSTOMREQUEST'), parameter => $options{request}->{method});
    }
    if ($options{request}->{method} eq 'DELETE') {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_CUSTOMREQUEST'), parameter => $options{request}->{method});
    }
    if ($options{request}->{method} eq 'PATCH') {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_CUSTOMREQUEST'), parameter => $options{request}->{method});
    }
}

sub set_auth {
    my ($self, %options) = @_;

    if (defined($options{request}->{credentials})) {
        if (defined($options{request}->{basic})) {
            $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HTTPAUTH'), parameter => $self->{constant_cb}->(name => 'CURLAUTH_BASIC'));
            $self->{curl_log}->log('--basic');
        } elsif (defined($options{request}->{ntlmv2})) {
            $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HTTPAUTH'), parameter => $self->{constant_cb}->(name => 'CURLAUTH_NTLM'));
            $self->{curl_log}->log('--ntlm');
        } elsif (defined($options{request}->{digest})) {
            $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HTTPAUTH'), parameter => $self->{constant_cb}->(name => 'CURLAUTH_DIGEST'));
            $self->{curl_log}->log('--digest');
        }else {
            $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HTTPAUTH'), parameter => $self->{constant_cb}->(name => 'CURLAUTH_ANY'));
            $self->{curl_log}->log('--anyauth');
        }
        my $userpassword = $options{request}->{username}  . ':' . $options{request}->{password};
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_USERPWD'), parameter => $userpassword);
        $self->{curl_log}->log('--user', $userpassword);
    }

    if (defined($options{request}->{cert_file}) &&  $options{request}->{cert_file} ne '') {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_SSLCERT'), parameter => $options{request}->{cert_file});
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_SSLKEY'), parameter => $options{request}->{key_file});
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_KEYPASSWD'), parameter => $options{request}->{cert_pwd});

        $self->{curl_log}->log('--cert', $options{request}->{cert_file});
        $self->{curl_log}->log('--key', $options{request}->{key_file});
        $self->{curl_log}->log('--pass', $options{request}->{cert_pwd}) if defined $options{request}->{cert_pwd} && $options{request}->{cert_pwd} ne '';
    }

    if (defined($options{request}->{cert_pkcs12})) {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_SSLCERTTYPE'), parameter => "P12");
        $self->{curl_log}->log('--cert-type', 'p12');
    } else {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_SSLCERTTYPE'), parameter => "PEM");
        # no curl_log call because PEM is the default value
    }
}

sub set_form {
    my ($self, %options) = @_;

    if (!defined($self->{form_loaded})) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Net::Curl::Form',
            error_msg => "Cannot load module 'Net::Curl::Form'."
        );
        $self->{form_loaded} = 1;
    }

    my $form = Net::Curl::Form->new();
    foreach (@{$options{form}}) {
        my %args = ();
        $args{ $self->{constant_cb}->(name => 'CURLFORM_COPYNAME()') } = $_->{copyname}
            if (defined($_->{copyname}));
        $args{ $self->{constant_cb}->(name => 'CURLFORM_COPYCONTENTS()') } = $_->{copycontents}
            if (defined($_->{copycontents}));
        $form->add(%args);

        $self->{curl_log}->log("--form-string", $_->{copyname}."=".$_->{copycontents})
            if defined($_->{copyname}) && defined($_->{copycontents});
    }

    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HTTPPOST()'), parameter => $form);
}

sub set_proxy {
    my ($self, %options) = @_;

    if (defined($options{request}->{proxyurl}) && $options{request}->{proxyurl} ne '') {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_PROXY'), parameter => $options{request}->{proxyurl});
        $self->{curl_log}->log("--proxy", $options{request}->{proxyurl});
    }

    if (defined($options{request}->{proxypac}) && $options{request}->{proxypac} ne '') {
        $self->{output}->add_option_msg(short_msg => 'Unsupported proxypac option');
        $self->{output}->option_exit();
    }
}

sub set_extra_curl_opt {
    my ($self, %options) = @_;

    my $entries = {};
    foreach (@{$options{request}->{curl_opt}}) {
        my ($key, $value) = split /=>/;
        $key = centreon::plugins::misc::trim($key);

        if (!defined($entries->{$key})) {
            $entries->{$key} = { val => [], constants => [], force_array => 0 };
        }

        $value = centreon::plugins::misc::trim($value);

        # Here we want to convert a string containing curl options into a single value or into
        # an array of values depending on whether it begins with '[' and ends with ']'.
        # We also remove the quotes.
        # for example:
        #
        # $opt = ["CURLOPT_SSL_VERIFYPEER =>[opt1,'opt2','opt3']"];
        # is converted to a Perl array like this:
        # $VAR1 = [
        #  'opt1',
        #  'opt2',
        #  'opt3'
        # ];
        #
        # $opt = [ "CURLOPT_SSL_VERIFYPEER => 'opt1'" ];
        # is converted to:
        # $VAR1 = 'opt1';
        if ($value =~ /^\[(.*)\]$/) {
            $entries->{$key}->{force_array} = 1;
            $value = centreon::plugins::misc::trim($1);
            push @{$entries->{$key}->{constants}}, map { $_ = centreon::plugins::misc::trim($_); s/^'(.*)'$/$1/; $_  } split ',', $value;
        } else {
            push @{$entries->{$key}->{constants}}, $value =~ /^'(.*)'$/ ? $1 : $value;
        }

        if ($value  =~ /^CURLOPT|CURL/) {
            $value = $self->{constant_cb}->(name => $value);
        }

        push @{$entries->{$key}->{val}}, $value; 
    }

    foreach (keys %$entries) {
        my $key = $_;

        if ($self->{curl_log}->is_enabled()) {
            $self->{curl_log}->convert_curlopt_to_cups_parameter(
                key => $key,
                parameter => $entries->{$key}->{constants},
            );
        }

        if (/^CURLOPT|CURL/) {
            $key = $self->{constant_cb}->(name => $_);
        }

        my $parameter;
        if ($entries->{$_}->{force_array} == 1 || scalar(@{$entries->{$_}->{val}}) > 1) {
            $parameter = $entries->{$_}->{val};
        } else {
            $parameter = pop @{$entries->{$_}->{val}};
        }
        $self->curl_setopt(option => $key, parameter => $parameter);

    }
}

sub cb_get_header {
    my ($easy, $header, $uservar) = @_;

    $header =~ s/[\r\n]//g;
    if ($header =~ /^[\r\n]*$/) {
        $uservar->{nheaders}++;
    } else {
        $uservar->{response_headers}->[$uservar->{nheaders}] = {}
            if (!defined($uservar->{response_headers}->[$uservar->{nheaders}]));
        if ($header =~  /^(\S(?:.*?))\s*:\s*(.*)/) {
            my $header_name = lc($1);
            $uservar->{response_headers}->[$uservar->{nheaders}]->{$header_name} = []
                if (!defined($uservar->{response_headers}->[$uservar->{nheaders}]->{$header_name}));
            push @{$uservar->{response_headers}->[$uservar->{nheaders}]->{$header_name}}, $2;
        } else {
           $uservar->{response_headers}->[$uservar->{nheaders}]->{response_line} = $header; 
        }
    }

    return length($_[1]);
}

sub request {
    my ($self, %options) = @_;

    # Enable curl logger when debug mode is on
    $self->{curl_log}->init( enabled => $self->{output}->is_debug() );

    if (!defined($self->{curl_easy})) {
        $self->{curl_easy} = Net::Curl::Easy->new();
    }

    my $url;
    if (defined($options{request}->{full_url})) {
        $url = $options{request}->{full_url};
    } elsif (defined($options{request}->{port}) && $options{request}->{port} =~ /^[0-9]+$/) {
        $url = $options{request}->{proto}. "://" . $options{request}->{hostname} . ':' . $options{request}->{port} . $options{request}->{url_path};
    } else {
        $url = $options{request}->{proto}. "://" . $options{request}->{hostname} . $options{request}->{url_path};
    }

    my $uri = URI->new($url);
    if (defined($options{request}->{get_params})) {
        $uri->query_form($options{request}->{get_params});
    }

    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_URL'), parameter => $uri);

    $self->{curl_log}->log($uri);

    if ($self->{output}->is_debug()) {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_DEBUGFUNCTION'), parameter => \&cb_debug);
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_DEBUGDATA'), parameter => $self);
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_VERBOSE'), parameter => 1);

        $self->{curl_log}->log('--verbose');
    }

    if (defined($options{request}->{timeout}) && $options{request}->{timeout} =~ /\d/) {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_TIMEOUT'), parameter => $options{request}->{timeout});
        $self->{curl_log}->log("--max-time", $options{request}->{timeout});
    }

    if (defined($options{request}->{cookies_file})) {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_COOKIEFILE'), parameter => $options{request}->{cookies_file});
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_COOKIEJAR'), parameter => $options{request}->{cookies_file});
        $self->{curl_log}->log('--cookie', $options{request}->{cookies_file});
        $self->{curl_log}->log('--cookie-jar', $options{request}->{cookies_file});
    }

    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_FOLLOWLOCATION'), parameter => 1);
    if (defined($options{request}->{no_follow})) {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_FOLLOWLOCATION'), parameter => 0);
    } else {
        $self->{curl_log}->log('-L');
    }

    if (defined($options{request}->{http_peer_addr}) && $options{request}->{http_peer_addr} ne '') {
        $url =~ /^(?:http|https):\/\/(.*?)(\/|\:|$)/;
        my $resolve = $1 . ':' . $options{request}->{port_force} . ':' . $options{request}->{http_peer_addr};
        $self->{curl_easy}->setopt(
            $self->{constant_cb}->(name => 'CURLOPT_RESOLVE'),
            [$resolve]
        );
        $self->{curl_log}->log('--resolve', $resolve);
    }    

    my $headers = [];
    my $content_type_forced = 0;
    foreach my $key (keys %{$options{request}->{headers}}) {
        my $header = $key . ':' . (defined($options{request}->{headers}->{$key}) ? $options{request}->{headers}->{$key} : '');
        push @$headers, $header;
        if ($key =~ /content-type/i) {
            $content_type_forced = 1;
        }
        $self->{curl_log}->log("-H", $header);
    }

    $self->set_method(%options, content_type_forced => $content_type_forced, headers => $headers);

    if (defined($options{request}->{form})) {
        $self->set_form(form => $options{request}->{form});
    }

    if (scalar(@$headers) > 0) {
        $self->{curl_easy}->setopt($self->{constant_cb}->(name => 'CURLOPT_HTTPHEADER'), $headers);
    }

    if (defined($options{request}->{cacert_file}) && $options{request}->{cacert_file} ne '') {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_CAINFO'), parameter => $options{request}->{cacert_file});
        $self->{curl_log}->log('--cacert', $options{request}->{cacert_file});
    }
    if (defined($options{request}->{insecure})) {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_SSL_VERIFYPEER'), parameter => 0);
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_SSL_VERIFYHOST'), parameter => 0);
        $self->{curl_log}->log('--insecure');
    }

    $self->set_auth(%options);
    $self->set_proxy(%options);
    $self->set_extra_curl_opt(%options);
    $self->{response_body} = '';
    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_FILE'), parameter => \$self->{response_body});
    $self->{nheaders} = 0;
    $self->{response_headers} = [{}];
    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HEADERDATA'), parameter => $self);
    $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_HEADERFUNCTION'), parameter => \&cb_get_header);

    if (defined($options{request}->{certinfo}) && $options{request}->{certinfo} == 1) {
        $self->curl_setopt(option => $self->{constant_cb}->(name => 'CURLOPT_CERTINFO'), parameter => 1);
        # no curl_log call because there is no equivalent in command line
    }

    $self->{response_code} = undef;

    if ($self->{curl_log}->is_enabled()) {
        $self->{output}->output_add(long_msg => 'curl request [curl backend]: ' . $self->{curl_log}->get_log());
    }

    eval {
        $self->{curl_easy}->perform();
    };
    if ($@) {
        my $err = $@;
        if (ref($@) eq "Net::Curl::Easy::Code") {
            my $num = $@;
            if ($num == $self->{constant_cb}->(name => 'CURLE_OPERATION_TIMEDOUT')) {
                $self->{response_code} = 450;
            }
        }

        if (!defined($self->{response_code})) {
            $self->{output}->add_option_msg(short_msg => 'curl perform error : ' . $err);
            $self->{output}->option_exit();
        }
    }

    $self->{response_code} = $self->{curl_easy}->getinfo($self->{constant_cb}->(name => 'CURLINFO_RESPONSE_CODE'))
        if (!defined($self->{response_code}));

    # Check response
    my $status = 'ok';
    if (defined($options{request}->{critical_status}) && $options{request}->{critical_status} ne '' &&
        $self->{output}->test_eval(test => $options{request}->{critical_status}, values => { code => $self->{response_code} })) {
        $status = 'critical';
    } elsif (defined($options{request}->{warning_status}) && $options{request}->{warning_status} ne '' &&
        $self->{output}->test_eval(test => $options{request}->{warning_status}, values => { code => $self->{response_code} })) {
        $status = 'warning';
    } elsif (defined($options{request}->{unknown_status}) && $options{request}->{unknown_status} ne '' &&
        $self->{output}->test_eval(test => $options{request}->{unknown_status}, values => { code => $self->{response_code} })) {
        $status = 'unknown';
    }

    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        my $short_msg = $self->{response_code} . ' ' . 
            (defined($http_code_explained->{$self->{response_code}}) ? $http_code_explained->{$self->{response_code}} : 'unknown');

        $self->{output}->output_add(
            severity => $status,
            short_msg => $short_msg
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    return $self->{response_body};
}

sub get_headers {
    my ($self, %options) = @_;

    my $headers = '';
    foreach (keys %{$self->{response_headers}->[$options{nheader}]}) {
        next if (/response_line/);
        foreach my $value (@{$self->{response_headers}->[$options{nheader}]->{$_}}) {
            $headers .= "$_: " . $value . "\n";
        }
    }

    return $headers;
}

sub get_first_header {
    my ($self, %options) = @_;

    if (!defined($options{name})) {
        return $self->get_headers(nheader => 0);
    }

    return undef
        if (!defined($self->{response_headers}->[0]->{ lc($options{name}) }));
    return wantarray ? @{$self->{response_headers}->[0]->{ lc($options{name}) }} : $self->{response_headers}->[0]->{ lc($options{name}) }->[0];
}

sub get_header {
    my ($self, %options) = @_;

    if (!defined($options{name})) {
        return $self->get_headers(nheader => -1);
    }

    return undef
        if (!defined($self->{response_headers}->[-1]->{ lc($options{name}) }));
    return wantarray ? @{$self->{response_headers}->[-1]->{ lc($options{name}) }} : $self->{response_headers}->[-1]->{ lc($options{name}) }->[0];
}

sub get_code {
    my ($self, %options) = @_;

    return $self->{response_code};
}

sub get_message {
    my ($self, %options) = @_;

    return defined($http_code_explained->{$self->{response_code}}) ? $http_code_explained->{$self->{response_code}} : 'Unknown code';
}

sub get_certificate {
    my ($self, %options) = @_;

    my $certs = $self->{curl_easy}->getinfo($self->{constant_cb}->(name => 'CURLINFO_CERTINFO'));
    return ('pem', $certs->[0]->{Cert});
}

sub get_times {
    my ($self, %options) = @_;

    # TIME_T = 7.61.0
    my $resolve = $self->{curl_easy}->getinfo($self->{constant_cb}->(name => 'CURLINFO_NAMELOOKUP_TIME'));
    my $connect = $self->{curl_easy}->getinfo($self->{constant_cb}->(name => 'CURLINFO_CONNECT_TIME'));
    my $appconnect = $self->{curl_easy}->getinfo($self->{constant_cb}->(name => 'CURLINFO_APPCONNECT_TIME'));
    my $start = $self->{curl_easy}->getinfo($self->{constant_cb}->(name => 'CURLINFO_STARTTRANSFER_TIME'));
    my $total = $self->{curl_easy}->getinfo($self->{constant_cb}->(name => 'CURLINFO_TOTAL_TIME'));
    my $times = {
        resolve => $resolve * 1000,
        connect => ($connect - $resolve) * 1000,
        transfer => ($total - $start) * 1000
    };
    if ($appconnect > 0) {
        $times->{tls} = ($appconnect - $connect) * 1000;
        $times->{processing} = ($start - $appconnect) * 1000;
    } else {
        $times->{processing} = ($start - $connect) * 1000;
    }

    return $times;
}

1;

__END__

=head1 NAME

HTTP Curl backend layer.

=head1 SYNOPSIS

HTTP Curl backend layer.

=head1 BACKEND CURL OPTIONS

=over 8

=item B<--curl-opt>

Set CURL Options (--curl-opt="CURLOPT_SSL_VERIFYPEER => 0" --curl-opt="CURLOPT_SSLVERSION => CURL_SSLVERSION_TLSv1_1" ).

=back

=head1 DESCRIPTION

B<http>.

=cut
