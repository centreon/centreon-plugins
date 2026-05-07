#
# Copyright 2026-Now Centreon (http://www.centreon.com/)
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

package notification::telegram::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use URI::Encode;

my %telegram_icon_host = (
    up => "\x{2705}",
    down => "\x{1F525}",
    unreachable => "\x{2753}",
);
my %telegram_icon_service = (
    ok => "\x{2705}",
    warning => "\x{26A0}",
    critical => "\x{1F525}",
    unknown => "\x{2753}",
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"            => { name => 'hostname', default => 'api.telegram.org' },
        "port:s"                => { name => 'port', default => 443 },
        "proto:s"               => { name => 'proto', default => 'https' },
        "urlpath:s"             => { name => 'url_path', default => "/sendMessage" },
        "chat-id:s"             => { name => 'chat_id' },
        "bot-token:s"           => { name => 'bot_token' },
        "host-name:s"           => { name => 'host_name' },
        "host-state:s"          => { name => 'host_state' },
        "host-output:s"         => { name => 'host_output' },
        "service-description:s" => { name => 'service_description' },
        "service-state:s"       => { name => 'service_state' },
        "service-output:s"      => { name => 'service_output' },
        "graph-url:s"           => { name => 'graph_url' },
        "link-url:s"            => { name => 'link_url' },
        "centreon-url:s"        => { name => 'centreon_url' },
        "centreon-token:s"      => { name => 'centreon_token' },
        "action-links"          => { name => 'action_links' },
        "legacy"                => { name => 'legacy' },
        "timeout:s"             => { name => 'timeout' }
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{chat_id})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --chat-id option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{bot_token})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --bot-token option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{host_name}) || $self->{option_results}->{host_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --host-name option.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{action_links})) {
        if (!defined($self->{option_results}->{centreon_url}) || $self->{option_results}->{centreon_url} eq '') {
            $self->{output}->add_option_msg(short_msg => "Please set --centreon-url option when using --action-links");
            $self->{output}->option_exit();
        }
    }

    foreach (('graph_url', 'link_url')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/$self->{option_results}->{$1}/eg;
        }
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

# Build the URL path pointing to the new Resources Status page (/monitoring/resources),
# with a pre-filled JSON filter for the host and/or service.
sub build_resource_status_filters {
    my ($self, %options) = @_;

    my $data_format = URI::Encode->new({ encode_reserved => 1 });

    my $raw_resource_status_filters = {
        "id"        => "",
        "name"      => "New+filter",
        "criterias" => [
            {
                "name"        => "resource_types",
                "object_type" => undef,
                "type"        => "multi_select",
                "value"       => [
                    {
                        "id"   => "service",
                        "name" => "Service"
                    }
                ]
            },
            {
                "name"        => "states",
                "object_type" => undef,
                "type"        => "multi_select",
                "value"       => []
            },
            {
                "name"        => "statuses",
                "object_type" => undef,
                "type"        => "multi_select",
                "value"       => []
            },
            {
                "name"        => "status_types",
                "object_type" => undef,
                "type"        => "multi_select",
                "value"       => []
            },
            {
                "name"        => "host_groups",
                "object_type" => "host_groups",
                "type"        => "multi_select",
                "value"       => []
            },
            {
                "name"        => "service_groups",
                "object_type" => "service_groups",
                "type"        => "multi_select",
                "value"       => []
            },
            {
                "name"        => "monitoring_servers",
                "object_type" => "monitoring_servers",
                "type"        => "multi_select",
                "value"       => []
            },
            {
                "name"        => "search",
                "object_type" => undef,
                "type"        => "text",
                "value"       => sprintf(
                    's.description:%s h.name:%s',
                    defined($self->{option_results}->{service_description}) ? $self->{option_results}->{service_description} : '',
                    defined($self->{option_results}->{host_name})           ? $self->{option_results}->{host_name}           : ''
                )
            },
            {
                "name"        => "sort",
                "object_type" => undef,
                "type"        => "array",
                "value"       => [ "status_severity_code", "asc" ]
            }
        ]
    };

    my $link_url_path           = '/monitoring/resources?filter=';
    my $encoded_filters         = JSON::XS->new->utf8->encode($raw_resource_status_filters);
    my $encoded_data_for_uri    = $data_format->encode($encoded_filters);
    $link_url_path             .= $encoded_data_for_uri;

    return $link_url_path;
}

