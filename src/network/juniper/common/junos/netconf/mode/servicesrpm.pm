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

package network::juniper::common::junos::netconf::mode::servicesrpm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_services_loss_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel},
        instances => $instances,
        value     => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0,
        max       => 100,
        unit      => '%'
    );
}

sub custom_services_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel},
        instances => $instances,
        value     => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'probe status: %s',
        $self->{result_values}->{probeStatus}
    );
}

sub service_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking service RPM '%s' [type: %s] [source address %s] [target address %s]",
        $options{instance_value}->{testName},
        $options{instance_value}->{probeType},
        $options{instance_value}->{sourceAddress},
        $options{instance_value}->{targetAddress}
    );
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return sprintf(
        "service RPM '%s' [type: %s] [source address %s] [target address %s] ",
        $options{instance_value}->{testName},
        $options{instance_value}->{probeType},
        $options{instance_value}->{sourceAddress},
        $options{instance_value}->{targetAddress}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of services ';
}

sub prefix_rtt_output {
    my ($self, %options) = @_;

    return 'round trip time delay ';
}

sub prefix_prtj_output {
    my ($self, %options) = @_;

    return 'positive round trip jitter delay ';
}

sub prefix_nrtj_output {
    my ($self, %options) = @_;

    return 'negative round trip jitter delay ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name               => 'services', type => 3, cb_prefix_output => 'prefix_service_output', cb_long_output => 'service_long_output',
          indent_long_output => '    ', message_multiple => 'All services are ok',
          group              => [
              { name => 'status', type => 0, skipped_code => { -10 => 1 } },
              { name => 'loss', type => 0, skipped_code => { -10 => 1 } },
              { name => 'rtt', type => 0, cb_prefix_output => 'prefix_rtt_output', skipped_code => { -10 => 1 } },
              { name => 'prtj', type => 0, cb_prefix_output => 'prefix_prtj_output', skipped_code => { -10 => 1 } },
              { name => 'nrtj', type => 0, cb_prefix_output => 'prefix_nrtj_output', skipped_code => { -10 => 1 } }
          ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'services-detected', display_ok => 0, nlabel => 'services.detected.count', set => {
            key_values      => [ { name => 'detected' } ],
            output_template => 'detected: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type  => 2,
            set   => {
                key_values                     => [
                    { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' },
                    { name => 'probeStatus' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{loss} = [
        { label => 'service-rpm-probe-loss-percentage', nlabel => 'service.rpm.probe.loss.percentage', set => {
            key_values              => [ { name => 'lastLossPercentage' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'loss: %.2f %%',
            closure_custom_perfdata => $self->can('custom_services_loss_perfdata')
        }
        }
    ];

    $self->{maps_counters}->{rtt} = [
        { label => 'service-rpm-probe-rtt-delay-average', nlabel => 'service.rpm.probe.rtt.delay.average.microseconds', set => {
            key_values              => [ { name => 'lastRTTAvgDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'average: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        },
        { label => 'service-rpm-probe-rtt-delay-jitter', nlabel => 'service.rpm.probe.rtt.delay.jitter.microseconds', set => {
            key_values              => [ { name => 'lastRTTJitterDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'jitter: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        },
        { label => 'service-rpm-probe-rtt-delay-stdev', nlabel => 'service.rpm.probe.rtt.delay.stdev.microseconds', set => {
            key_values              => [ { name => 'lastRTTStdevDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'stdev: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        }
    ];

    $self->{maps_counters}->{prtj} = [
        { label => 'service-rpm-probe-prtj-delay-average', nlabel => 'service.rpm.probe.prtj.delay.average.microseconds', set => {
            key_values              => [ { name => 'lastPRTJAvgDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'average: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        },
        { label => 'service-rpm-probe-prtj-delay-jitter', nlabel => 'service.rpm.probe.prtj.delay.jitter.microseconds', set => {
            key_values              => [ { name => 'lastPRTJJitterDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'jitter: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        },
        { label => 'service-rpm-probe-prtj-delay-stdev', nlabel => 'service.rpm.probe.prtj.delay.stdev.microseconds', set => {
            key_values              => [ { name => 'lastPRTJStdevDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'stdev: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        }
    ];

    $self->{maps_counters}->{nrtj} = [
        { label => 'service-rpm-probe-nrtj-delay-average', nlabel => 'service.rpm.probe.nrtj.delay.average.microseconds', set => {
            key_values              => [ { name => 'lastNRTJAvgDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'average: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        },
        { label => 'service-rpm-probe-nrtj-delay-jitter', nlabel => 'service.rpm.probe.nrtj.delay.jitter.microseconds', set => {
            key_values              => [ { name => 'lastNRTJJitterDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'jitter: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        },
        { label => 'service-rpm-probe-nrtj-delay-stdev', nlabel => 'service.rpm.probe.nrtj.delay.stdev.microseconds', set => {
            key_values              => [ { name => 'lastNRTJStdevDelay' }, { name => 'testName' }, { name => 'probeType' }, { name => 'sourceAddress' }, { name => 'targetAddress' } ],
            output_template         => 'stdev: %s usec',
            closure_custom_perfdata => $self->can('custom_services_perfdata')
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'               => { name => 'filter_name' },
        'filter-type:s'               => { name => 'filter_type' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(testName)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances   => $self->{option_results}->{custom_perfdata_instances},
        labels      => { testName => 1, probeType => 1, sourceAddress => 1, targetAddress => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_service_rpm_infos();

    $self->{global} = { detected => 0 };
    $self->{services} = {};
    foreach (@$result) {
        next if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_name}) &&
                 $_->{testName} !~ /$self->{option_results}->{filter_name}/);
        next if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_type}) &&
                 $_->{probeType} !~ /$self->{option_results}->{filter_type}/);

        $self->{services}->{ $_->{testName} } = {
            testName      => $_->{testName},
            targetAddress => $_->{targetAddress},
            sourceAddress => $_->{sourceAddress},
            probeType     => $_->{probeType},
            status        => {
                testName      => $_->{testName},
                targetAddress => $_->{targetAddress},
                sourceAddress => $_->{sourceAddress},
                probeType     => $_->{probeType},
                probeStatus   => $_->{probeStatus}
            },
            loss          => {
                testName           => $_->{testName},
                targetAddress      => $_->{targetAddress},
                sourceAddress      => $_->{sourceAddress},
                probeType          => $_->{probeType},
                lastLossPercentage => $_->{lastLossPercentage}
            },
            rtt           => {
                testName           => $_->{testName},
                targetAddress      => $_->{targetAddress},
                sourceAddress      => $_->{sourceAddress},
                probeType          => $_->{probeType},
                lastRTTAvgDelay    => $_->{lastRTTAvgDelay},
                lastRTTJitterDelay => $_->{lastRTTJitterDelay},
                lastRTTStdevDelay  => $_->{lastRTTStdevDelay}
            },
            prtj          => {
                testName            => $_->{testName},
                targetAddress       => $_->{targetAddress},
                sourceAddress       => $_->{sourceAddress},
                probeType           => $_->{probeType},
                lastPRTJAvgDelay    => $_->{lastPRTJAvgDelay},
                lastPRTJJitterDelay => $_->{lastPRTJJitterDelay},
                lastPRTJStdevDelay  => $_->{lastPRTJStdevDelay}
            },
            nrtj          => {
                testName            => $_->{testName},
                targetAddress       => $_->{targetAddress},
                sourceAddress       => $_->{sourceAddress},
                probeType           => $_->{probeType},
                lastNRTJAvgDelay    => $_->{lastNRTJAvgDelay},
                lastNRTJJitterDelay => $_->{lastNRTJJitterDelay},
                lastNRTJStdevDelay  => $_->{lastNRTJStdevDelay}
            }
        };

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check real-time performance monitoring (RPM) services.

=over 8

=item B<--filter-name>

Filter service by name.

=item B<--filter-type>

Filter service by type.

=item B<--custom-perfdata-instances>

Define performance data instances (default: C<%(testName)>)

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{testName}>, C<%{probeType}>, C<%{sourceAddress}>, C<%{targetAddress}>, C<%{probeStatus}>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{testName}>, C<%{probeType}>, C<%{sourceAddress}>, C<%{targetAddress}>, C<%{probeStatus}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{testName}>, C<%{probeType}>, C<%{sourceAddress}>, C<%{targetAddress}>, C<%{probeStatus}>

=item B<--warning-services-detected>

Define the services detected conditions to match for the status to be WARNING.

=item B<--critical-services-detected>

Define the services detected conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-loss-percentage>

Define the service RPM probe loss percentage conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-loss-percentage>

Define the service RPM probe loss percentage conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-rtt-delay-average>

Define the service RPM probe route-trip time delay average conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-rtt-delay-average>

Define the service RPM probe route-trip time delay average conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-rtt-delay-jitter>

Define the service RPM probe route-trip time delay jitter conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-rtt-delay-jitter>

Define the service RPM probe route-trip time delay jitter conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-rtt-delay-stdev>

Define the service RPM probe route-trip time delay standard deviation conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-rtt-delay-stdev>

Define the service RPM probe route-trip time delay standard deviation conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-prtj-delay-average>

Define the service RPM probe positive round trip jitter delay average conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-prtj-delay-average>

Define the service RPM probe positive round trip jitter delay average conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-prtj-delay-jitter>

Define the service RPM probe positive round trip jitter delay jitter conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-prtj-delay-jitter>

Define the service RPM probe positive round trip jitter delay jitter conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-prtj-delay-stdev>

Define the service RPM probe positive round trip jitter delay standard deviation conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-prtj-delay-stdev>

Define the service RPM probe positive round trip jitter delay standard deviation conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-nrtj-delay-average>

Define the service RPM probe negative round trip jitter delay average conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-nrtj-delay-average>

Define the service RPM probe negative round trip jitter delay average conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-nrtj-delay-jitter>

Define the service RPM probe negative round trip jitter delay jitter conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-nrtj-delay-jitter>

Define the service RPM probe negative round trip jitter delay jitter conditions to match for the status to be CRITICAL.

=item B<--warning-service-rpm-probe-nrtj-delay-stdev>

Define the service RPM probe negative round trip jitter delay standard deviation conditions to match for the status to be WARNING.

=item B<--critical-service-rpm-probe-nrtj-delay-stdev>

Define the service RPM probe negative round trip jitter delay standard deviation conditions to match for the status to be CRITICAL.

=back

=cut
