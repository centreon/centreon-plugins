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

package notification::slack::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

my %slack_color_host = (
    up => 'good',
    down => 'danger',
    unreachable => 'danger',
);
my %slack_color_service = (
    ok => 'good',
    warning => 'warning',
    critical => 'danger',
    unknown => 'warning',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "slack-url:s"           => { name => 'slack_url' },
        "slack-channel:s"       => { name => 'slack_channel' },
        "slack-username:s"      => { name => 'slack_username' },
        "host-name:s"           => { name => 'host_name' },
        "host-state:s"          => { name => 'host_state' },
        "host-output:s"         => { name => 'host_output' },
        "service-description:s" => { name => 'service_description' },
        "service-state:s"       => { name => 'service_state' },
        "service-output:s"      => { name => 'service_output' },
        "slack-color:s"         => { name => 'slack_color' },
        "slack-emoji:s"         => { name => 'slack_emoji', },
        "graph-url:s"           => { name => 'graph_url' },
        "priority:s"            => { name => 'priority' },
        "zone:s"                => { name => 'zone' },
        "link-url:s"            => { name => 'link_url' },
        "centreon-url:s"        => { name => 'centreon_url' },
        "centreon-token:s"      => { name => 'centreon_token' },
        "credentials"           => { name => 'credentials' },
        "basic"                 => { name => 'basic' },
        "ntlm"                  => { name => 'ntlm' },
        "username:s"            => { name => 'username' },
        "password:s"            => { name => 'password' },
        "timeout:s"             => { name => 'timeout' },
    });
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{payload_attachment} = { fields => [] }; 
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{slack_url}) || $self->{option_results}->{slack_url} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --slack-url option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{slack_channel}) || $self->{option_results}->{slack_channel} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --slack-channel option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{host_name}) || $self->{option_results}->{host_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --host-name option.");
        $self->{output}->option_exit();
    }
    
    foreach (('graph_url', 'link_url')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{option_results}->{$1}/g;
            eval "\$self->{option_results}->{\$_} = \"$self->{option_results}->{$_}\"";
        }
    }

    $self->{http}->set_options(%{$self->{option_results}}, hostname => 'dummy');
}

sub format_payload {
    my ($self, %options) = @_;
    
    my $json = JSON->new;
    my $payload = { channel => $self->{option_results}->{slack_channel},
                    attachments => [ $self->{payload_attachment} ] };
    if (defined($self->{option_results}->{slack_emoji}) && $self->{option_results}->{slack_emoji} ne '') {
        $payload->{icon_emoji} = $self->{option_results}->{slack_emoji};
    }
    if (defined($self->{option_results}->{slack_username}) && $self->{option_results}->{slack_username} ne '') {
        $payload->{username} = $self->{option_results}->{slack_username};
    }
    eval {
        $self->{payload_str} = $json->encode($payload);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
}

sub host_message {
    my ($self, %options) = @_;
    
    my $url_host = $self->{option_results}->{host_name};
    $self->{payload_attachment}->{fallback} = "Host " . $self->{option_results}->{host_name};
    if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $url_host = '<' . $self->{option_results}->{link_url} . '|' . $self->{option_results}->{host_name} . '>';
    }
    $self->{payload_attachment}->{text} = "Host " . $url_host;
    
    if (defined($self->{option_results}->{host_state}) && $self->{option_results}->{host_state} ne '') {
        $self->{payload_attachment}->{text} .= ' is ' . $self->{option_results}->{host_state};
        $self->{payload_attachment}->{fallback} .= ' is ' . $self->{option_results}->{host_state};
        if (defined($slack_color_host{lc($self->{option_results}->{host_state})})) {
            $self->{payload_attachment}->{color} = $slack_color_host{lc($self->{option_results}->{host_state})};
        }
    } else {
        $self->{payload_attachment}->{text} .= ' alert';
        $self->{payload_attachment}->{fallback} .= ' alert';
    }
    
    if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $self->{payload_attachment}->{fallback} .= ' : ' . $self->{option_results}->{link_url};
    }
    
    if (defined($self->{option_results}->{host_output}) && $self->{option_results}->{host_output} ne '') {
        push @{$self->{payload_attachment}->{fields}}, { title => 'output', value => $self->{option_results}->{host_output}, short => 'true' };
    }
    if (defined($self->{option_results}->{host_state}) && $self->{option_results}->{host_state} ne '') {
        push @{$self->{payload_attachment}->{fields}}, { title => 'State', value => $self->{option_results}->{host_state}, short => 'true'};
    }
}

