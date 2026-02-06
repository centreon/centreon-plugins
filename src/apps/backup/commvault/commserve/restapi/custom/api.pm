#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::commvault::commserve::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc qw/json_encode/;
use MIME::Base64;

sub new {
    my ($class, %options) = @_;
    my $self = {};
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
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'url-path:s'     => { name => 'url_path' },
            'api-username:s' => { name => 'api_username',  default => '' },
            'api-password:s' => { name => 'api_password',  default => '' },
            'user-domain:s'  => { name => 'user_domain' },
            'timeout:s'      => { name => 'timeout' },
            'instance:s'     => { name => 'instance', default => 'default' },
            'cache-create'   => { name => 'cache_create' },
            'cache-use'      => { name => 'cache_use' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{cache_authent_token} = centreon::plugins::statefile->new(%options);

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
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/webconsole/api';
    $self->{api_username} = $self->{option_results}->{api_username};
    $self->{api_password} = $self->{option_results}->{api_password};

    $self->{use_authent_token} = $self->{option_results}->{api_username} eq '' && $self->{option_results}->{api_password} eq '';

    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{user_domain} = (defined($self->{option_results}->{user_domain})) ? $self->{option_results}->{user_domain} : '';
    $self->{cache_create} = $self->{option_results}->{cache_create};
    $self->{cache_use} = $self->{option_results}->{cache_use};

    $self->{output}->option_exit(short_msg => 'Need to specify hostname option.')
        if $self->{hostname} eq '';

    $self->{output}->option_exit(short_msg => "--api-username and --api-password must be set or both be unset")
        if !$self->{use_authent_token} && ($self->{api_username} eq '' || $self->{api_password} eq '');

    $self->{cache}->check_options(option_results => $self->{option_results});
    $self->{cache_authent_token}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;

    return $self->{hostname} . '_' . $self->{http}->get_port();
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub is_use_cache {
    my ($self, %options) = @_;

    return defined($self->{cache_use}) ? 1 : 0;
}

sub json_decode {
    my ($self, %options) = @_;

    $options{content} =~ s/\r//mg;
    return centreon::plugins::misc::json_decode($options{content}, output => $self->{output}, no_exit => 1);
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub load_authent_token {
    my ($self) = @_;

    my $has_cache_file = $self->{cache_authent_token}->read(statefile => 'commvault_commserve_cat_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{instance}));
    return (0, '', '') unless $has_cache_file;

    my $authent_token = $self->{cache_authent_token}->get(name => 'authentToken') // '';
    my $refresh_token = $self->{cache_authent_token}->get(name => 'refreshToken') // '';
    my $update_time = $self->{cache_authent_token}->get(name => 'update_time') // 0;

    return ($update_time, $authent_token, $refresh_token);
}

sub refresh_authent_token
{
    my ($self, %options) = @_;
    my $json_request = { accessToken => $options{authentToken}, refreshToken => $options{refreshToken} };

    $json_request = json_encode($json_request, output => $self->{output});

    my $exit_on_failed = $options{exit_on_failed} // 1;
    my ($content) = $self->{http}->request(
        method => 'POST',
        url_path => $self->{url_path} . '/V4/AccessToken/Renew',
        query_form_post => $json_request,
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    if ($self->{http}->get_code() != 200) {
        return ('', '') unless $exit_on_failed;
        my $message = $content && $content =~ /Message\":\"([^\"]+)\"/ ? $1 : $self->{http}->get_message();
        $self->{output}->option_exit(short_msg => "Cannot refresh token [code: '" . $self->{http}->get_code() . "'] [message: '$message']");
    }
    my ($accessToken, $refreshToken) = ('', '');
    # For some obscure reasons json flux is sometime invalid, so we have to extract values with regexp
    if ($content) {
        $accessToken = $1
            if $content =~ /accessToken\":\s*\"([^\"]+)\"/m;
        $refreshToken = $1
            if $content =~ /refreshToken\":\s*\"([^\"]+)\"/m;
    }

    $self->{output}->option_exit(short_msg => "Cannot extract tokens !")
        if $exit_on_failed && ($accessToken eq '' || $refreshToken eq '');

    return ($accessToken, $refreshToken);
}

sub write_authent_token {
    my ($self, %options) = @_;
    $self->{cache_authent_token}->write(
        data => { authentToken => $options{authentToken}, refreshToken => $options{refreshToken}, update_time => time() });
}

sub clean_legacy_token {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{legacy_token} = undef;
    $self->{http}->remove_header(key => 'Authorization');
}

sub get_legacy_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'commvault_commserve_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $legacy_token = $options{statefile}->get(name => 'access_token');

    # Token expires every 15 minutes
    if ($has_cache_file == 0 || !defined($legacy_token)) {
        my $json_request = {
            username => $self->{api_username},
            password => MIME::Base64::encode_base64($self->{api_password}, '')
        };
        $json_request->{domain} = $self->{user_domain} if ($self->{user_domain} ne '');

        my $encoded = json_encode($json_request, output => $self->{output});

        my ($content) = $self->{http}->request(
            method => 'POST',
            url_path => $self->{url_path} . '/Login',
            query_form_post => $encoded,
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            my $message = $content && $content =~ /Message\":\"([^\"]+)\"/ ? $1 : $self->{http}->get_message();
            $self->{output}->option_exit(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '$message']");
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{token})) {
            my $message = $content && $content =~ /Message\":\"([^\"]+)\"/ ? $1 : "Cannot get token";
            $self->{output}->add_option_msg(short_msg => $message);
            $self->{output}->option_exit();
        }

        $legacy_token = $decoded->{token};
        my $datas = {
            access_token => $legacy_token
        };
        $options{statefile}->write(data => $datas);
    }

    $self->{legacy_token} = $legacy_token;
    $self->{http}->add_header(key => 'Authtoken', value => $self->{legacy_token});
}

sub request_internal {
    my ($self, %options) = @_;

    $self->settings();
    my $authent_token = '';

    if ($self->{use_authent_token}) {
        (undef, $authent_token, undef) = $self->load_authent_token();

	$self->{output}->option_exit(short_msg => 'Tokens where not found. Please use the "token" mode first')
	    if $authent_token eq '';
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $authent_token);

    } elsif (!defined($self->{legacy_token})) {
        $self->get_legacy_token(statefile => $self->{cache});
    }

    my $content;

    # retries to handle token expiration
    for my $retry (1..2) {
        $content = $self->{http}->request(
            url_path => $self->{url_path} . $options{endpoint},
            get_param => $options{get_param},
            header => $options{header},
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );

        last if $self->{http}->get_code() >= 200 && $self->{http}->get_code() < 300;
        last if $self->{use_authent_token};

        # legacy mode with auth token
        # Maybe there is an issue with the token. So we retry.
        $self->clean_legacy_token(statefile => $self->{cache});
        $self->get_legacy_token(statefile => $self->{cache});
    }
    my $decoded = $self->json_decode(content => $content);

    $self->{output}->option_exit(short_msg => 'Error while retrieving data (add --debug option for detailed message)')
        unless defined $decoded;

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        my $message = $content && $content =~ /Message\":\"([^\"]+)\"/ ? $1 : $self->{http}->get_message();
        $self->{output}->option_exit(short_msg => $message);
    }

    return $decoded;
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_commvault_commserve_' . $options{type} . '_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $response = $self->{cache}->get(name => 'response');
    my $update_time = $self->{cache}->get(name => 'update_time');

    $self->{output}->option_exit(short_msg => 'Cache file missing')
        unless defined $response;

    return $response;
}

sub get_cache_file_update {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_commvault_commserve_' . $options{type} . '_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $update_time = $self->{cache}->get(name => 'update_time');
    return $update_time;
}

sub create_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_commvault_commserve_' . $options{type} . '_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    $self->{cache}->write(data => { response => $options{response}, update_time => time() });
    $self->{output}->output_add(
        severity => 'ok',
        short_msg => 'Cache file created successfully'
    );
    $self->{output}->display();
    $self->{output}->exit();
}