sub build_action_links {
    my ($self, %options) = @_;

    return unless defined($self->{option_results}->{action_links});

    my $resource_type = (defined($self->{option_results}->{service_description})
                         && $self->{option_results}->{service_description} ne '')
                        ? 'service' : 'host';

    my $uri          = URI::Encode->new({ encode_reserved => 0 });
    my $link_url_path;

    if (defined($self->{option_results}->{legacy})) {
        # Legacy: redirect to deprecated Centreon monitoring pages
        $link_url_path = '/main.php?p=2020';
        if ($resource_type eq 'service') {
            $link_url_path .= '1&o=svc&host_search=' . $self->{option_results}->{host_name}
                           .  '&search='             . $self->{option_results}->{service_description};
        } else {
            $link_url_path .= '2&o=svc&host_search=' . $self->{option_results}->{host_name};
        }
    } else {
        # Default: redirect to the new Resources Status page
        $link_url_path = $self->build_resource_status_filters();
    }

    my $link_uri_encoded = $uri->encode($self->{option_results}->{centreon_url}) . $link_url_path;
    $self->{action_link_url} = $link_uri_encoded;

    # Graph link (service only) : always points to the performance graph page
    if ($resource_type eq 'service') {
        my $graph_url_path   = '/main.php?p=204&mode=0&svc_id='
                             . $self->{option_results}->{host_name} . ';'
                             . $self->{option_results}->{service_description};
        $self->{action_graph_url} = $uri->encode($self->{option_results}->{centreon_url} . $graph_url_path);
    }
}

sub host_message {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{host_state}) && $self->{option_results}->{host_state} ne '') {
        if (defined($telegram_icon_host{lc($self->{option_results}->{host_state})})) {
            $self->{message} = $telegram_icon_host{lc($self->{option_results}->{host_state})};
        }
    }

    $self->{message} .= " Host <i>" . $self->{option_results}->{host_name} . "</i>";

    if (defined($self->{option_results}->{host_state}) && $self->{option_results}->{host_state} ne '') {
        $self->{message} .= ' is <b>' . $self->{option_results}->{host_state} . '</b>';
    } else {
        $self->{message} .= ' alert';
    }
    if (defined($self->{option_results}->{host_output}) && $self->{option_results}->{host_output} ne '') {
        $self->{message} .= "\n " . $self->{option_results}->{host_output};
    }

    # --action-links takes priority over the manual --link-url
    if (defined($self->{action_link_url}) && $self->{action_link_url} ne '') {
        $self->{message} .= "\n <a href=\"" . $self->{action_link_url} . "\">Link</a>";
    } elsif (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $self->{message} .= "\n <a href=\"" . $self->{option_results}->{link_url} . "\">Link</a>";
    }
}

