#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::paloalto::ssh::mode::vpn;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'state: %s [type: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{type}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output',  message_multiple => 'All vpn are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-ipsec', nlabel => 'vpn.total.ipsec.count', display_ok => 0, set => {
                key_values => [ { name => 'total_ipsec' } ],
                output_template => 'total ipsec vpn: %s',
                perfdatas => [
                    { value => 'total_ipsec_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'status',  threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'type' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "vpn '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'    => { name => 'unknown_status', default => '' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{state} ne "active"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'unknown_status', 'warning_status', 'critical_status'
        ]
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(command => 'show vpn flow', ForceArray => ['entry']);

    $self->{global} = { total_ipsec => 0 };
    $self->{vpn} = {};
    foreach (@{$result->{IPSec}->{entry}}) {
        $self->{vpn}->{$_->{name}} = {
            display => $_->{name},
            type => 'ipsec',
            state => $_->{state}
        };
        $self->{global}->{total_ipsec}++;
    }
}

1;

__END__

=head1 MODE

Check vpn.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{state}, %{type}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{type}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} ne "active"').
Can used special variables like: %{state}, %{type}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-ipsec'.

=back

=cut
