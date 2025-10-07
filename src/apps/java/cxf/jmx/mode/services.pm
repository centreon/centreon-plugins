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

package apps::java::cxf::jmx::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_service_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $instances,
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub service_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking service '%s' [port: %s]",
        $options{instance_value}->{service},
        $options{instance_value}->{port}
    );
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return sprintf(
        "Service '%s' [port: %s] ",
        $options{instance_value}->{service},
        $options{instance_value}->{port}
    );
}

sub prefix_fault_output {
    my ($self, %options) = @_;

    return "number of faults ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'services', type => 3, cb_prefix_output => 'prefix_service_output', cb_long_output => 'service_long_output', indent_long_output => '    ', message_multiple => 'All services are ok',
            group => [
                { name => 'invocation', type => 0, skipped_code => { -10 => 1 } },
                { name => 'faults', type => 0, cb_prefix_output => 'prefix_fault_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{invocation} = [
        { label => 'invocations', nlabel => 'service.invocations.count', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'service' }, { name => 'port' } ],
                output_template => 'number of invocations: %s',
                closure_custom_perfdata => $self->can('custom_service_perfdata')
            }
        },
        { label => 'inflight', nlabel => 'service.inflight.count', set => {
                key_values => [ { name => 'inFlight' }, { name => 'service' }, { name => 'port' } ],
                output_template => 'inflight: %s',
                closure_custom_perfdata => $self->can('custom_service_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{faults} = [
        { label => 'faults-checked-application', nlabel => 'service.faults.checked.application.count', set => {
                key_values => [ { name => 'checkedApplication', diff => 1 }, { name => 'service' }, { name => 'port' } ],
                output_template => 'checked application: %s',
                closure_custom_perfdata => $self->can('custom_service_perfdata')
            }
        },
        { label => 'faults-unchecked-application', nlabel => 'service.faults.unchecked.application.count', set => {
                key_values => [ { name => 'unCheckedApplication', diff => 1}, { name => 'service' }, { name => 'port' } ],
                output_template => 'unchecked application: %s',
                closure_custom_perfdata => $self->can('custom_service_perfdata')
            }
        },
        { label => 'faults-logical-runtime', nlabel => 'service.faults.logical.runtime.count', set => {
                key_values => [ { name => 'logicalRuntime', diff => 1 }, { name => 'service' }, { name => 'port' } ],
                output_template => 'logical runtime: %s',
                closure_custom_perfdata => $self->can('custom_service_perfdata')
            }
        },
        { label => 'faults-runtime', nlabel => 'service.faults.runtime.count', set => {
                key_values => [ { name => 'runtime', diff => 1 }, { name => 'service' }, { name => 'port' } ],
                output_template => 'runtime: %s',
                closure_custom_perfdata => $self->can('custom_service_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-service:s'            => { name => 'filter_service' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(service) %(port)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { service => 1, port => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        {
            mbean => 'org.apache.cxf:Attribute=*,bus.id=*,service=*,port=*,type=Metrics.Server',
            attributes => [ { name => 'Count' } ]
        }
    ];

    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{cache_name} = 'apache_cxf_' . $self->{mode} . '_' . 
        md5_hex(
            $options{custom}->get_connection_info() . '_' .
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_service}) ? $self->{option_results}->{filter_service} : '')
        );

    $self->{services} = {};
    foreach my $mbean (keys %$result) {
        my ($attribute, $bus_id, $service, $port);

        $service = $1 if ($mbean =~ /service=(.*?)(?:,|$)/);
        $port = $1 if ($mbean =~ /port=(.*?)(?:,|$)/);
        $attribute = $1 if ($mbean =~ /Attribute=(.*?)(?:,|$)/i);
        $bus_id = $1 if ($mbean =~ /bus\.id=(.*?)(?:,|$)/);
        $service =~ s/^"(.*)"$/$1/;
        $service = $1 if ($service =~ /\{(.*)\}/);
        $port =~ s/^"(.*)"$/$1/;

        next if (defined($self->{option_results}->{filter_service}) && $self->{option_results}->{filter_service} ne '' &&
            $service !~ /$self->{option_results}->{filter_service}/);

        if (!defined($self->{services}->{$bus_id})) {
            $self->{services}->{$bus_id} = {
                service => $service,
                port => $port,
                invocation => {
                    service => $service,
                    port => $port
                },
                faults => {
                    service => $service,
                    port => $port
                }
            };
        }

        $self->{services}->{$bus_id}->{invocation}->{total} = $result->{$mbean}->{Count} if ($attribute =~ /Totals/i);
        $self->{services}->{$bus_id}->{invocation}->{inFlight} = $result->{$mbean}->{Count} if ($attribute =~ /In Flight/i);

        $self->{services}->{$bus_id}->{faults}->{checkedApplication} = $result->{$mbean}->{Count} if ($attribute =~ /Checked Application Faults/i);
        $self->{services}->{$bus_id}->{faults}->{unCheckedApplication} = $result->{$mbean}->{Count} if ($attribute =~ /Unchecked Application Faults/i);
        $self->{services}->{$bus_id}->{faults}->{logicalRuntime} = $result->{$mbean}->{Count} if ($attribute =~ /Logical Runtime Faults/i);
        $self->{services}->{$bus_id}->{faults}->{runtime} = $result->{$mbean}->{Count} if ($attribute =~ /Runtime Faults/i);
    }

    if (scalar(keys %{$self->{services}}) <= 0) {
        $self->{output}->output_add(short_msg => 'no services found');
    }
}

1;

__END__

=head1 MODE

Check services.

=over 8

=item B<--filter-service>

Filter services by address (can be a regexp).

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(service) %(port)')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 
'invocations', 'inflight',
'faults-checked-application', 'faults-unchecked-application', 'faults-logical-runtime', 'faults-runtime'.

=back

=cut
