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

package notification::microsoft::office365::teams::mode::alert;

use strict;
use warnings;
use base qw(centreon::plugins::mode);
use Data::Dumper;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'action-links'                   => { name => 'action_links' },
        'bam'                            => { name => 'bam' },
        'centreon-host-name:s'           => { name => 'centreon_host_name' },
        'centreon-host-state:s'          => { name => 'centreon_host_state' },
        'centreon-host-output:s'         => { name => 'centreon_host_output', default => '' },
        'centreon-service-description:s' => { name => 'centreon_service_name' },
        'centreon-service-state:s'       => { name => 'centreon_service_state' },
        'centreon-service-output:s'      => { name => 'centreon_service_output', default => '' },
        'centreon-graph-url:s'           => { name => 'graph_url' },
        'centreon-link-url:s'            => { name => 'link_url' },
        'centreon-url:s'                 => { name => 'centreon_url' },
        'channel-id:s'                   => { name => 'channel_id' },
        'team-id:s'                      => { name => 'team_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{centreon_host_name}) || $self->{option_results}->{centreon_host_name} eq '') {
            $self->{output}->add_option_msg(short_msg => 'You need to specify --centreon-host-name option.');
            $self->{output}->option_exit();
        }
    if (!defined($self->{option_results}->{centreon_host_state}) || $self->{option_results}->{centreon_host_state} eq '') {
        $self->{output}->add_option_msg(short_msg => 'You need to specify --centreon-host-state option.');
        $self->{output}->option_exit();
    }
    $self->{teams}->{channel_id} = defined($self->{option_results}->{channel_id}) ? $self->{option_results}->{channel_id} : undef;
    $self->{teams}->{team_id} = defined($self->{option_results}->{team_id}) ? $self->{option_results}->{team_id} : undef;

}

sub build_payload {
    my ($self, %options) = @_;

    my $message = $self->build_message();
    $self->{json_payload} = {
        '@type'         => 'MessageCard',
	    '@context'      => 'https://schema.org/extensions',
        potentialAction => $message->{links},
        sections        => $message->{body_sections},
        summary         => 'Centreon Alert',
        themecolor      => $message->{color}
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json response');
        $self->{output}->option_exit();
    }

    return $self;
}

sub build_message {
    my ($self, %options) = @_;

    my %teams_colors = (
        centreon_host => {
            up => '42f56f',
            down => 'f21616',
            unreachable => 'f21616'
        },
        centreon_service => {
            ok => '42f56f',
            warning => 'f59042',
            critical => 'f21616',
            unknown => '757575'
        }
    );

    my $resource_type = defined($self->{option_results}->{centreon_host_state}) ? 'centreon_host' : 'centreon_service';
    my $formatted_resource = ucfirst($1) if ($resource_type =~ m/_(.*)/);
    $formatted_resource = 'BAM' if defined($self->{option_results}->{bam});

    $self->{body_sections}->{activityTitle} = $formatted_resource . ' "' . $self->{option_results}->{$resource_type . '_name'} . '" is ' . $self->{option_results}->{$resource_type . '_state'};
    $self->{body_sections}->{activitySubtitle} = 'Host ' . $self->{option_results}->{centreon_host_name} if ($resource_type eq 'centreon_service');
    $self->{color} = $teams_colors{$resource_type}->{lc($self->{option_results}->{$resource_type . '_state'})};

    if (defined($self->{option_results}->{$resource_type . '_output'}) && $self->{option_results}->{$resource_type . '_output'} ne '') {
        push @{$self->{body_sections}->{facts}}, { name => 'Status', 'value' => $self->{option_results}->{$resource_type . '_output'} };
    }

    if (defined($self->{option_results}->{action_links})) {
        if (!defined($self->{option_results}->{centreon_url}) || $self->{option_results}->{centreon_url} eq ''){
            $self->{output}->add_option_msg(short_msg => 'Please set --centreon-url option');
            $self->{output}->option_exit();
        }

        my $link_url_path = '/main.php?p=2020'; #only for the 'old' pages for now
        $link_url_path .= ($resource_type eq 'centreon_service') ?
                        '1&o=svc&host_search=' . $self->{option_results}->{centreon_host_name} . '&svc_search=' . $self->{option_results}->{centreon_service_name} :
                        '2&o=svc&host_search=' . $self->{option_results}->{centreon_host_name};

        my $link_uri = $self->{option_results}->{centreon_url} . $link_url_path;

        push @{$self->{links}}, {
            '@type' => 'OpenUri',
            name => 'Details',
            targets => [{
                'os' => 'default',
                'uri' => $link_uri
            }]
        };

        if ($resource_type eq 'centreon_service') {
            my $graph_url_path = '/main.php?p=204&mode=0&svc_id=';
            $graph_url_path .= $self->{option_results}->{centreon_host_name} . ';' . $self->{option_results}->{centreon_service_name};

            my $graph_uri = $self->{option_results}->{centreon_url} . $graph_url_path;
            push @{$self->{links}}, {
                '@type' => 'OpenUri',
                name => 'Graph',
                targets => [{
                    'os' => 'default',
                    'uri' => $graph_uri
                }]
            };
        }
    }
    return $self;
}

sub run {
    my ($self, %options) = @_;

    my $json_request = $self->build_payload();
    my $response = $options{custom}->teams_post_notification(
        json_request => $self->{json_payload},
        team_id => $self->{teams}->{team_id},
        channel_id => $self->{teams}->{channel_id}
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send notifications to a Microsoft Teams Channel.

Example for a Host:
centreon_plugins.pl --plugin=notification::microsoft::office365::teams::plugin --mode=alert --office365-webhook='https:/teams.microsoft.com/1/channel/...'
--centreon-host-name='my_host_1' --centreon-host-state='DOWN' --centreon-host-output='CRITICAL - my_host_1: rta nan, lost 100%'
--centreon-url='https://127.0.0.1/centreon/' --action-links'

=over 8

=item B<--action-links>

Add actions links buttons to the notification card (Resource status & graph page).

=item B<--centreon-host-name>

Specify Host server name for the alert (Required).

=item B<--centreon-host-state>

Specify Host server state for the alert.

=item B<--centreon-host-output>

Specify Host server output message for the alert.

=item B<--centreon-service-description>

Specify Service description name for the alert.

=item B<--centreon-service-state>

Specify Service state for the alert.

=item B<--centreon-service-output>

Specify Service output message for the alert.

=item B<--centreon-url>

Specify the Centreon interface URL (to be used with the action links).

=back

=cut