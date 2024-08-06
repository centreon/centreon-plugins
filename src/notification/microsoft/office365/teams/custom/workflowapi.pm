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

package notification::microsoft::office365::teams::custom::workflowapi;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self              = {};
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
            'teams-workflow:s' => { name => 'teams_workflow' },
            'port:s'           => { name => 'port' },
            'proto:s'          => { name => 'proto' },
            'timeout:s'        => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http}   = centreon::plugins::http->new(%options);

    return $self;
}

sub set_defaults {}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
}

sub check_options {
    my ($self, %options) = @_;

    $self->{teams_workflow} = (defined($self->{option_results}->{teams_workflow})) ? $self->{option_results}->{teams_workflow} : '';
    $self->{proto}          = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port}           = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{timeout}        = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;

    if ($self->{teams_workflow} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify the --teams-workflow option.');
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}}, hostname => 'dummy');

    return 0;
}

sub json_decode {
    my ($self, %options) = @_;

    $options{content} =~ s/\r//mg;
    my $decoded;
    eval {
        $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub teams_post_notification {
    my ($self, %options) = @_;

    my $encoded_data = JSON::XS->new->utf8->encode($options{json_request});

    my $content = $self->{http}->request(
        method          => 'POST',
        full_url        => $self->{teams_workflow},
        query_form_post => $encoded_data
    );

    return $content;
}

1;

__END__

=head1 NAME

O365 Teams Workflows API

=head1 SYNOPSIS

O365 Teams Workflows API

=head1 REST API OPTIONS

=over 8

=item B<--teams-workflow>

Define the Workflow full URI (required).

=item B<--port>

Define the API port (default: 443).

=item B<--proto>

Define the protocol if needed (default: 'https').

=item B<--timeout>

Define the HTTP timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
