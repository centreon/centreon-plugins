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

package database::elasticsearch::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use URI::Escape;
use JSON::XS;
use centreon::plugins::misc qw/value_of/;

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
            'hostname:s' => { name => 'hostname', default => '' },
            'port:s'     => { name => 'port', default => 9200 },
            'proto:s'    => { name => 'proto', default => 'https' },
            'username:s' => { name => 'username', default => '' },
            'password:s' => { name => 'password', default => '' },
            'timeout:s'  => { name => 'timeout', default => 10 }
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
    $self->{$_} = $self->{option_results}->{$_} for qw/hostname port proto username password timeout/;
 
    $self->{output}->option_exit(short_msg => "Need to specify hostname option.")
        if $self->{hostname} eq '';

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};

    if (defined($self->{username}) && $self->{username} ne '') {
        $self->{option_results}->{credentials} = 1;
        $self->{option_results}->{basic} = 1;
        $self->{option_results}->{username} = $self->{username};
        $self->{option_results}->{password} = $self->{password};
    }
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub search {
    my ($self, %options) = @_;

    $self->settings();

    my $query = $options{query};

    my $response;
    my $pretty = $self->{output}->is_debug() ?
                    'pretty' :
                    '';

    my $path = ( $options{index} ne '' ?
                   '/'.$options{index} :
                   ''
               ).'/_search';


    # If query contains json object we use POST otherwise it's a simple query and we use GET
    my $json = $query =~ /^[\t\s]*\{/;

    if ($json) {
        $response = $self->{http}->request( method => 'POST',
                                            url_path => "$path?$pretty",
                                            query_form_post => $query,
                                            header => [ "Content-Type: application/json" ],
                                            critical_status => '', warning_status => '');
    } else {
        $response = $self->{http}->request( method => 'GET',
                                            url_path => $path.'?q='.uri_escape($query)."&$pretty",
                                            critical_status => '', warning_status => '');

    }

    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };

    $self->{output}->option_exit(exit_litteral => 'critical', short_msg => "Cannot decode json response: $@")
        if $@;

    if ($content->{error}) {
        my $error;
        foreach ('->{caused_by}->{reason}', '->{reason}', '->{root_cause}->[0]->{reason}') {
            $error = value_of($content, "->{error}$_", '');
            last if $error ne '';
        }
        $self->{output}->option_exit(exit_litteral => 'critical',
                                     short_msg => "Cannot get data: " . ($error || 'Unkown'));
    }

    return $content;
}


sub get {
    my ($self, %options) = @_;

    $self->settings();

    my $response = $self->{http}->request(url_path => $options{path}, critical_status => '', warning_status => '');
    
    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (defined($content->{errmsg})) {
        $self->{output}->add_option_msg(short_msg => "Cannot get data: " . $content->{errmsg});
        $self->{output}->option_exit();
    }
    
    return $content;
}

1;

__END__

=head1 NAME

Elasticsearch REST API

=head1 SYNOPSIS

Elasticsearch Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Elasticsearch hostname.

=item B<--port>

Port used (default: 9200)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--username>

Elasticsearch username.

=item B<--password>

Elasticsearch password.

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
