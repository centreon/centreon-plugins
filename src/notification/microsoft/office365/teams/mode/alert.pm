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

package notification::microsoft::office365::teams::mode::alert;

use strict;
use warnings;
use base qw(centreon::plugins::mode);
use URI::Encode;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'action-links'          => { name => 'action_links' },
        'bam'                   => { name => 'bam' },
        'centreon-url:s'        => { name => 'centreon_url' },
        'channel-id:s'          => { name => 'channel_id' },
        'date:s'                => { name => 'date' },
        'extra-info-format:s'   => { name => 'extra_info_format', default => 'Author: %s, Comment: %s' },
        'extra-info:s'          => { name => 'extra_info' },
        'host-name:s'           => { name => 'host_name' },
        'host-output:s'         => { name => 'host_output', default => '' },
        'host-state:s'          => { name => 'host_state' },
        'legacy:s'              => { name => 'legacy' },
        'notification-type:s'   => { name => 'notif_type' },
        'service-description:s' => { name => 'service_name' },
        'service-output:s'      => { name => 'service_output', default => '' },
        'service-state:s'       => { name => 'service_state' },
        'team-id:s'             => { name => 'team_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{teams}->{channel_id} = defined($self->{option_results}->{channel_id}) && $self->{option_results}->{channel_id} ne '' ?
                                   $self->{option_results}->{channel_id} : undef;
    $self->{teams}->{team_id} = defined($self->{option_results}->{team_id}) && $self->{option_results}->{channel_id} ne ''
                                ? $self->{option_results}->{team_id} : undef;

    if (!defined($self->{option_results}->{notif_type}) || $self->{option_results}->{notif_type} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --notification-type option.");
        $self->{output}->option_exit();
    }
}

sub build_resource_status_filters {
    my ($self, %options) = @_;

    my $data_format                 = URI::Encode->new({ encode_reserved => 1 });
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
                "value"       => [

                ]
            },
            {
                "name"        => "statuses",
                "object_type" => undef,
                "type"        => "multi_select",
                "value"       => [

                ]
            },
            {
                "name"        => "status_types",
                "object_type" => undef,
                "type"        => "multi_select",
                "value"       => [

                ]
            },
            {
                "name"        => "host_groups",
                "object_type" => "host_groups",
                "type"        => "multi_select",
                "value"       => [

                ]
            },
            {
                "name"        => "service_groups",
                "object_type" => "service_groups",
                "type"        => "multi_select",
                "value"       => [

                ]
            },
            {
                "name"        => "monitoring_servers",
                "object_type" => "monitoring_servers",
                "type"        => "multi_select",
                "value"       => [

                ]
            },
            {
                "name"        => "search",
                "object_type" => undef,
                "type"        => "text",
                "value"       => sprintf(
                    's.description:%s h.name:%s',
                    defined($self->{option_results}->{service_name}) ? $self->{option_results}->{service_name} : '',
                    defined($self->{option_results}->{host_name}) ? $self->{option_results}->{host_name} : ''
                )
            },
            {
                "name"        => "sort",
                "object_type" => undef,
                "type"        => "array",
                "value"       => [
                    "status_severity_code",
                    "asc"
                ]
            }
        ]
    };

    my $link_url_path                   = '/monitoring/resources?filter=';
    my $encoded_resource_status_filters = JSON::XS->new->utf8->encode($raw_resource_status_filters);
    my $encoded_data_for_uri            = $data_format->encode($encoded_resource_status_filters);
    $link_url_path                      .= $encoded_data_for_uri;

    return $link_url_path;
}

sub build_webhook_payload {
    my ($self, %options) = @_;

    my $message           = $self->build_webhook_message();
    $self->{json_payload} = {
        '@type'         => 'MessageCard',
        '@context'      => 'https://schema.org/extensions',
        potentialAction => $message->{potentialAction},
        sections        => $message->{sections},
        summary         => 'Centreon ' . $message->{notif_type},
        themeColor      => $message->{themecolor}
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json response');
        $self->{output}->option_exit();
    }

    return $self;
}

