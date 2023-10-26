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

my %color_host = (
    up => { 
        background => '#88B922',
        text => '#FFFFFF' 
    },
    down => { 
        background => '#FF4A4A', 
        text => '#FFFFFF' 
    },
    unreachable => { 
        background => '#E0E0E0', 
        text => '#666666' 
    },
    acknowledgement => { 
        background => '#F5F1E9', 
        text => '#666666'
    },
    downtimestart => { 
        background => '#F0E9F8', 
        text => '#666666' 
    },
    downtimeend => { 
        background => '#F0E9F8', 
        text => '#666666'
    },
    downtimecancelled => { 
        background => '#F0E9F8', 
        text => '#666666'
    }
);

my %color_service = (
    ok => {
        background => '#88B922',
        text => '#FFFFFF'
    },
    warning => {
        background => '#FD9B27',
        text => '#FFFFFF'
    },
    critical => {
        background => '#FF4A4A',
        text => '#FFFFFF'
    },
    unknown => {
        background => '#E0E0E0',
        text => '#FFFFFF'
    },
    acknowledgement => {
        background => '#F5F1E9',
        text => '#666666'
    },
    downtimestart => {
        background => '#F0E9F8',
        text => '#666666'
    },
    downtimeend => {
        background => '#F0E9F8',
        text => '#666666'
    },
    downtimecancelled => {
        background => '#F0E9F8',
        text => '#666666'
    }
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'notification-type:s'    => { name => 'type'},
        'host-id:s'              => { name => 'host_id' },
        'host-address:s'         => { name => 'host_address'},
        'host-name:s'            => { name => 'host_name' },
        'host-alias:s'           => { name => 'host_alias'},
        'host-state:s'           => { name => 'host_state' },
        'host-output:s'          => { name => 'host_output' },
        'host-attempts:s'        => { name => 'host_attempts'},
        'max-host-attempts:s'    => { name => 'max_host_attempts'},
        'host-duration:s'        => { name => 'host_duration' },
        'service-id:s'           => { name => 'service_id' },
        'service-description:s'  => { name => 'service_description' },
        'service-displayname:s'  => { name => 'service_displayname' },
        'service-state:s'        => { name => 'service_state' },
        'service-output:s'       => { name => 'service_output' },
        'service-longoutput:s'   => { name => 'service_longoutput' },
        'service-attempts:s'     => { name => 'service_attempts'},
        'max-service-attempts:s' => { name => 'max_service_attempts'},
        'service-duration:s'     => { name => 'service_duration' },
        'date:s'                 => { name => 'date' },
        'notif-author:s'         => { name => 'notif_author' },
        'notif-comment:s'        => { name => 'notif_comment' },
        'add-link'               => { name => 'add_link' },
        'centreon-url:s'         => { name => 'centreon_url' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{type}) || $self->{option_results}->{type} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --notification-type option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{host_id}) || $self->{option_results}->{host_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --host-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{host_name}) || $self->{option_results}->{host_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --host-name option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{host_alias}) || $self->{option_results}->{host_alias} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --host-alias option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{host_state}) || $self->{option_results}->{host_state} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --host-state option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{service_id}) || $self->{option_results}->{service_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --service-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{service_description}) || $self->{option_results}->{service_description} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --service-description option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{service_state}) || $self->{option_results}->{service_state} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --service-state option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{service_output}) || $self->{option_results}->{service_output} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --service-output option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{date}) || $self->{option_results}->{date} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify the --date option.");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{add_link})) {
        if (!defined($self->{option_results}->{centreon_url}) || $self->{option_results}->{centreon_url} eq ''){
            $self->{output}->add_option_msg(short_msg => 'Please set --centreon-url option');
            $self->{output}->option_exit();
        }
    }
}

sub build_payload {
    my ($self, %options) = @_;

    my $message = $self->build_message();
    $self->{json_payload} = {
        '@type'         => 'MessageCard',
        '@context'      => 'https://schema.org/extensions',
        potentialAction => $message->{potentialAction},
        sections        => $message->{sections},
        summary         => $message->{summary},
        themecolor      => $message->{themecolor}
    };

    return $self;
}

