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

package apps::monitoring::kadiska::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use Date::Parse;
use JSON::XS;

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
            'client-id:s'      => { name => 'client_id' },
            'client-secret:s'  => { name => 'client_secret' },
            'hostname:s'       => { name => 'hostname' },
            'port:s'           => { name => 'port' },
            'proto:s'          => { name => 'proto' },
            'period:s'         => { name => 'period' },
            'timeout:s'        => { name => 'timeout' },
            'url-path:s'       => { name => 'url_path' }
        });
    }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'app.kadiska.com';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{period} = (defined($self->{option_results}->{period})) ? $self->{option_results}->{period} : '15';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/api/v1/';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{client_id} = (defined($self->{option_results}->{client_id})) ? $self->{option_results}->{client_id} : '';
    $self->{client_secret} = (defined($self->{option_results}->{client_secret})) ? $self->{option_results}->{client_secret} : '';

    if (!defined($self->{client_id}) || $self->{client_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{client_secret}) || $self->{client_secret} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-secret option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    
    return 0;
   
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token}) if defined($self->{access_token});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_access_token {
    my ($self, %options) = @_;

    my $datas = { last_timestamp => time() };
    $options{statefile}->write(data => $datas);
    $self->{http}->remove_header(key => 'Authorization');
    $self->{access_token} = undef;
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'kadiska_' . md5_hex($self->{hostname}) . '_' . md5_hex($self->{client_id}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');

    if ( $has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        my $credentials = { 'client_id' => $self->{client_id}, 'secret' => $self->{client_secret} };
        my $post_json = JSON::XS->new->utf8->encode($credentials);

        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            query_form_post => $post_json,
            url_path => $self->{url_path} . "config/clients/" . $self->{client_id} . "/tokens"
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

        $access_token = $decoded->{token};
        my $expiration_time = $decoded->{expiration_time};
        my $datas = { last_timestamp => time(), access_token => $access_token, expires_on => str2time($expiration_time) };
        $options{statefile}->write(data => $datas);
    }
    
    return $access_token;
}

sub forge_select {
    my ($self, %options) = @_;

    my %filters;
    $filters{gateway_name} = $options{gateway_name} if defined($options{gateway_name}) && $options{gateway_name} ne '';
    $filters{site_name} = $options{site_name} if defined($options{site_name}) && $options{site_name} ne '';
    $filters{watcher_name} = $options{watcher_name} if defined($options{watcher_name}) && $options{watcher_name} ne '';
    $filters{wfa} = 1 if ($options{wfa} eq 'yes');

    my $multiple = scalar(keys %filters);
    my @filter = ();
    foreach my $filter_name (keys %filters) {
        my @entry;
        if ($filter_name eq 'wfa') {
            @entry = $multiple > 1 ? (["=", "wfa", \1]) : ("=", "wfa", \1);
        } else {
            @entry = $multiple > 1 ? (["=", $filter_name, ['$', $filters{$filter_name}]]) : ("=", $filter_name, ['$', $filters{$filter_name}]);
        }

        unshift(@filter, @entry);
    }
    
    if ($multiple > 1) {
        unshift(@filter, 'and');
    }

    return \@filter;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings();

    my $encoded_form_post;

    my $end = time() * 1000;
    my $begin = ($end - (60 * $self->{period} * 1000));

    $options{query_form_post}->{begin} = $begin;
    $options{query_form_post}->{end} = $end;

    eval {
        $encoded_form_post = JSON::XS->new->utf8->encode($options{query_form_post});
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    my ($content) = $self->{http}->request(
        method => 'POST',
        url_path => $self->{url_path} . $options{endpoint},
        query_form_post => $encoded_form_post,
    );

    if ($self->{http}->get_code() == 429){
        $self->{output}->add_option_msg(short_msg => "[code: 429] Too many requests.");
        $self->{output}->option_exit();
    }


    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;

    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };


    if (defined($decoded->{error_code})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{error_code} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    
    return $decoded;
}

1;

__END__

=head1 NAME

Kadiska Rest API.

=head1 REST API OPTIONS

Kadiska Rest API.

=over 8

=item B<--hostname>

Set hostname (default: 'app.kadiska.com').

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--period>

Set period in minutes from which you want to get information. (default: '15')
Example: --period=60 would return you the data from last hour.  

=item B<--client-id>

Set client id.

=item B<--client-secret>

Set client secret.

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=cut