sub build_webhook_message {
    my ($self, %options) = @_;

    my $teams_colors = {
        ACKNOWLEDGEMENT => 'fefc8e',
        DOWNTIMEEND     => 'f1dfff',
        DOWNTIMESTART   => 'f1dfff',
        RECOVERY        => '42f56f',
        PROBLEM         => {
            host    => {
                up          => '42f56f',
                down        => 'f21616',
                unreachable => 'f21616'
            },
            service => {
                ok       => '42f56f',
                warning  => 'f59042',
                critical => 'f21616',
                unknown  => '757575'
            }
        }
    };

    $self->{sections}      = [];
    $self->{notif_type}    = $self->{option_results}->{notif_type};
    my $resource_type      = defined($self->{option_results}->{host_state}) ? 'host' : 'service';
    my $formatted_resource = ucfirst($resource_type);
    $formatted_resource    = 'BAM' if defined($self->{option_results}->{bam});

    push @{$self->{sections}}, {
        activityTitle    =>
        $self->{notif_type} . ': ' . $formatted_resource . ' "' . $self->{option_results}->{$resource_type . '_name'} . '" is ' . $self->{option_results}->{$resource_type . '_state'},
        activitySubtitle =>
        $resource_type eq 'service' ? 'Host ' . $self->{option_results}->{host_name} : ''
    };
    $self->{themecolor} = $teams_colors->{$self->{notif_type}};
    if ($self->{notif_type} eq 'PROBLEM') {
        $self->{themecolor} = $teams_colors->{PROBLEM}->{$resource_type}->{lc($self->{option_results}->{$resource_type . '_state'})};
    }

    if (defined($self->{option_results}->{$resource_type . '_output'}) && $self->{option_results}->{$resource_type . '_output'} ne '') {
        push @{$self->{sections}[0]->{facts}}, { name => 'Status', 'value' => $self->{option_results}->{$resource_type . '_output'} };
    }

    if (defined($self->{option_results}->{date}) && $self->{option_results}->{date} ne '') {
        push @{$self->{sections}[0]->{facts}}, { name => 'Event date', 'value' => $self->{option_results}->{date} };
    }

    if (defined($self->{option_results}->{extra_info}) && $self->{option_results}->{extra_info} !~ m/^\/\/$/) {
        if ($self->{option_results}->{extra_info} =~ m/^(.*)\/\/(.*)$/) {
            push @{$self->{sections}[0]->{facts}}, {
                name  => 'Additional Information',
                value => sprintf($self->{option_results}->{extra_info_format}, $1, $2)
            };
        }
    }

    if (defined($self->{option_results}->{action_links})) {
        if (!defined($self->{option_results}->{centreon_url}) || $self->{option_results}->{centreon_url} eq '') {
            $self->{output}->add_option_msg(short_msg => 'Please set --centreon-url option');
            $self->{output}->option_exit();
        }
        my $uri = URI::Encode->new({ encode_reserved => 0 });
        my $link_url_path;

        if (defined($self->{option_results}->{legacy})) {
            $link_url_path = '/main.php?p=2020'; # deprecated pages
            $link_url_path .= ($resource_type eq 'service') ?
                              '1&o=svc&host_search=' . $self->{option_results}->{host_name} . '&search=' . $self->{option_results}->{service_name} :
                              '2&o=svc&host_search=' . $self->{option_results}->{host_name};

            my $link_uri_encoded = $uri->encode($self->{option_results}->{centreon_url} . $link_url_path);
        } else {
            $link_url_path = $self->build_resource_status_filters();
        }

        my $link_uri_encoded = $uri->encode($self->{option_results}->{centreon_url}) . $link_url_path;

        push @{$self->{potentialAction}}, {
            '@type' => 'OpenUri',
            name    => 'Details',
            targets => [{
                'os'  => 'default',
                'uri' => $link_uri_encoded
            }]
        };

        if ($resource_type eq 'service') {
            my $graph_url_path = '/main.php?p=204&mode=0&svc_id=';

            $graph_url_path       .= $self->{option_results}->{host_name} . ';' . $self->{option_results}->{service_name};
            my $graph_uri_encoded = $uri->encode($self->{option_results}->{centreon_url} . $graph_url_path);
            push @{$self->{potentialAction}}, {
                '@type' => 'OpenUri',
                name    => 'Graph',
                targets => [{
                    'os'  => 'default',
                    'uri' => $graph_uri_encoded
                }]
            };
        }

    }
    return $self;
}

