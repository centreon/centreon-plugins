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

package cloud::kubernetes::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use DateTime;
use JSON::XS;
use URI::Encode;

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
            'hostname:s'    => { name => 'hostname' },
            'port:s'        => { name => 'port' },
            'proto:s'       => { name => 'proto' },
            'token:s'       => { name => 'token' },
            'timeout:s'     => { name => 'timeout' },
            'limit:s'       => { name => 'limit' },
            'config-file:s' => { name => 'config_file' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) && $self->{option_results}->{timeout} =~ /(\d+)/ ? $1 : 10;
    $self->{token} = (defined($self->{option_results}->{token})) ? $self->{option_results}->{token} : '';
    $self->{limit} = (defined($self->{option_results}->{limit})) && $self->{option_results}->{limit} =~ /(\d+)/ ? $1 : 100;
 
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{token}) || $self->{token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --token option.");
        $self->{output}->option_exit();
    }
    
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings;

    $self->{output}->output_add(long_msg => "URL: '" . $self->{proto} . '://' . $self->{hostname} .
        ':' . $self->{port} . $options{url_path} . "'", debug => 1);

    my $response = $self->{http}->request(%options);

    if ($self->{http}->get_code() != 200) {
        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($response);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $response, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $response");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{code})) {
            $self->{output}->output_add(long_msg => "Error message: " . $decoded->{message}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "API return error code '" . $decoded->{code} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        } else {
            $self->{output}->output_add(long_msg => "Error message: " . $decoded, debug => 1);
            $self->{output}->add_option_msg(short_msg => "API return error code '" . $self->{http}->get_code() . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
    }    

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $response");
        $self->{output}->option_exit();
    }
    
    return $decoded;
}

sub request_api_paginate {
    my ($self, %options) = @_;

    my @items;
    my @get_param = ( 'limit=' . $self->{limit} );
    push @get_param, @{$options{get_param}} if (defined($options{get_param}));
    
    while (1) {
        my $response = $self->request_api(
            method => $options{method},
            url_path => $options{url_path},
            get_param => \@get_param
        );
        last if (!defined($response->{items}));
        push @items, @{$response->{items}};

        last if (!defined($response->{metadata}->{continue}));
        @get_param = ( 'limit=' . $self->{limit}, 'continue=' . $response->{metadata}->{continue} );
        push @get_param, @{$options{get_param}} if (defined($options{get_param}));
    }

    return \@items;
}

sub kubernetes_list_cronjobs {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/apis/batch/v1beta1/cronjobs');
    
    return $response;
}

sub kubernetes_list_daemonsets {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/apis/apps/v1/daemonsets');
    
    return $response;
}

sub kubernetes_list_deployments {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/apis/apps/v1/deployments');
    
    return $response;
}

sub kubernetes_list_events {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/api/v1/events');
    
    return $response;
}

sub kubernetes_list_ingresses {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/apis/extensions/v1beta1/ingresses');
    
    return $response;
}

sub kubernetes_list_namespaces {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/api/v1/namespaces');
    
    return $response;
}

sub kubernetes_list_nodes {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/api/v1/nodes');
    
    return $response;
}

sub kubernetes_list_rcs {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/api/v1/replicationcontrollers');
    
    return $response;
}

sub kubernetes_list_replicasets {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/apis/apps/v1/replicasets');
    
    return $response;
}

sub kubernetes_list_services {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/apis/v1/services');
    
    return $response;
}

sub kubernetes_list_statefulsets {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/apis/apps/v1/statefulsets');
    
    return $response;
}

sub kubernetes_list_pods {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/api/v1/pods');
    
    return $response;
}

sub kubernetes_list_pvs {
    my ($self, %options) = @_;
        
    my $response = $self->request_api_paginate(method => 'GET', url_path => '/api/v1/persistentvolumes');
    
    return $response;
}

1;

__END__

=head1 NAME

Kubernetes Rest API

=head1 SYNOPSIS

Kubernetes Rest API custom mode

=head1 REST API OPTIONS

Kubernetes Rest API

=over 8

=item B<--hostname>

Kubernetes API hostname.

=item B<--port>

API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--timeout>

Set HTTP timeout

=item B<--limit>

Number of responses to return for each list calls.

See https://kubernetes.io/docs/reference/kubernetes-api/common-parameters/common-parameters/#limit

=back

=head1 DESCRIPTION

B<custom>.

=cut
