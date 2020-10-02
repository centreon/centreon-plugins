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

package network::paloalto::ssh::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [type: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'interface', type => 1, cb_prefix_output => 'prefix_interface_output',  message_multiple => 'All interface are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'interfaces.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total interfaces: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{interface} = [
        { label => 'status', type => 2, critical_default => '%{state} ne "up"', set => {
                key_values => [
                    { name => 'state' }, { name => 'type' },
                    { name => 'ha_state' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "interface '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(command => 'show high-availability state');
    my $ha_state = defined($result->{group}->{'local-info'}->{state}) ? $result->{group}->{'local-info'}->{state} : 'disabled';

    $result = $options{custom}->execute_command(command => 'show interface all', ForceArray => ['entry']);

    $self->{global} = { total => 0 };
    $self->{interface} = {};
    foreach (@{$result->{hw}->{entry}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{interface}->{$_->{name}} = {
            display => $_->{name},
            type => $_->{type},
            state => $_->{state},
            ha_state => $ha_state
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--filter-name>

Filter interface name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{state}, %{type}, %{ha_state}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{type}, %{ha_state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} ne "active"').
Can used special variables like: %{state}, %{type}, %{ha_state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total'.

=back

=cut