sub build_workflow_payload {
    my ($self, %options) = @_;

    my $message           = $self->build_workflow_message();
    $self->{json_payload} = {
        type        => "message",
        attachments => [
            {
                contentType => "application/vnd.microsoft.card.adaptive",
                content     => {
                    '$schema' => "http://adaptivecards.io/schemas/adaptive-card.json",
                    type      => "AdaptiveCard",
                    version   => "1.0",
                    body      => $message->{body},
                    actions   => $message->{actions}
                }
            }
        ]
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json response');
        $self->{output}->option_exit();
    }

    return $self;
}

sub build_workflow_message {
    my ($self, %options) = @_;

    my $teams_colors = {
        ACKNOWLEDGEMENT => 'accent',
        DOWNTIMEEND     => 'accent',
        DOWNTIMESTART   => 'accent',
        RECOVERY        => 'good',
        PROBLEM         => {
            host    => {
                up          => 'good',
                down        => 'attention',
                unreachable => 'attention'
            },
            service => {
                ok       => 'good',
                warning  => 'warning',
                critical => 'attention',
                unknown  => 'light'
            }
        }
    };

    $self->{body}          = [];
    $self->{notif_type}    = $self->{option_results}->{notif_type};
    my $resource_type      = defined($self->{option_results}->{host_state}) ? 'host' : 'service';
    my $formatted_resource = ucfirst($resource_type);
    $formatted_resource    = 'BAM' if defined($self->{option_results}->{bam});
    my $themecolor         = $teams_colors->{$self->{notif_type}};
    if ($self->{notif_type} eq 'PROBLEM') {
        $themecolor = $teams_colors->{PROBLEM}->{$resource_type}->{lc($self->{option_results}->{$resource_type . '_state'})};
    }
    if (!defined($themecolor)) {
        $themecolor = 'default';
    }

    push @{$self->{body}}, {
        type     => "TextBlock",
        text     => $self->{notif_type} . ': ' . $formatted_resource . ' "' . $self->{option_results}->{$resource_type . '_name'} . '" is ' . $self->{option_results}->{$resource_type . '_state'},
        "size"   => "Large",
        "weight" => "Bolder",
        "style"  => "heading",
        "color"  => $themecolor
    };
    push @{$self->{body}}, {
        type     => "TextBlock",
        text     => $resource_type eq 'service' ? 'Host ' . $self->{option_results}->{host_name} : '',
        "size"   => "Medium",
        "weight" => "Bolder",
        "style"  => "heading",
        "color"  => $themecolor
    };

    if (defined($self->{option_results}->{$resource_type . '_output'}) && $self->{option_results}->{$resource_type . '_output'} ne '') {
        push @{$self->{body}}, {
            type => "TextBlock",
            text => "Status: " . $self->{option_results}->{$resource_type . '_output'}
        };
    }

    if (defined($self->{option_results}->{date}) && $self->{option_results}->{date} ne '') {
        push @{$self->{body}}, {
            type => "TextBlock",
            text => "Event date: " . $self->{option_results}->{date}
        };
    }

    if (defined($self->{option_results}->{extra_info}) && $self->{option_results}->{extra_info} !~ m/^\/\/$/) {
        if ($self->{option_results}->{extra_info} =~ m/^(.*)\/\/(.*)$/) {
            push @{$self->{body}}, {
                type   => "TextBlock",
                text   => "Additional Information:  \n" . sprintf($self->{option_results}->{extra_info_format}, $1, $2),
                "wrap" => "true"
            };
        }
    }

    if (defined($self->{option_results}->{action_links})) {
        if (!defined($self->{option_results}->{centreon_url}) || $self->{option_results}->{centreon_url} eq '') {
            $self->{output}->add_option_msg(short_msg => 'Please set --centreon-url option');
            $self->{output}->option_exit();
        }
        my $uri = URI::Encode->new({ encode_reserved => 0 });
        my $link_url_path;

        if (defined($self->{option_results}->{legacy})) {
            $link_url_path = '/main.php?p=2020'; # deprecated pages
            $link_url_path .= ($resource_type eq 'service') ?
                              '1&o=svc&host_search=' . $self->{option_results}->{host_name} . '&search=' . $self->{option_results}->{service_name} :
                              '2&o=svc&host_search=' . $self->{option_results}->{host_name};

            my $link_uri_encoded = $uri->encode($self->{option_results}->{centreon_url} . $link_url_path);
        } else {
            $link_url_path = $self->build_resource_status_filters();
        }

        my $link_uri_encoded = $uri->encode($self->{option_results}->{centreon_url}) . $link_url_path;

        push @{$self->{actions}}, {
            "type"  => "Action.OpenUrl",
            "title" => "Details",
            "url"   => "$link_uri_encoded",
            "role"  => "button"
        };

        if ($resource_type eq 'service') {
            my $graph_url_path = '/main.php?p=204&mode=0&svc_id=';

            $graph_url_path       .= $self->{option_results}->{host_name} . ';' . $self->{option_results}->{service_name};
            my $graph_uri_encoded = $uri->encode($self->{option_results}->{centreon_url} . $graph_url_path);
            push @{$self->{actions}}, {
                "type"  => "Action.OpenUrl",
                "title" => "Graph",
                "url"   => $graph_uri_encoded,
                "role"  => "button"
            };
        }

    }
    return $self;
}