sub host_message {
    my ($self, %options) = @_;

    my $message;
    $message->{sections} = [];
    $message->{themecolor} = ($self->{option_results}->{type} =~ /^problem|recovery$/i) ? $color_host{lc($self->{option_results}->{host_state})}->{background} : $color_host{lc($self->{option_results}->{type})}->{background};
    
    my @facts = [];
    if ($self->{option_results}->{type} =~ /^acknowledgement$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Host has been acknowledged';
        $message->{title} = 'Host <b>' . $self->{option_results}->{host_name} . '</b> has been acknowledged';
        @facts = (
            { name => 'Author', value => $self->{option_results}->{notif_author} },
            { name => 'Comment', value => $self->{option_results}->{notif_comment} }
        );
    } elsif ($self->{option_results}->{type} =~ /^downtimestart$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Host has entered a downtime period';
        $message->{title} = 'Host <b>' . $self->{option_results}->{host_name} . '</b> has entered a downtime period';
        @facts = (
            { name => 'Author', value => $self->{option_results}->{notif_author} },
            { name => 'Comment', value => $self->{option_results}->{notif_comment} }
        );
    } elsif ($self->{option_results}->{type} =~ /^downtimeend|downtimecancelled$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Host has exited a downtime period';
        $message->{title} = 'Host <b>' . $self->{option_results}->{host_name} . '</b> has exited a downtime period';
    } else {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Host is ' . $self->{option_results}->{host_state};
        my $formatted_status = ucfirst(lc($self->{option_results}->{host_state}));
        my $chip = '<span style="color:' . $color_host{lc($self->{option_results}->{host_state})}->{text} . ';background-color:' . $color_host{lc($self->{option_results}->{host_state})}->{background} . ';border-radius:10px;justify-content:center;padding-left:1em;padding-right:1em;margin-right:1em;letter-spacing:0.01071em">' . $formatted_status . '</span>';
        $message->{title} = $chip . ' Host <b>' . $self->{option_results}->{host_name} . '</b>';
        $message->{text} = $self->{option_results}->{host_output};
        @facts = (
            { name => 'Host', value => $self->{option_results}->{host_name} },
            { name => 'Host alias', value => $self->{option_results}->{host_alias} }
        );
        push @facts, { name => 'Host address', value => $self->{option_results}->{host_address} } if (defined($self->{option_results}->{host_address}) && $self->{option_results}->{host_address} ne '');
    }

    push @{$message->{sections}}, {
        activityTitle => $message->{title},
        activitySubtitle => $self->{option_results}->{date}
    };
    $message->{sections}[0]->{text} = $message->{text} if (defined($message->{text}) && $message->{text} ne '');
    push @{$message->{sections}[0]->{facts}}, @facts if (scalar(@facts) > 1);

    if (defined($self->{option_results}->{add_link})) {        
        my $search = {
            criterias => [
                {
                    name => 'search',
                    type => 'text',
                    value => 'h.name:' . $self->{option_results}->{host_name}
                },
                {
                    name => 'sort',
                    type => 'array',
                    value => [
                        'name',
                        'asc'
                    ]
                }
            ]
        };
        my $details = {
            id => $self->{option_results}->{host_id},
            resourcesDetailsEndpoint => '/centreon/api/latest/monitoring/resources/hosts/' . $self->{option_results}->{host_id},
            tab => 'details'
        };

        my $uri = URI::Encode->new({encode_reserved => 1});
        my $search_encoded = $uri->encode(encode_json($search));
        my $details_encoded = $uri->encode(encode_json($details));

        push @{$message->{potentialAction}}, {
            '@type' => 'OpenUri',
            name    => 'View in Centreon',
            targets => [{
                'os'  => 'default',
                'uri' => $self->{option_results}->{centreon_url} .'/monitoring/resources?filter=' . $search_encoded . '&details=' . $details_encoded
            }]
        };     
    }

    return $message;
}

