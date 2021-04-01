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

package notification::sirportly::mode::ticket;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'            => { name => 'hostname', default => 'api.sirportly.com' },
        'port:s'                => { name => 'port', default => 443 },
        'proto:s'               => { name => 'proto', default => 'https' },
        'api-token:s'           => { name => 'api_token' },
        'api-secret:s'          => { name => 'api_secret' },
        'cache'                 => { name => 'cache' },
        'contact-name:s'        => { name => 'contact_name', default => 'Centreon Notifications' },
        'contact-type:s'        => { name => 'contact_type', default => 'telephone' },
        'contact-data:s'        => { name => 'contact_data', default => '-' },
        'brand:s'               => { name => 'brand' },
        'department:s'          => { name => 'department' },
        'submit-user:s'         => { name => 'submit_user' },
        'close-user:s'          => { name => 'close_user' },
        'submit-status:s'       => { name => 'submit_status' },
        'close-status:s'        => { name => 'close_status' },
        'priority-mapping:s'    => { name => 'priority_mapping' },
        'priority:s'            => { name => 'priority' },
        'item-id:s'             => { name => 'item_id' },
        'subject:s'             => { name => 'subject' },
        'message:s'             => { name => 'message' },
        'timeout:s'             => { name => 'timeout' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    foreach (('api_token', 'api_secret', 'brand', 'department', 'submit_status',
        'close_status', 'priority', 'item_id', 'subject', 'message')) {
        if (!defined($self->{option_results}->{$_})) {
            my $option = $_;
            $option =~ s/_/-/g;
            $self->{output}->add_option_msg(short_msg => "You need to set --$option option");
            $self->{output}->option_exit();
        }
    }

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{cache}->check_options(option_results => $self->{option_results});
}

sub proceed {
    my ($self, %options) = @_;

    # Let's compute a priority mapping hash, with lc keys
    my %priority_mapping;
    if (defined($self->{option_results}->{priority_mapping})) {
        my $i = 0;
        %priority_mapping = map { $i++ % 2 ? $_ : lc } split /[:,]/, $self->{option_results}->{priority_mapping};
    }

    # Let's compute a ticket tag to be able to find the opened ticket later on
    my $tag = $options{item_id};
    if ($options{priority} =~ /^(UP|DOWN|UNREACHABLE)$/i) {
        $tag = "centreon-hst:$tag";
    } else {
        $tag = "centreon-svc:$tag";
    }

    # Is there an existing Sirportly ticket for this item ?
    my $post_param = [
        "spql=SELECT tickets.reference,statuses.name FROM tickets WHERE ticket_tags.tag=\"$tag\" AND statuses.name!=\"$self->{option_results}->{close_status}\" ORDER BY tickets.submitted_at DESC LIMIT 1",
    ];
    my $response = $self->{http}->request(method => 'POST', url_path =>'/api/v2/tickets/spql', post_param => $post_param, warning_status => '', unknown_status => '', critical_status => '');
    my $ticket_info;
    eval {
        $ticket_info = JSON::XS->new->decode($response)->{results}[0];
    };

    if ($options{priority} =~ /^(UP|OK)$/i) { # Close the ticket
        if (defined($ticket_info)) {
            $post_param = [
                "ticket=$ticket_info->[0]",
                "contact=$self->{option_results}->{contact_name}",
                "message=$options{message}",
            ];
            $self->{http}->request(method => 'POST', url_path =>'/api/v2/tickets/post_update', post_param => $post_param, warning_status => '', unknown_status => '', critical_status => '');
            if ($ticket_info->[1] eq $self->{option_results}->{submit_status}) {
                $post_param = [
                    "ticket=$ticket_info->[0]",
                    "user=" . (defined($self->{option_results}->{close_user}) ? $self->{option_results}->{close_user} : ""),
                    "status=$self->{option_results}->{close_status}",
                ];
                my $response = $self->{http}->request(method => 'POST', url_path =>'/api/v2/tickets/update', post_param => $post_param, warning_status => '', unknown_status => '', critical_status => '');
                eval {
                    JSON::XS->new->decode($response);
                };
                if ($@) { # We only check we received a response from Sirportly, thus we don't take the risk to hold the queue/cache processing
                    $ticket_info->[0] = "failed";
                }
            }
        }
    } elsif (defined($ticket_info)) { # Update an existing ticket
        $post_param = [
            "ticket=$ticket_info->[0]",
            "contact=$self->{option_results}->{contact_name}",
            "message=$options{message}",
        ];
        $self->{http}->request(method => 'POST', url_path =>'/api/v2/tickets/post_update', post_param => $post_param, warning_status => '', unknown_status => '', critical_status => '');
        $post_param = [
            "ticket=$ticket_info->[0]",
            "priority=" . (defined($priority_mapping{lc($options{priority})}) ? $priority_mapping{lc($options{priority})} : $options{priority}),
        ];
        my $response = $self->{http}->request(method => 'POST', url_path =>'/api/v2/tickets/update', post_param => $post_param, warning_status => '', unknown_status => '', critical_status => '');
        eval {
            JSON::XS->new->decode($response);
        };
        if ($@) { # We only check we received a response from Sirportly, thus we don't take the risk to hold the queue/cache processing
            $ticket_info->[0] = 'failed';
        }
    } else { # Open a new ticket
        $post_param = [
            "contact_name=$self->{option_results}->{contact_name}",
            "contact_method_type=$self->{option_results}->{contact_type}",
            "contact_method_data=$self->{option_results}->{contact_data}",
            "brand=$self->{option_results}->{brand}",
            "department=$self->{option_results}->{department}",
            "user=" . (defined($self->{option_results}->{submit_user}) ? $self->{option_results}->{submit_user} : ""),
            "status=$self->{option_results}->{submit_status}",
            "priority=" . (defined($priority_mapping{lc($options{priority})}) ? $priority_mapping{lc($options{priority})} : $options{priority}),
            "tag_list=$tag",
            "subject=$options{subject}",
            "message=$options{message}",
        ];
        my $response = $self->{http}->request(method => 'POST', url_path =>'/api/v2/tickets/submit', post_param => $post_param, warning_status => '', unknown_status => '', critical_status => '');
        my $decoded;
        eval {
            $decoded = JSON::XS->new->decode($response);
        };
        if ($@ || !defined($decoded->{reference})) { # Here we check Sirportly correctly received the new ticket, as it's the most important step
            $ticket_info->[0] = "failed";
        } else {
            $ticket_info->[0] = $decoded->{reference};
        }
    }

    # Return proceeded ticket
    return $ticket_info->[0];
}

