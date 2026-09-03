#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::xmlapi::mode::serviceprofile;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "service profile '%s' assoc state is '%s' [oper state: %s] [assigned to: %s]",
        $self->{result_values}->{name},
        $self->{result_values}->{assoc_state},
        $self->{result_values}->{oper_state},
        $self->{result_values}->{assigned_to}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global',   type => 0 },
        { name => 'profiles', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All service profiles are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total',    nlabel => 'serviceprofiles.total.count',    set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total profiles: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'associated',   nlabel => 'serviceprofiles.associated.count', set => {
            key_values      => [ { name => 'associated' } ],
            output_template => 'Associated: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'unassociated', nlabel => 'serviceprofiles.unassociated.count', set => {
            key_values      => [ { name => 'unassociated' } ],
            output_template => 'Unassociated: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{profiles} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'name' }, { name => 'assoc_state' },
                { name => 'oper_state' }, { name => 'assigned_to' },
            ],
            closure_custom_output           => $self->can('custom_status_output'),
            closure_custom_perfdata         => sub { return 0; },
            closure_custom_threshold_check => \&_threshold_check,
          }
        },
    ];
}

sub _threshold_check {
    my ($self, %options) = @_;

    return 'CRITICAL'
        if defined($self->{instance_mode}->{option_results}->{critical_status})
        && $self->{instance_mode}->{option_results}->{critical_status} ne ''
        && eval "$self->{instance_mode}->{option_results}->{critical_status}";

    return 'WARNING'
        if defined($self->{instance_mode}->{option_results}->{warning_status})
        && $self->{instance_mode}->{option_results}->{warning_status} ne ''
        && eval "$self->{instance_mode}->{option_results}->{warning_status}";

    return 'OK';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Service profile '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status',  default => '' },
        'critical-status:s' => { name => 'critical_status',
            default => '%{assoc_state} =~ /associated/i && %{oper_state} !~ /^ok$/i' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $profiles = $options{custom}->request(class_id => 'lsServer');

    $self->{global}   = { total => 0, associated => 0, unassociated => 0 };
    $self->{profiles} = {};

    foreach my $profile (@{$profiles}) {
        my $name       = $profile->{name}       // $profile->{dn} // 'unknown';
        my $assoc      = $profile->{assocState} // 'unassociated';
        my $oper       = $profile->{operState}  // 'unknown';
        my $assigned   = $profile->{pnDn}       // '';
        my $type       = $profile->{type}        // 'initial';

        # Skip template profiles
        next if $type eq 'updating-template' || $type eq 'initial-template';

        next if defined($self->{option_results}->{filter_name})
            && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/;

        $self->{global}->{total}++;
        if ($assoc =~ /^associated$/i) {
            $self->{global}->{associated}++;
        } else {
            $self->{global}->{unassociated}++;
        }

        $self->{profiles}->{$name} = {
            name        => $name,
            assoc_state => $assoc,
            oper_state  => $oper,
            assigned_to => $assigned,
        };
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS service profiles via XML API (lsServer class).

=over 8

=item B<--filter-name>

Filter service profiles by name (regexp).

=item B<--warning-status>

Warning threshold (default: '').

=item B<--critical-status>

Critical threshold (default: '%{assoc_state} =~ /associated/i && %{oper_state} !~ /^ok$/i').

=back

=cut