sub service_message {
    my ($self, %options) = @_;

    my $message;
    $message->{sections} = [];
    $message->{themecolor} = ($self->{option_results}->{type} =~ /^problem|recovery$/i) ? $color_service{lc($self->{option_results}->{service_state})}->{background} : $color_service{lc($self->{option_results}->{type})}->{background};
    
    my @facts = [];
    if ($self->{option_results}->{type} =~ /^acknowledgement$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Service has been acknowledged';
        $message->{title} = 'Service <b>' . $self->{option_results}->{service_description} . '</b> on host <b>' . $self->{option_results}->{host_name} . '</b> has been acknowledged';
        @facts = (
            { name => 'Author', value => $self->{option_results}->{notif_author} },
            { name => 'Comment', value => $self->{option_results}->{notif_comment} }
        );
    } elsif ($self->{option_results}->{type} =~ /^downtimestart$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Service has entered a downtime period';
        $message->{title} = 'Service <b>' . $self->{option_results}->{service_description} . '</b> on host <b>' . $self->{option_results}->{host_name} . '</b> has entered a downtime period';
        @facts = (
            { name => 'Author', value => $self->{option_results}->{notif_author} },
            { name => 'Comment', value => $self->{option_results}->{notif_comment} }
        );
    } elsif ($self->{option_results}->{type} =~ /^downtimeend|downtimecancelled$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Service has exited a downtime period';
        $message->{title} = 'Service <b>' . $self->{option_results}->{service_description} . '</b> on host <b>' . $self->{option_results}->{host_name} . '</b> has exited a downtime period';
    } else {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Service is ' . $self->{option_results}->{service_state};
        my $formatted_status = ucfirst(lc($self->{option_results}->{service_state}));
        my $chip = '<span style="color:' . $color_service{lc($self->{option_results}->{service_state})}->{text} . ';background-color:' . $color_service{lc($self->{option_results}->{service_state})}->{background} . ';border-radius:10px;justify-content:center;padding-left:1em;padding-right:1em;margin-right:1em;letter-spacing:0.01071em">' . $formatted_status . '</span>';
        $message->{title} = $chip . ' Service <b>' . $self->{option_results}->{service_description} . '</b> on host <b>' . $self->{option_results}->{host_name} . '</b>';
        $message->{text} = $self->{option_results}->{service_output};
        @facts = (
            { name => 'Service', value => $self->{option_results}->{service_description} },
            { name => 'Host', value => $self->{option_results}->{host_name} },
            { name => 'Host alias', value => $self->{option_results}->{host_alias} }
        );
        push @facts, { name => 'Host address', value => $self->{option_results}->{host_address} } if (defined($self->{option_results}->{host_address}) && $self->{option_results}->{host_address} ne '');
        push @facts, { name => 'Additionnal information', value => $self->{option_results}->{service_longoutput} } if (defined($self->{option_results}->{service_longoutput}) && $self->{option_results}->{service_longoutput} ne '');
    }

    push @{$message->{sections}}, {
        activityTitle => $message->{title},
        activitySubtitle => $self->{option_results}->{date}
    };
    $message->{sections}[0]->{text} = $message->{text} if (defined($message->{text}) && $message->{text} ne '');
    push @{$message->{sections}[0]->{facts}}, @facts if (scalar(@facts) > 1);

    if (defined($self->{option_results}->{add_link})) {        
        my $search = {
            criterias => [
                {
                    name => 'search',
                    type => 'text',
                    value => 'h.name:' . $self->{option_results}->{host_name} . ' s.description:'. $self->{option_results}->{service_description}
                }
            ]
        };
        my $details = {
            id => $self->{option_results}->{service_id},
            resourcesDetailsEndpoint => '/centreon/api/latest/monitoring/resources/hosts/' . $self->{option_results}->{host_id} . '/services/' . $self->{option_results}->{service_id},
            tab => 'details'
        };

        my $uri = URI::Encode->new({encode_reserved => 1});
        my $search_encoded = $uri->encode(encode_json($search));
        my $details_encoded = $uri->encode(encode_json($details));

        push @{$message->{potentialAction}}, {
            '@type' => 'OpenUri',
            name    => 'View in Centreon',
            targets => [{
                'os'  => 'default',
                'uri' => $self->{option_results}->{centreon_url} .'/monitoring/resources?filter=' . $search_encoded . '&details=' . $details_encoded
            }]
        };     
    }

    return $message;
}

