#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::hp::athonet::nodeexporter::api::mode::smsf;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_diameter_output {
    my ($self, %options) = @_;

    return sprintf(
        "diameter stack '%s' origin host '%s' ",
        $options{instance_value}->{stack},
        $options{instance_value}->{originHost}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'diameters', type => 1, cb_prefix_output => 'prefix_diameter_output', message_multiple => 'All diameter connections are ok', skipped_code => { -10 => 1 } },

    ];

    $self->{maps_counters}->{global} = [
        { label => 'sms-stored', nlabel => 'smsf.sms.stored.count', set => {
                key_values => [ { name => 'smsf_sms_stored' } ],
                output_template => 'SMS messages stored: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{diameters} = [
        { label => 'diameter-connection-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'originHost' }, { name => 'stack' } ],
                output_template => 'connection status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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

    $self->{global} = {};

    my $response = $options{custom}->query(queries => ['smsf_sms_stored']);
    $self->{global}->{smsf_sms_stored} = $response->[0]->{value}->[1];

    # TODO (need an example)
    #$response = $options{custom}->query(queries => ['sum(smsf_sms_queued) by (state)']);

    my $map_interface_status = { 1 => 'up', 0 => 'down' };

    $response = $options{custom}->query(queries => ['diameter_peer_status{target_type="smsf"}']);
    $self->{diameters} = {};
    my $id = 0;
    foreach (@$response) {
        $self->{diameters}->{$id} = {
            originHost => $_->{metric}->{orig_host},
            stack => $_->{metric}->{stack},
            status => $map_interface_status->{ $_->{value}->[1] }
        };
        
        $id++;
    }
}

1;

__END__

=head1 MODE

Check short message service function.

=over 8

=item B<--unknown-diameter-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--warning-diameter-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--critical-diameter-connection-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--warning-sms-stored>

Thresholds.

=item B<--critical-sms-stored>

Thresholds.

=back

=cut
