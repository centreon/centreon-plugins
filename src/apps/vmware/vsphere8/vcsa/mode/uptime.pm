#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcsa::mode::uptime;

use base qw(apps::vmware::vsphere8::vcsa::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(change_seconds);
my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_uptime_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'System uptime is: %s',
        change_seconds(value => $self->{result_values}->{uptime}, start => 'd')
    );


    return $msg;
}

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'uptime', unit => $self->{instance_mode}->{option_results}->{unit},
        nlabel => 'system.uptime.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        value => sprintf("%.2f", $self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_uptime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => sprintf("%.2f", $self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'uptime',
            nlabel => 'system.uptime.seconds',
            type   => 1,
            set    => {
                key_values                     => [ { name => 'uptime' } ],
                closure_custom_output          => $self->can('custom_uptime_output'),
                closure_custom_perfdata        => $self->can('custom_uptime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_uptime_threshold')

            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => { 'unit:s' => { name => 'unit', default => 's' } }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $self->get_value(%options, endpoint => 'system/uptime');

    $self->{global}->{uptime} = $response;

}

1;

__END__

=head1 MODE

Monitor the number of VMware VMs through vSphere 8 REST API.

=over 8

=item B<--warning-uptime>

Threshold.

=item B<--critical-uptime>

Threshold.

=item B<--unit>

Select the time unit for thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=back

=cut