sub bam_message {
    my ($self, %options) = @_;

    my $message;
    $message->{sections} = [];
    $message->{themecolor} = ($self->{option_results}->{type} =~ /^problem|recovery$/i) ? $color_service{lc($self->{option_results}->{service_state})}->{background} : $color_service{lc($self->{option_results}->{type})}->{background};
    
    my @facts = [];
    if ($self->{option_results}->{type} =~ /^acknowledgement$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Business Activity has been acknowledged';
        $message->{title} = 'Business Activity <b>' . $self->{option_results}->{service_displayname} . '</b> has been acknowledged';
        @facts = (
            { name => 'Author', value => $self->{option_results}->{notif_author} },
            { name => 'Comment', value => $self->{option_results}->{notif_comment} }
        );
    } elsif ($self->{option_results}->{type} =~ /^downtimestart$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Business Activity has entered a downtime period';
        $message->{title} = 'Business Activity <b>' . $self->{option_results}->{service_displayname} . '</b> has entered a downtime period';
        @facts = (
            { name => 'Author', value => $self->{option_results}->{notif_author} },
            { name => 'Comment', value => $self->{option_results}->{notif_comment} }
        );
    } elsif ($self->{option_results}->{type} =~ /^downtimeend|downtimecancelled$/i) {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Business Activity has exited a downtime period';
        $message->{title} = 'Business Activity <b>' . $self->{option_results}->{service_displayname} . '</b> has exited a downtime period';
    } else {
        $message->{summary} = ucfirst(lc($self->{option_results}->{type})) . ' Notification : Business Activity is ' . $self->{option_results}->{service_state};
        my $formatted_status = ucfirst(lc($self->{option_results}->{service_state}));
        my $chip = '<span style="color:' . $color_service{lc($self->{option_results}->{service_state})}->{text} . ';background-color:' . $color_service{lc($self->{option_results}->{service_state})}->{background} . ';border-radius:10px;justify-content:center;padding-left:1em;padding-right:1em;margin-right:1em;letter-spacing:0.01071em">' . $formatted_status . '</span>';
        $message->{title} = $chip . ' Business Activity <b>' . $self->{option_results}->{service_displayname} . '</b>';
        push @facts, { name => 'Additionnal information', value => $self->{option_results}->{service_longoutput} } if (defined($self->{option_results}->{service_longoutput}) && $self->{option_results}->{service_longoutput} ne '');
    }

    push @{$message->{sections}}, {
        activityTitle => $message->{title},
        activitySubtitle => $self->{option_results}->{date}
    };
    $message->{sections}[0]->{text} = $message->{text} if (defined($message->{text}) && $message->{text} ne '');
    push @{$message->{sections}[0]->{facts}}, @facts if (scalar(@facts) > 1);

    return $message;
}

sub build_message {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{service_description}) && $self->{option_results}->{service_description} ne '') {
        if (defined($self->{option_results}->{host_name}) && $self->{option_results}->{host_name} =~ /Module_BAM/i) {
            $self->bam_message();
        } else {
            $self->service_message();
        }
    } else {
        $self->host_message();
    }
}

sub run {
    my ($self, %options) = @_;

    my $json_request = $self->build_payload();
    my $response = $options{custom}->teams_post_notification(
        json_request => $self->{json_payload}
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send notifications to a Microsoft Teams team's channel.

Example for a host:

centreon_plugins.pl --plugin=notification::microsoft::office365::teams::plugin --mode=alert --custommode=webhookapi
-teams-webhook='https://toto.webhook.office.com/webhookb2/...' --notification-type='PROBLEM' ---host-name='my_host_1'
--host-alias='tha_host' --host-state='DOWN' --host-output='CRITICAL - my_host_1: rta nan, lost 100%' --host-id='342'
--add-link --centreon-url='https://127.0.0.1/centreon'

Example of configuration:

centreon_plugins.pl --plugin=notification::microsoft::office365::teams::plugin --mode=alert --custommode=webhookapi
--notification-type='$NOTIFICATIONTYPE$' --host-name='$HOSTNAME$' --host-address='$HOSTADDRESS$' --host-alias='$HOSTALIAS$'
--host-state='$HOSTSTATE$' --host-output='$HOSTOUTPUT$' --host-id='$HOSTID$' --service-description='$SERVICEDESC$'
--service-state='$SERVICESTATE$' --service-output='$SERVICEOUTPUT$' --service-id='$SERVICEID$' --date='$SHORTDATETIME$'
--notif-author='$NOTIFICATIONAUTHOR$' --notif-comment='$NOTIFICATIONCOMMENT$' --add-link --centreon-url='$CENTREONURL$'
--teams-webhook='$CONTACTPAGER$' --timeout=10

=over 8

=item B<--notification-type>

Specify the notification type.

=item B<--host-id>

ID of the host.

=item B<--host-address>

IP Address of the host (not mandatory).

=item B<--host-name>

Specify Host server name for the alert.

=item B<--host-alias>

Alias of the host.

=item B<--host-state>

Specify Host server state for the alert.

=item B<--host-output>

Specify Host server output message for the alert.

=item B<--service-id>

ID of the service.

=item B<--service-description>

Specify Service description name for the alert.

=item B<--service-displayname>

Specify Service displayname name for the alert (used by BAM alerts).

=item B<--service-state>

Specify Service state for the alert.

=item B<--service-output>

Specify Service output message for the alert.

=item B<--service-longoutput>

Long output of the service (not mandatory).

=item B<--date>

Specify the date & time of the event.

=item B<--notif-author>

Author of the notification.

=item B<--notif-comment>

Comment for the notification.

=item B<--add-link>

Add a link to Centreon resource into Teams card.

=item B<--centreon-url>

Specify the Centreon interface URL (to be used with the action links).
Syntax: --centreon-url='https://mycentreon.mydomain.local/centreon'

=back

=cut