sub request {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(type => $options{type})
        if (defined($self->{cache_use}));

    my $response = $self->request_internal(
        endpoint => $options{endpoint}
    );

    $self->create_cache_file(type => $options{type}, response => $response)
        if (defined($self->{cache_create}));

    return $response;
}

sub request_jobs {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(type => 'jobs')
        if (defined($self->{cache_use}));

    my $lookup_time = $options{completed_job_lookup_time};
    if (defined($self->{cache_create})) {
        my $update_time = $self->get_cache_file_update(type => 'jobs');
        $lookup_time = 3600;
        if (defined($update_time)) {
            $lookup_time = time() - $update_time;
        }
    }

    my $offset = 0;

    my @items;
    while (1) {
        my $content = $self->request_internal(
            endpoint => $options{endpoint},
            get_param => ['completedJobLookupTime=' . $lookup_time],
            header => [ 'limit: 100', "offset: $offset" ]
        );
        push @items, @{$content->{jobs}};
        last if @items >= $content->{totalRecordsWithoutPaging} // 0;
        $offset += 100;
    }

    my $response = { jobs => \@items };

    $self->create_cache_file(type => 'jobs', response => $response)
        if (defined($self->{cache_create}));

    return $response;
}

sub request_paging {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(type => $options{type})
        if (defined($self->{cache_use}));

    my ($page_num, $page_count) = (1, 200);
    my $alerts = [];
    while (1) {
        my $results = $self->request_internal(
            endpoint => $options{endpoint},
            get_param => ['pageNo=' . $page_num, 'pageCount=' . $page_count],
            header => ['Cache-Control: private']
        );

        last if (!defined($results->{feedsList}));
        push @$alerts, @{$results->{feedsList}};
        last if ($results->{totalNoOfAlerts} < ($page_num * $page_count));
        $page_num++;
    }

    $self->create_cache_file(type => $options{type}, response => $alerts)
        if (defined($self->{cache_create}));

    return $alerts;
}

1;

__END__

=head1 NAME

Commvault API

=head1 SYNOPSIS

Commvault API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

API hostname.

=item B<--url-path>

API url path (default: '/webconsole/api')

=item B<--port>

API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

Set API username

=item B<--api-password>

Set API password

=item B<--instance>

Set instance name to differentiate cache files when --api-token and 'token' authentication are used (default: 'default').

=item B<--timeout>

Set HTTP timeout

=item B<--cache-create>

Create a cache file and quit.

=item B<--cache-use>

Use the cache file (created with --cache-create). 

=back

=head1 DESCRIPTION

B<custom>.

=cut