sub service_message {
    my ($self, %options) = @_;
    
    my $url_service = "Host: " . $self->{option_results}->{host_name} . " | Service " . $self->{option_results}->{service_description};
    $self->{payload_attachment}->{fallback} = $url_service;
    if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $url_service = '<' . $self->{option_results}->{link_url} . '|' . $self->{option_results}->{host_name} . '/' . $self->{option_results}->{service_description} . '>';
        $self->{payload_attachment}->{fallback} = "Service " . $self->{option_results}->{host_name} . '/' . $self->{option_results}->{service_description};
    }
    $self->{payload_attachment}->{text} = $url_service;
    
    if (defined($self->{option_results}->{service_state}) && $self->{option_results}->{service_state} ne '') {
        $self->{payload_attachment}->{text} .= ' is ' . $self->{option_results}->{service_state};
        $self->{payload_attachment}->{fallback} .= ' is ' . $self->{option_results}->{service_state};
        if (defined($slack_color_service{lc($self->{option_results}->{service_state})})) {
            $self->{payload_attachment}->{color} = $slack_color_service{lc($self->{option_results}->{service_state})};
        }
    } else {
        $self->{payload_attachment}->{text} .= ' alert';
        $self->{payload_attachment}->{fallback} .= ' alert';
    }
    
    if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $self->{payload_attachment}->{fallback} .= ' : ' . $self->{option_results}->{link_url};
    }
    
    if (defined($self->{option_results}->{service_output}) && $self->{option_results}->{service_output} ne '') {
        push @{$self->{payload_attachment}->{fields}}, { title => 'output', value => $self->{option_results}->{service_output} };
    }
    
    if (defined($self->{option_results}->{graph_url}) && $self->{option_results}->{graph_url} ne '') {
        $self->{payload_attachment}->{image_url} = $self->{option_results}->{graph_url};
    }
    if (defined($self->{option_results}->{service_state}) && $self->{option_results}->{service_state} ne '') {
        push @{$self->{payload_attachment}->{fields}}, { title => 'State', value => $self->{option_results}->{service_state}, short => 'true'};
    }
}

sub set_payload {
    my ($self, %options) = @_;
        
    if (defined($self->{option_results}->{service_description}) && $self->{option_results}->{service_description} ne '') {
        $self->service_message();
    } else {
        $self->host_message();
    }

    if (defined($self->{option_results}->{slack_color}) && $self->{option_results}->{slack_color} ne '') {
        $self->{payload_attachment}->{color} = $self->{option_results}->{slack_color};
    }
    
    if (defined($self->{option_results}->{priority}) && $self->{option_results}->{priority} ne '') {
        push @{$self->{payload_attachment}->{fields}}, { title => 'Priority', value => $self->{option_results}->{priority}, short => 'true' };
    }
    if (defined($self->{option_results}->{zone}) && $self->{option_results}->{zone} ne '') {
        push @{$self->{payload_attachment}->{fields}}, { title => 'Zone', value => $self->{option_results}->{zone}, short => 'true' };
    }
}

sub run {
    my ($self, %options) = @_;

    $self->set_payload();
    $self->format_payload();
    my $response = $self->{http}->request(full_url => $self->{option_results}->{slack_url}, 
                                          method => 'POST', 
                                          post_param => ['payload=' . $self->{payload_str}]);
    
    $self->{output}->output_add(short_msg => 'slack response: ' . $response);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send slack alerts.

Example for a host:
centreon_plugins.pl --plugin=notification::slack::plugin --mode=alert --slack-url='https://hooks.slack.com/services/T0A754E2V/B0E0CEL4B/81V8kCJusL7kafDSdsd' --slack-channel='#testchannel' --slack-username='bot' --slack-emoji=':ghost:' --host-name='srvi-clus-win' --host-state='DOWN' --host-output='test output' --priority='High' --zone='Production' --centreon-url='https://centreon.test.com/centreon/' --link-url='%{centreon_url}/main.php?p=20202&o=svc&host_search=%{host_name}'

Example for a service:
centreon_plugins.pl --plugin=notification::slack::plugin --mode=alert --slack-url='https://hooks.slack.com/services/T0A754E2V/B0E0CEL4B/81V8kCJusL7kafDSdsd' --slack-channel='#tmptestqga' --slack-username='bot' --slack-emoji=':ghost:' --host-name='srvi-clus-win' --service-description='Ping' --service-state='WARNING' --service-output='CRITICAL - 10.50.1.78: rta nan, lost 100%' --priority='High' --zone='Production' --centreon-url='https://ces.merethis.net/centreon/' --link-url='%{centreon_url}/main.php?p=20201&o=svc&host_search=%{host_name}&svc_search=%{service_description}' --centreon-token='LxTQxFbLU6' --graph-url='%{centreon_url}/include/views/graphs/generateGraphs/generateImage.php?username=myuser&token=%{centreon_token}&hostname=%{host_name}&service=%{service_description}'

=over 8

=item B<--slack-url>

Specify slack url (Required).

=item B<--slack-channel>

Specify slack channel (Required).

=item B<--slack-username>

Specify slack username.

=item B<--host-name>

Specify host server name for the alert (Required).

=item B<--host-state>

Specify host server state for the alert.

=item B<--host-output>

Specify host server output message for the alert.

=item B<--service-description>

Specify service description name for the alert.

=item B<--service-state>

Specify service state for the alert.

=item B<--service-output>

Specify service output message for the alert.

=item B<--slack-color>

Specify slack color (According state option, color will be choosed).

=item B<--slack-emoji>

Specify slack emoji.

=item B<--priority>

Specify the priority message.

=item B<--zone>

Specify the zone message.

=item B<--centreon-url>

Specify the centreon url macro (could be used in link-url and graph-url option).

=item B<--centreon-token>

Specify the centreon token for autologin macro (could be used in link-url and graph-url option).

=item B<--graph-url>

Specify the graph url (Example: %{centreon_url}/include/views/graphs/generateGraphs/generateImage.php?username=myuser&token=%{centreon_token}&hostname=%{host_name}&service=%{service_description}).

=item B<--link-url>

Specify the link url (Example: %{centreon_url}/main.php?p=20201&o=svc&host_search=%{host_name}&svc_search=%{service_description})

=item B<--credentials>

Specify this option if you access webpage with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access webpage over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access webpage over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
