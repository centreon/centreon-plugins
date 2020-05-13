#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package cloud::ibm::softlayer::mode::opentickets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_ticket_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Title: '%s', Group: '%s', Priority: %s, Create Date: %s (%s ago)",
        $self->{result_values}->{title}, 
        $self->{result_values}->{group},
        $self->{result_values}->{priority},
        $self->{result_values}->{create_date},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{since}));
    return $msg;
}

sub custom_ticket_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{id} = $options{new_datas}->{$self->{instance} . '_id'};
    $self->{result_values}->{title} = $options{new_datas}->{$self->{instance} . '_title'};
    $self->{result_values}->{priority} = $options{new_datas}->{$self->{instance} . '_priority'};
    $self->{result_values}->{create_date} = $options{new_datas}->{$self->{instance} . '_create_date'};
    $self->{result_values}->{group} = $options{new_datas}->{$self->{instance} . '_group'};
    $self->{result_values}->{since} = $options{new_datas}->{$self->{instance} . '_since'};
    return 0;
}

sub prefix_tickets_output {
    my ($self, %options) = @_;
    
    return "Ticket '" . $options{instance_value}->{id} . "' is open with ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'tickets', type => 1, cb_prefix_output => 'prefix_tickets_output' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'open', set => {
                key_values => [ { name => 'open' } ],
                output_template => 'Number of open tickets : %d',
                perfdatas => [
                    { label => 'open_tickets', value => 'open', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{tickets} = [
        { label => 'ticket', threshold => 0, set => {
                key_values => [ { name => 'id' }, { name => 'title' }, { name => 'priority' }, { name => 'create_date' },
                { name => 'group' }, { name => 'since' } ],
                closure_custom_calc => $self->can('custom_ticket_calc'),
                closure_custom_output => $self->can('custom_ticket_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "ticket-group:s"    => { name => 'ticket_group' },
                                    "warning-status:s"  => { name => 'warning_status', default => '' },
                                    "critical-status:s" => { name => 'critical_status', default => '' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global}->{open} = 0;
    $self->{tickets} = {};

    my $group_id = '';
    my %groups_hash;
    my $groups = $options{custom}->get_endpoint(service => 'SoftLayer_Ticket', method => 'getAllTicketGroups', extra_content => '');
    foreach my $group (@{$groups->{'ns1:getAllTicketGroupsResponse'}->{'getAllTicketGroupsReturn'}->{'item'}}) {
        $groups_hash{$group->{id}->{content}} = $group->{name}->{content};

        if (defined($self->{option_results}->{ticket_group}) && $self->{option_results}->{ticket_group} ne '' && 
            $group->{name}->{content} =~ /^$self->{option_results}->{ticket_group}$/) {
            $group_id = $group->{id}->{content};
        }
    }

    if (defined($self->{option_results}->{ticket_group}) && $self->{option_results}->{ticket_group} ne '' && $group_id eq '') {
        $self->{output}->add_option_msg(short_msg => "Ticket group ID not found from API.");
        $self->{output}->option_exit();
    }

    my $current_time = time();

    my $tickets = $options{custom}->get_endpoint(service => 'SoftLayer_Account', method => 'getOpenTickets', extra_content => '');
    foreach my $ticket (@{$tickets->{'ns1:getOpenTicketsResponse'}->{'getOpenTicketsReturn'}->{'item'}}) {
        next if (defined($group_id) && $group_id ne '' && $ticket->{groupId}->{content} ne $group_id);

        next if ($ticket->{createDate}->{content} !~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(.*)$/); # 2018-10-18T15:36:54+00:00
        my $dt = DateTime->new(
            year => $1,
            month => $2,
            day => $3,
            hour => $4,
            minute => $5,
            second => $6,
            time_zone => $7
        );
        
        $self->{tickets}->{$ticket->{id}->{content}} = {
            id => $ticket->{id}->{content},
            title => $ticket->{title}->{content},
            priority => $ticket->{priority}->{content},
            create_date => $ticket->{createDate}->{content},
            group => $groups_hash{$ticket->{groupId}->{content}},
            since => $current_time - $dt->epoch,
        };

        $self->{global}->{open}++;
    }
}

1;

__END__

=head1 MODE

Check if there is open tickets

=over 8

=item B<--ticket-group>

Name of the ticket group (Can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{id}, %{title},
%{priority}, %{create_date}, %{group}, %{since}.

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{id}, %{title},
%{priority}, %{create_date}, %{group}, %{since}.

=item B<--warning-open>

Threshold warning for open tickets.

=item B<--critical-open>

Threshold critical for open tickets.

=back

=cut