sub run {
    my ($self, %options) = @_;

    # Authentication headers
    $self->{http}->add_header(key => 'X-Auth-Token', value => $self->{option_results}->{api_token});
    $self->{http}->add_header(key => 'X-Auth-Secret', value => $self->{option_results}->{api_secret});

    # Load cache
    $self->{cache}->read(statefile => 'sirportly_api_' . $self->{option_results}->{api_token});
    my $cache;
    if (defined($self->{option_results}->{cache})) {
        $cache = $self->{cache}->get(name => 'cache');
    } else {
        $cache = {};
    }

    # Add current item to cache
    my $cache_index = time();
    $cache->{$cache_index}->{item_id} = $self->{option_results}->{item_id};
    $cache->{$cache_index}->{priority} = $self->{option_results}->{priority};
    $cache->{$cache_index}->{subject} = $self->{option_results}->{subject};
    $cache->{$cache_index}->{message} = $self->{option_results}->{message};
    $self->{cache}->write(data => {cache => $cache});

    # Proceed cached notifications
    my $cache_size = keys %{$cache};
    my $cache_done = 0;
    foreach $cache_index (sort keys %{$cache}) {
        my $ticket_reference = $self->proceed(
            priority => $cache->{$cache_index}->{priority},
            item_id  => $cache->{$cache_index}->{item_id},
            subject  => $cache->{$cache_index}->{subject},
            message  => $cache->{$cache_index}->{message},
        );
        if (!defined($ticket_reference) || $ticket_reference ne 'failed') {
            delete($cache->{$cache_index});
            $self->{cache}->write(data => {cache => $cache});
            $cache_done++;
        } else {
            last;
        }
    }

    # Exit
    $self->{output}->output_add(
        severity => ($cache_size == $cache_done) ? 'OK' : 'CRITICAL',
        short_msg => "Proceeded " . $cache_done . "/" . $cache_size . " notifications"
    );
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Open tickets via Sirportly API (https://sirportly.com/docs/api-specification/)

=over 6

=item B<--hostname>

Hostname of the OVH SMS API (default: 'api.sirportly.com').

=item B<--port>

Port used by API (default: '443').

=item B<--proto>

Specify https if needed (Default: 'https').

=item B<--api-token>

Specify the API authentication token.

=item B<--api-secret>

Specify the API authentication secret.

=item B<--cache>

Cache notifications not correctly delivered, to retry at next run.

=item B<--contact-name>

Specify the contact name for this ticket (default: 'Centreon Notifications').

=item B<--contact-type>

Specify the contact type (email or telephone) of the contact (default: 'telephone').

=item B<--contact-data>

Specify the email address or telephone number of the contact (default: '-').

=item B<--brand>

Specify the brand for this ticket.

=item B<--department>

Specify the department for this ticket.

=item B<--submit-user>

Specify the user to assign the ticket to when submitting the ticket.

=item B<--close-user>

Specify the user to assign the ticket to when closing the ticket.

=item B<--submit-status>

Specify the Sirportly status to be used when submitting the ticket.

=item B<--close-status>

Specify the Sirportly status to be used when closing the ticket (only if still in submit status).

=item B<--priority-mapping>

Map the Centreon priorities to Sirportly ones, comma separated (syntax: (down|unreachable|warning|critical|unknown):priority).

=item B<--priority>

Specify the priority for this ticket.

=item B<--item-id>

Specify the host or service ID for this ticket.

=item B<--subject>

Specify the subject for this ticket.

=item B<--message>

Specify the message for this ticket.

=item B<--timeout>

Threshold for HTTP timeout

=back

=cut
