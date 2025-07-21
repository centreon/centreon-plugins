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

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
}

sub service_long_output {
    my ($self, %options) = @_;

    return "checking service '" . $options{instance} . "'";
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance} . "' ";
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
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'invocation', type => 0, skipped_code => { -10 => 1 } },
                { name => 'fault', type => 0, cb_prefix_output => 'prefix_fault_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, warning_default => '%{state} =~ /suspend/i', set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{faults} = [
        { label => 'invocations', nlabel => 'service.invocations.count', set => {
                key_values => [ { name => 'numInvocations', diff => 1 }, { name => 'name' } ],
                output_template => 'number of invocations: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'handling-time', nlabel => 'service.handling.time.milliseconds', set => {
                key_values => [ { name => 'totalHandlingTime', diff => 1 }, { name => 'name' } ],
                output_template => 'handling time: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'average-processing-time', nlabel => 'service.processing.time.average.milliseconds', set => {
                key_values => [ { name => 'averageProcessingTime', diff => 1 }, { name => 'name' } ],
                output_template => 'average processing time: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{faults} = [
        { label => 'faults-checked-application', nlabel => 'service.faults.checked.application.count', set => {
                key_values => [ { name => 'checkedApplication', diff => 1 }, { name => 'name' } ],
                output_template => 'checked application: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'faults-unchecked-application', nlabel => 'service.faults.unchecked.application.count', set => {
                key_values => [ { name => 'unCheckedApplication', diff => 1 }, { name => 'name' } ],
                output_template => 'unchecked application: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'faults-logical-runtime', nlabel => 'service.faults.logical.runtime.count', set => {
                key_values => [ { name => 'logicalRuntime', diff => 1 }, { name => 'name' } ],
                output_template => 'logical runtime: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'faults-runtime', nlabel => 'service.faults.runtime.count', set => {
                key_values => [ { name => 'runtime', diff => 1 }, { name => 'name' } ],
                output_template => 'runtime: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        {
            mbean => 'org.apache.cxf:bus.id=*,type=Performance.Counter.Server,service=*,port=*',
            attributes => [
                { name => 'NumInvocations' }, { name => 'TotalHandlingTime' }, { name => 'AverageProcessingTime' },
                { name => 'NumCheckedApplicationFaults' }, { name => 'NumLogicalRuntimeFaults' },
                { name => 'NumRuntimeFaults' }, { name => 'NumUnCheckedApplicationFaults' }
            ]
        }
    ];

    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{cache_name} = 'apache_cxf_' . $self->{mode} . '_' . 
        md5_hex(
            $options{custom}->get_connection_info() . '_' .
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : ''))
        );

    $self->{routes} = {};
    foreach my $mbean (keys %$result) {
        my ($service, $port);

        $service = $1 if ($mbean =~ /service=(.*?)(?:,|$)/);
        $port = $1 if ($mbean =~ /port=(.*?)(?:,|$)/);
        $service =~ s/^"(.*)"$/$1/;
        $port =~ s/^"(.*)"$/$1/;

        my $name = $service . ':' . $port;

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{services}->{$name} = {
            global => {
                name => $name,
                state => $result->{$mbean}->{'State'}
            },
            invocation => {
                name => $name,
                numInvocations => $result->{$mbean}->{'NumInvocations'},
                totalHandlingTime => $result->{$mbean}->{'TotalHandlingTime'},
                averageProcessingTime => $result->{$mbean}->{'AverageProcessingTime'}
            },
            faults => {
                name => $name,
                checkedApplication => $result->{$mbean}->{'NumCheckedApplicationFaults'},
                unCheckedApplication => $result->{$mbean}->{'NumUnCheckedApplicationFaults'},
                logicalRuntime => $result->{$mbean}->{'NumLogicalRuntimeFaults'},
                runtime => $result->{$mbean}->{'NumRuntimeFaults'}
            }
        };
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

=item B<--filter-name>

Filter services by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{statisticsEnabled} eq "no" || %{state} =~ /suspend/i').
You can use the following variables: %{state}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 
'invocations', 'handling-time' (ms), 'average-processing-time' (ms),
'faults-checked-application', 'faults-unchecked-application', 'faults-logical-runtime', 'faults-runtime'.

=back

=cut
