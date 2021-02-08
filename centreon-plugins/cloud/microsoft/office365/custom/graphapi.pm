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

package cloud::microsoft::office365::custom::graphapi;

use strict;
use warnings;
use DateTime;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Text::CSV;
use Encode;
use URI::Encode;
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
        $options{options}->add_options(arguments => {
            'tenant:s'         => { name => 'tenant' },
            'client-id:s'      => { name => 'client_id' },
            'client-secret:s'  => { name => 'client_secret' },
            'login-endpoint:s' => { name => 'login_endpoint' },
            'graph-endpoint:s' => { name => 'graph_endpoint' },
            'timeout:s'        => { name => 'timeout' }
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

    $self->{tenant} = (defined($self->{option_results}->{tenant})) ? $self->{option_results}->{tenant} : undef;
    $self->{client_id} = (defined($self->{option_results}->{client_id})) ? $self->{option_results}->{client_id} : undef;
    $self->{client_secret} = (defined($self->{option_results}->{client_secret})) ? $self->{option_results}->{client_secret} : undef;
    $self->{login_endpoint} = (defined($self->{option_results}->{login_endpoint})) ? $self->{option_results}->{login_endpoint} : 'https://login.microsoftonline.com';
    $self->{graph_endpoint} = (defined($self->{option_results}->{graph_endpoint})) ? $self->{option_results}->{graph_endpoint} : 'https://graph.microsoft.com';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;

    if (!defined($self->{tenant}) || $self->{tenant} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --tenant option.");
        $self->{output}->option_exit();
    }
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

    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    if (defined($self->{access_token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'office365_graphapi_' . md5_hex($self->{tenant}) . '_' . md5_hex($self->{client_id}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');

    if ($has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        my $uri = URI::Encode->new({encode_reserved => 1});
        my $encoded_client_secret = $uri->encode($self->{client_secret});
        my $encoded_graph_endpoint = $uri->encode($self->{graph_endpoint} . '/.default');
        my $post_data = 'grant_type=client_credentials' . 
            '&client_id=' . $self->{client_id} .
            '&client_secret=' . $encoded_client_secret .
            '&scope=' . $encoded_graph_endpoint;
        
        $self->settings();

        my $content = $self->{http}->request(method => 'POST', query_form_post => $post_data,
                                             full_url => $self->{login_endpoint} . '/' . $self->{tenant} . '/oauth2/v2.0/token',
                                             hostname => '');

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error_description}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Login endpoint API return error code '" . $decoded->{error} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{access_token}, expires_on => time() + $decoded->{expires_in} };
        $options{statefile}->write(data => $datas);
    }
    
    return $access_token;
}

sub request_api_json { #so lame for now
    my ($self, %options) = @_;

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings();

    my @results;
    my %local_options = %options;

    while (1) {
        $self->{output}->output_add(long_msg => "URL: '" . $local_options{full_url} . "'", debug => 1);

        my $content = $self->{http}->request(%local_options);

        if ($self->{http}->get_code() == 429) {
            last;
        }
        
        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}->{message}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Graph endpoint API return error code '" . $decoded->{error}->{code} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
        push @results, @{$decoded->{value}};
        
        last if (!defined($decoded->{'@odata.nextLink'}));
        $local_options{full_url} = $decoded->{'@odata.nextLink'};
    }

    return @results;
}

sub request_api_csv {
    my ($self, %options) = @_;

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings();

    $self->{output}->output_add(long_msg => "URL: '" . $options{full_url} . "'", debug => 1);

    my $content = $self->{http}->request(%options);
    
    if ($self->{http}->get_code() != 200) {
        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}->{message}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Graph endpoint API return error code '" . $decoded->{error}->{code} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
    }    
    
    my $decoded;
    eval {
        $decoded = decode('UTF-8', $content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response: $@");
        $self->{output}->option_exit();
    }
    $decoded =~ s/^\x{feff}//;

    my @rows;
    eval {
        open my $fh, '<', \$decoded;
        my $csv = Text::CSV->new({ binary => 1 });
        $csv->column_names($csv->getline($fh));
        while (my $row = $csv->getline_hr($fh)) {
            push @rows, $row;
        }
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot parse csv response: $@");
        $self->{output}->option_exit();
    }
    
    return \@rows;
}

sub office_get_sharepoint_site_usage_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getSharePointSiteUsageDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_sharepoint_site_usage {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_sharepoint_site_usage_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_sharepoint_activity_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getSharePointActivityUserDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_sharepoint_activity {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_sharepoint_activity_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_onedrive_usage_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getOneDriveUsageAccountDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_onedrive_usage {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_onedrive_usage_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
}

sub office_get_onedrive_activity_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getOneDriveActivityUserDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_onedrive_activity {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_onedrive_activity_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_exchange_activity_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getEmailActivityUserDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_exchange_activity {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_exchange_activity_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_exchange_mailbox_usage_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getMailboxUsageDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_exchange_mailbox_usage {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_exchange_mailbox_usage_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_teams_activity_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getTeamsUserActivityUserDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_teams_activity {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_teams_activity_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_teams_device_usage_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getTeamsDeviceUsageUserDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_teams_device_usage {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_teams_device_usage_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_skype_activity_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getSkypeForBusinessActivityUserDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_skype_activity {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_skype_activity_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub office_get_skype_device_usage_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/reports/getSkypeForBusinessDeviceUsageUserDetail(" . $options{param} . ")";

    return $url;
}

sub office_get_skype_device_usage {
    my ($self, %options) = @_;

    my $full_url = $self->office_get_skype_device_usage_set_url(%options);
    my $response = $self->request_api_csv(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response;
}

sub teams_post_notification_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/teams/" . $options{team_id} . "/channels/" . $options{channel_id} . "/messages";

    return $url;
}

sub teams_post_notification {
    my ($self, %options) = @_;

    my $encoded_data = JSON::XS->new->utf8->encode($options{json_request});
    my $full_url = $self->teams_post_notification_set_url(%options);
    my $response = $self->request_api_json(method => 'POST', full_url => $full_url, hostname => '', query_form_post => $encoded_data);

    return $response;
}

1;

__END__

=head1 NAME

Microsoft Office 365 Graph API

=head1 REST API OPTIONS

Microsoft Office 365 Graph API

To connect to the Office 365 Graph API, you must register an application.

Follow the 'How-to guide' in https://docs.microsoft.com/en-us/graph/auth-register-app-v2?view=graph-rest-1.0

This custom mode is using the 'OAuth 2.0 Client Credentials Grant Flow'.

=over 8

=item B<--tenant>

Set Office 365 tenant ID.

=item B<--client-id>

Set Office 365 client ID.

=item B<--client-secret>

Set Office 365 client secret.

=item B<--login-endpoint>

Set Office 365 login endpoint URL (Default: 'https://login.microsoftonline.com')

=item B<--graph-endpoint>

Set Office 365 graph endpoint URL (Default: 'https://graph.microsoft.com')

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
