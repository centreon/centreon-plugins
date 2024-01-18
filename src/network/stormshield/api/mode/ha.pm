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

package network::stormshield::api::mode::ha;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_link_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'link status: %s',
        $self->{result_values}->{linkStatus}
    );
}

sub custom_member_state_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [mode: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{mode}
    );
}

sub custom_member_config_output {
    my ($self, %options) = @_;

    return sprintf(
        'config sync: %s',
        $self->{result_values}->{isConfigSync}
    );
}

sub member_long_output {
    my ($self, %options) = @_;

    return "checking member '" . $options{instance_value}->{name} . "'";
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "member '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Members ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'members', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All stack members are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'config', type => 0, skipped_code => { -10 => 1 } },
                { name => 'quality', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'members-detected', nlabel => 'members.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'members detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    foreach ('none', 'starting', 'waiting_peer', 'running', 'ready', 'reboot', 'down', 'initializing') {
        my $label = $_;
        $label =~ s/_/-/;
        push @{$self->{maps_counters}->{global}}, {
                label => 'members-' . $label, nlabel => 'members.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => 'state_' . $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    }

    $self->{maps_counters}->{status} = [
        { label => 'member-state', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'mode' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_member_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'member-link-status',
            type => 2,
            unknown_default => '%{linkStatus} =~ /unknown/i',
            critical_default => '%{linkStatus} =~ /failed|failing/i',
            set => {
                key_values => [ { name => 'linkStatus' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{config} = [
        { label => 'member-config', type => 2, warning_default => '%{isConfigSync} eq "no"', set => {
                key_values => [ { name => 'isConfigSync' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_member_config_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{quality} = [
        { label => 'member-quality', nlabel => 'member.quality.percentage', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'quality: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ha = $options{custom}->request(command => 'ha info');

    $self->{global} = { detected => 0 };
    foreach ('none', 'starting', 'waiting_peer', 'running', 'ready', 'reboot', 'down', 'initializing') {
        $self->{global}->{'state_' . $_ } = 0;
    }

    $self->{members} = {};
    foreach my $name (keys %$ha) {
        my $values = {};
        foreach my $entry (@{$ha->{$name}}) {
            foreach my $key (keys %$entry) {
                $values->{$key} = $entry->{$key};
            }
        }

        next if ($values->{Reply} == 0);

        $values->{State} = lc($values->{State});
        $values->{State} =~ s/ /_/g;

        $self->{global}->{detected}++;
        $self->{global}->{'state_' . $values->{State} }++;

        $self->{members}->{$name} = {
            name => $name,
            status => {
                name => $name,
                mode => lc($values->{Mode}),
                state => $values->{State},
                linkStatus => lc($values->{Link})
            },
            config => {
                name => $name,
                isConfigSync => $values->{IsConfigSync} =~ /1|true/i ? 'yes' : 'no'
            },
            quality => { current => $values->{Quality} }
        };
    }
}

1;

__END__

=head1 MODE

Check high availability.

=over 8

=item B<--unknown-member-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{name}

=item B<--warning-member-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{name}

=item B<--critical-member-state>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{name}

=item B<--unknown-member-link-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{linkStatus} =~ /unknown/i').
You can use the following variables: %{linkStatus}, %{name}

=item B<--warning-member-link-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{linkStatus}, %{name}

=item B<--critical-member-link-status>

Define the conditions to match for the status to be CRITICAL (default: '%{linkStatus} =~ /failed|failing/i').
You can use the following variables: %{linkStatus}, %{name}

=item B<--unknown-member-config>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{isConfigSync}, %{name}

=item B<--warning-member-config>

Define the conditions to match for the status to be WARNING  (default: '%{isConfigSync} eq "no"').
You can use the following variables: %{isConfigSync}, %{name}

=item B<--critical-member-config>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{isConfigSync}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'member-quality', 'members-detected', 'members-none',
'members-starting', 'members-waiting-peer', 'members-running',
'members-ready', 'members-reboot', 'members-down', 'members-initializing'.

=back

=cut
