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

package hardware::server::cisco::ucs::xmlapi::mode::mgmtentities;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "management entity '%s' state is '%s' [role: %s] [services: %s]",
        $self->{result_values}->{id},
        $self->{result_values}->{state},
        $self->{result_values}->{role},
        $self->{result_values}->{ha_ready}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'entities', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All management entities are ok' },
    ];

    $self->{maps_counters}->{entities} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'id' }, { name => 'state' }, { name => 'role' }, { name => 'ha_ready' },
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

    return $self->{instance_mode}->{option_results}->{critical_status}
        if defined($self->{instance_mode}->{option_results}->{critical_status})
        && $self->{instance_mode}->{option_results}->{critical_status} ne ''
        && $self->{result_values}->{state} =~ /$self->{instance_mode}->{option_results}->{critical_status}/;

    return $self->{instance_mode}->{option_results}->{warning_status}
        if defined($self->{instance_mode}->{option_results}->{warning_status})
        && $self->{instance_mode}->{option_results}->{warning_status} ne ''
        && $self->{result_values}->{state} =~ /$self->{instance_mode}->{option_results}->{warning_status}/;

    return 'OK';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Management entity '" . $options{instance_value}->{id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status',  default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} !~ /^up$/i' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $entities = $options{custom}->request(class_id => 'mgmtEntity');

    $self->{entities} = {};
    foreach my $entity (@{$entities}) {
        my $id       = $entity->{id}       // $entity->{dn} // 'unknown';
        my $state    = $entity->{state}    // 'unknown';
        my $role     = $entity->{role}     // 'unknown';
        my $ha_ready = $entity->{haReady}  // $entity->{svcStates} // 'unknown';

        $self->{entities}->{$id} = {
            id       => $id,
            state    => $state,
            role     => $role,
            ha_ready => $ha_ready,
        };
    }

    if (scalar(keys %{$self->{entities}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No management entities found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS management entities (UCSM HA nodes) via XML API.

=over 8

=item B<--warning-status>

Warning threshold (default: '').

=item B<--critical-status>

Critical threshold (default: '%{state} !~ /^up$/i').

=back

=cut
