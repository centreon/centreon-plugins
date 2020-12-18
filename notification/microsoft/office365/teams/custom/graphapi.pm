#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package notification::microsoft::office365::teams::custom::graphapi;

use strict;
use warnings;
use cloud::microsoft::office365::custom::graphapi;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
        "channel-id:s"                   => { name => 'channel_id'},
        "team-id:s"                      => { name => 'team_id'}
        });

$self = cloud::microsoft::office365::custom::graphapi->new(%options);

return $self;
}

sub check_options {
    my ($self, %options) = @_;
    if (!defined($self->{option_results}->{channel_id}) || $self->{option_results}->{channel_id} eq '') {
            $self->{output}->add_option_msg(short_msg => "You need to specify --channel-id option.");
            $self->{output}->option_exit();
        }
    if (!defined($self->{option_results}->{team_id}) || $self->{option_results}->{team_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --team-id option.");
        $self->{output}->option_exit();
    }
    $self->{teams}->{channel_id} = defined($self->{option_results}->{channel_id}) ? $self->{option_results}->{channel_id} : undef;
    $self->{teams}->{team_id} = defined($self->{option_results}->{team_id}) ? $self->{option_results}->{team_id} : undef;
}

sub teams_post_notification_set_url {
    my ($self, %options) = @_;

    my $url = $self->{graph_endpoint} . "/v1.0/teams/" . $self->{teams}->{team_id} . "/channels/" . $self->{teams}->{channel_id} . "/messages";

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