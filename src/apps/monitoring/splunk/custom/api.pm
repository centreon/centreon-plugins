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

package apps::monitoring::splunk::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use DateTime;
use XML::LibXML::Simple;
use URI::Encode;
use JSON::XS;
use centreon::plugins::misc qw(value_of);
use Digest::MD5 qw(md5_hex);

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
        $options{options}->add_options(arguments =>  {
            'hostname:s'             => { name => 'hostname' },
            'url-path:s'             => { name => 'url_path' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'timeout:s'              => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'splunk-retries:s'       => { name => 'splunk_retries', default => 5 },
            'splunk-wait:s'          => { name => 'splunk_wait', default => 2 }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'XMLAPI OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8089;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{splunk_retries} = (defined($self->{option_results}->{splunk_retries})) ? $self->{option_results}->{splunk_retries} : 5;
    $self->{splunk_wait} = (defined($self->{option_results}->{splunk_wait})) ? $self->{option_results}->{splunk_wait} : 2;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
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

sub clean_session_token {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{http}->remove_header(key => 'Authorization');
    $self->{session_token} = undef;
}

sub convert_iso8601_to_epoch {
    my ($self, %options) = @_;
    
    if ($options{time_string} =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-]\d{4})/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            time_zone  => $7
        );

        my $epoch_time = $dt->epoch();
        return $epoch_time;
    }
    
    $self->{output}->add_option_msg(short_msg => "Wrong date format: $options{time_string}");
    $self->{output}->option_exit();

}


sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'X-Requested-By', value => $self->{requested_by});
    $self->{http}->add_header(key => 'Authorization', value => 'Splunk ' . $self->{session_token}) if defined($self->{session_token});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    $self->settings();
    my $has_cache_file = $options{statefile}->read(statefile => 'splunk_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $session_token = $options{statefile}->get(name => 'session_token');

    if ($has_cache_file == 0 || !defined($session_token)) {
        my $credentials = [
            'username=' . $self->{api_username},
            'password=' . $self->{api_password}
        ];

        my ($content) = $self->{http}->request(
            method => 'POST',
            url_path => '/services/auth/login',
            post_param => $credentials,
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "login error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $xml_result;
        eval {
            $SIG{__WARN__} = sub {};
            $xml_result = XMLin($content, ForceArray => $options{force_array}, KeyAttr => []);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
            $self->{output}->option_exit();
        }
        if (defined($xml_result->{XPathError})) {
            $self->{output}->add_option_msg(short_msg => "Api return error: " . $xml_result->{XPathError}->{Reason});
            $self->{output}->option_exit();
        }

        if (!defined($xml_result) || !defined($xml_result->{sessionKey})) {
            $self->{output}->add_option_msg(short_msg => 'error retrieving session_token');
            $self->{output}->option_exit();
        }

        $session_token = $xml_result->{sessionKey};

        my $datas = { session_token => $session_token };
        $options{statefile}->write(data => $datas);
    }

    return $session_token;
}

sub get_index_info {
    my ($self, %options) = @_;

    my $index_res_info = $self->request_api(
        method => 'GET',
        endpoint => '/services/data/indexes',
        get_param => ['count=-1']
    );    

    my @index_update_time;
    foreach (@{$index_res_info->{entry}}){
        next if (defined($_->{title}) && defined($options{index_name}) && $options{index_name} ne '' && $_->{title} !~ /$options{index_name}/);
        foreach my $attribute (@{$_->{content}->{'s:dict'}->{'s:key'}}){
            next if ($attribute->{name} ne 'maxTime' || !defined($attribute->{content}));
            my $epoch_time = ( time() - $self->convert_iso8601_to_epoch(time_string => $attribute->{content}) );
            push @index_update_time, { index_name => $_->{title}, ts_last_update => $epoch_time }
        }
    }

    return \@index_update_time;
}

sub get_splunkd_health {
    my ($self, %options) = @_;

    my $splunkd_health_details = $self->request_api(
        method => 'GET',
        endpoint => '/services/server/health/splunkd/details',
    );

    my @splunkd_features_health;
    foreach (@{$splunkd_health_details->{entry}->{content}->{'s:dict'}->{'s:key'}[1]->{'s:dict'}->{'s:key'}}){
        my $feature_name = $_->{name};
        $feature_name =~ s/ /-/g;
        foreach my $sub_feature (@{$_->{'s:dict'}->{'s:key'}}){
            next if $sub_feature->{name} ne 'health';
            push @splunkd_features_health, { feature_name => lc($feature_name), global_health => $sub_feature->{content} }
        }
    }

    return \@splunkd_features_health;
}

# Values may be in different locations depending on the field type.
# This function handles the supported cases.
sub get_value {
    my ($self, %options) = @_;

    my $record = $options{record};

    return '' unless ref $record eq 'HASH';

    # get first value only, we don't handle more complex structures
    return $record->{value}->[0]->{text} if ref $record->{value} eq 'ARRAY';

    # common case, single value
    return $record->{value}->{text} if $record->{value};

    # _raw case
    return $record->{v}->{content} if $record->{v};

    return '';
}

sub query_count {
    my ($self, %options) = @_;

    my $query = $options{query};
    $query .= '| stats count';

    my $query_sid = $self->request_api(
        method => 'POST',
        endpoint => '/services/search/jobs',
        post_param => [
            'search=' . $options{query} . '| stats count'
        ]
    );
    if (!defined($query_sid->{sid}) || $query_sid->{sid} eq ''){
        $self->{output}->add_option_msg(short_msg => "Error during process. No SID where returned after query was made. Please check your query and splunkd health.");
        $self->{output}->option_exit();
    }

    my $retries = 0;
    my $is_done = 0;

    while ($retries < $self->{http}->{options}->{splunk_retries}) {
        my $query_status = $self->request_api(
            method => 'GET',
            endpoint => '/services/search/jobs/' . $query_sid->{sid}
        );

        foreach (@{$query_status->{content}->{'s:dict'}->{'s:key'}}) {
            if ($_->{name} eq 'isDone' && $_->{content} == 1){
                $is_done = 1;
                last;
            } elsif ($_->{name} eq 'isFailed' && $_->{content} == 1) {
                $self->{output}->add_option_msg(short_msg => "Search command failed.");
                $self->{output}->option_exit();
            }
        }

        if ($is_done) {
            last;
        }

        $retries++;
        sleep($self->{http}->{options}->{splunk_wait});
    }

    # it took too long to run query
    $self->{output}->option_exit(short_msg => "Search command didn't finish in time. Considere tweaking --splunk-wait and --splunk-retries if the search is just slow")
        unless $is_done;

    my $query_res = $self->request_api(
        method => 'GET',
        endpoint => '/services/search/jobs/' . $query_sid->{sid} . '/results'
    );
    my $query_count = $query_res->{result}->{field}->{value}->{text};

    return $query_count;
}

sub query_value {
    my ($self, %options) = @_;

    my $query = $options{query};

    my @post_param = ( "search=$query" );

    push @post_param, "adhoc_search_level=$options{search_mode}"
        if $options{search_mode} && $options{search_mode} =~ /^(fast|smart|verbose)$/;

    my $query_sid = $self->request_api(
        method => 'POST',
        endpoint => '/services/search/jobs',
        post_param => \@post_param
    );
    if (!defined($query_sid->{sid}) || $query_sid->{sid} eq ''){
        $self->{output}->add_option_msg(short_msg => "Error during process. No SID where returned after query was made. Please check your query and splunkd health.");
        $self->{output}->option_exit();
    }

    my $retries = 0;
    my $is_done = 0;

    while ($retries < $self->{http}->{options}->{splunk_retries}) {
        my $query_status = $self->request_api(
            method => 'GET',
            endpoint => '/services/search/jobs/' . $query_sid->{sid}
        );

        foreach (@{$query_status->{content}->{'s:dict'}->{'s:key'}}) {
            if ($_->{name} eq 'isDone' && $_->{content} == 1){
                $is_done = 1;
                last;
            } elsif ($_->{name} eq 'isFailed' && $_->{content} == 1) {
                $self->{output}->option_exit(short_msg => "Search command failed.");
            }
        }

        last if $is_done;

        $retries++;
        sleep($self->{http}->{options}->{splunk_wait});
    }
    # it took too long to run query
    $self->{output}->option_exit(short_msg => "Search command didn't finish in time. Considere tweaking --splunk-wait and --splunk-retries if the search is just slow")
        unless $is_done;

    my $query_res = $self->request_api(
        method => 'GET',
        endpoint => '/services/search/jobs/' . $query_sid->{sid} . '/results'
    );

    return $query_res;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{session_token})) {
        $self->{session_token} = $self->get_access_token(statefile => $self->{cache});
    }
    $self->settings();

    my $content = $self->{http}->request(
        method => $options{method},
        url_path => $options{endpoint},
        get_param => $options{get_param},
        post_param => $options{post_param},
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    my $xml_result;
    if ($self->{http}->get_code() == 400) {
        eval {
            $SIG{__WARN__} = sub {};
            $xml_result = XMLin($content, ForceArray => $options{force_array}, KeyAttr => []);
        };
        if (value_of($xml_result, "->{messages}->{msg}->{type}") eq 'FATAL') {
            $self->{output}->add_option_msg(short_msg => "Error: ". value_of($xml_result, "->{messages}->{msg}->{content}", "-"));
            $self->{output}->option_exit();
        }
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session_token(statefile => $self->{cache});     
        $self->{session_token} = $self->get_access_token(statefile => $self->{cache});
        $self->settings();
        $content = $self->{http}->request(
            method => $options{method},
            url_path => $options{endpoint},
            get_param => $options{get_param},
            post_param => $options{post_param},
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    eval {
        $SIG{__WARN__} = sub {};
        $xml_result = XMLin($content, ForceArray => $options{force_array}, KeyAttr => []);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }
    if (defined($xml_result->{XPathError})) {
        $self->{output}->add_option_msg(short_msg => "Api return error: " . $xml_result->{XPathError}->{Reason});
        $self->{output}->option_exit();
    }

    return $xml_result;
}

1;

__END__

=head1 NAME

Splunk API.

=head1 SYNOPSIS

Splunk API custom mode.

=head1 XMLAPI OPTIONS

Splunk API.

=over 8

=item B<--hostname>

Splunk server address.

=item B<--port>

API port (default: 8089)

=item B<--proto>

Specify http if needed (default: 'https')

=item B<--api-username>

Specify api username.

=item B<--api-password>

Specify api password.

=item B<--timeout>

Set HTTP timeout.

=item B<--splunk-retries>

How many times we should retry queries to splunk. To use in par with the --splunk-wait paramater (default: 5) 

=item B<--splunk-wait>

How long (in seconds) should we wait between each retry. To use in par with the --splunk-retries paramater (default: 2)

=back

=head1 DESCRIPTION

B<custom>.

=cut