sub run {
    my ($self, %options) = @_;

    my $json_request;
    if (!centreon::plugins::misc::is_empty($options{custom}->{teams_webhook})) {
        $json_request = $self->build_webhook_payload();
    } else {
        $json_request = $self->build_workflow_payload();
    }
    $options{custom}->teams_post_notification(
        channel_id   => $self->{teams}->{channel_id},
        json_request => $self->{json_payload},
        team_id      => $self->{teams}->{team_id}
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send notifications to a Microsoft Teams Channel.

Example for a Host:
centreon_plugins.pl --plugin=notification::microsoft::office365::teams::plugin --mode=alert --teams-webhook='https:/teams.microsoft.com/1/channel/...'
--host-name='my_host_1' --host-state='DOWN' --host-output='CRITICAL - my_host_1: rta nan, lost 100%'
--centreon-url='https://127.0.0.1/centreon' --action-links'

=over 8

=item B<--notification-type>

Specify the notification type (required).

=item B<--host-name>

Specify Host server name for the alert (required).

=item B<--host-state>

Specify Host server state for the alert.

=item B<--host-output>

Specify Host server output message for the alert.

=item B<--service-desc>

Specify Service description name for the alert.

=item B<--service-state>

Specify Service state for the alert.

=item B<--service-output>

Specify Service output message for the alert.

=item B<--action-links>

Only to be used with Centreon.
Add actions links buttons to the notification card (resource status & graph page).

=item B<--centreon-url>

Specify the Centreon interface URL (to be used with the action links).
Syntax: --centreon-url='https://mycentreon.mydomain.local/centreon'

=item B<--bam>

Compatibility with Centreon BAM notifications.

=item B<--date>

Specify the date & time of the event.

=item B<--extra-info>

Specify extra information about author and comment (only for ACK and DOWNTIME types).

=item B<--extra-info-format>

Specify the extra info display format (default: 'Author: %s, Comment: %s').

=item B<--legacy>

Only to be used with Centreon.
Permit redirection to Centreon legacy resource status pages.
To be used with --action-links.

=back

=cut