sub service_message {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{service_state}) && $self->{option_results}->{service_state} ne '') {
        if (defined($telegram_icon_service{lc($self->{option_results}->{service_state})})) {
            $self->{message} = $telegram_icon_service{lc($self->{option_results}->{service_state})};
        }
    }

    $self->{message} .= " Host <i>" . $self->{option_results}->{host_name} . " | Service " . $self->{option_results}->{service_description} . "</i>";

    if (defined($self->{option_results}->{service_state}) && $self->{option_results}->{service_state} ne '') {
        $self->{message} .= ' is <b>' . $self->{option_results}->{service_state} . '</b>';
    } else {
        $self->{message} .= ' alert';
    }
    if (defined($self->{option_results}->{service_output}) && $self->{option_results}->{service_output} ne '') {
        $self->{message} .= "\n " . $self->{option_results}->{service_output};
    }

    # --action-links takes priority over the manual --link-url / --graph-url
    if (defined($self->{action_link_url}) && $self->{action_link_url} ne '') {
        $self->{message} .= "\n <a href=\"" . $self->{action_link_url} . "\">Link</a>";
    } elsif (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $self->{message} .= "\n <a href=\"" . $self->{option_results}->{link_url} . "\">Link</a>";
    }

    if (defined($self->{action_graph_url}) && $self->{action_graph_url} ne '') {
        $self->{message} .= "\n <a href=\"" . $self->{action_graph_url} . "\">Graph</a>";
    } elsif (defined($self->{option_results}->{graph_url}) && $self->{option_results}->{graph_url} ne '') {
        $self->{message} .= "\n <a href=\"" . $self->{option_results}->{graph_url} . "\">Graph</a>";
    }
}

sub set_payload {
    my ($self, %options) = @_;

    # Build action links (Resources Status or legacy pages) before composing the message
    $self->build_action_links();

    if (defined($self->{option_results}->{service_description}) && $self->{option_results}->{service_description} ne '') {
        $self->service_message();
    } else {
        $self->host_message();
    }
}

sub format_payload {
    my ($self, %options) = @_;

    my $json = JSON::XS->new->utf8;

    my $payload = {
        chat_id    => $self->{option_results}->{chat_id},
        parse_mode => 'HTML',
        text       => $self->{message}
    };
    eval {
        $self->{payload_str} = $json->encode($payload);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept',       value => 'application/json');

    $self->set_payload();
    $self->format_payload();

    my $url_path = '/bot' . $self->{option_results}->{bot_token} . $self->{option_results}->{url_path};
    my $response = $self->{http}->request(
        url_path        => $url_path,
        method          => 'POST',
        query_form_post => $self->{payload_str}
    );

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded->{result}->{message_id})) {
        $self->{output}->output_add(long_msg => $decoded, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Error sending message");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(short_msg => 'Message ID : ' . $decoded->{result}->{message_id});
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send message with Telegram API.

=over 6

=item B<--chat-id>

Telegram Chat ID (Negative Integer for Group)
Use Telegram CLI for getting Chat ID

=item B<--bot-token>

Telegram Bot Token (Check Telegram Doc for Creating Bot)
https://core.telegram.org/bots#3-how-do-i-create-a-bot

=item B<--host-name>

Specify host server name for the alert (required).

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

=item B<--action-links>

Only to be used with Centreon.

Automatically generate and add links to the notification message pointing to the
Centreon Resources Status page (C</monitoring/resources>) with a pre-filled filter
for the notified host/service.

Requires C<--centreon-url> to be set.

When combined with C<--legacy>, links will point to the deprecated monitoring pages
(C</main.php?p=2020x>) instead.

=item B<--centreon-url>

Specify the Centreon interface URL (to be used with C<--action-links>).

Syntax: C<--centreon-url='https://mycentreon.mydomain.local/centreon'>

=item B<--legacy>

Only to be used with Centreon together with C<--action-links>.

Redirect to the deprecated Centreon resource status pages (C</main.php?p=20201> /
C</main.php?p=20202>) instead of the new Resources Status page.

=item B<--centreon-token>

Specify the centreon token for autologin macro (could be used in link-url and graph-url option).

=item B<--graph-url>

Specify a custom graph url.

Example: C<%{centreon_url}/include/views/graphs/generateGraphs/generateImage.php?username=myuser&token=%{centreon_token}&hostname=%{host_name}&service=%{service_description}>

Ignored when C<--action-links> is set (the graph link is then built automatically).

=item B<--link-url>

Specify a custom link url.

Example: C<%{centreon_url}/monitoring/resources>

Ignored when C<--action-links> is set (the link is then built automatically).

=item B<--timeout>

Threshold for HTTP timeout.

=back

=cut