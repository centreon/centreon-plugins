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

package apps::incus::restapi::mode::instances;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters);

# GET /1.0/instances?recursion=1 metadata entry, shortened:
# {"name":"foo","status":"Running","type":"container","project":"foo","location":"server01"}
# InstanceState.status: Running, Stopped, Frozen or Error.
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml

sub count_statuses {
    my ($instances) = @_;

    my %counts = (Running => 0, Stopped => 0, Frozen => 0, Error => 0);
    foreach my $instance (@{$instances // []}) {
        my $status = $instance->{status};
        $counts{$status}++ if (defined($status) && exists($counts{$status}));
    }
    return \%counts;
}

sub instance_is_critical {
    my ($status, $alert_stopped) = @_;

    return 0 if (!defined($status));
    return 1 if ($status eq 'Error' || $status eq 'Frozen');
    return 1 if ($alert_stopped && $status eq 'Stopped');
    return 0;
}

sub instance_id {
    my ($instance) = @_;

    return join('/', map { defined($_) ? $_ : '' } ($instance->{project}, $instance->{name}, $instance->{location}));
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'alert-stopped' => { name => 'alert_stopped' }
    });
    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'counts', type => COUNTER_TYPE_GLOBAL, prefix_output => 'instances ' },
        { name => 'instance', type => COUNTER_TYPE_INSTANCE, prefix_output => "instance '%{display}' ", message_multiple => 'all instances are ok' }
    ];

    $self->{maps_counters}->{counts} = [
        { label => 'running', nlabel => 'incus.instances.running.count', set => {
                key_values => [ { name => 'running' } ],
                output_template => 'running: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'stopped', nlabel => 'incus.instances.stopped.count', set => {
                key_values => [ { name => 'stopped' } ],
                output_template => 'stopped: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'frozen', nlabel => 'incus.instances.frozen.count', set => {
                key_values => [ { name => 'frozen' } ],
                output_template => 'frozen: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'error', nlabel => 'incus.instances.error.count', set => {
                key_values => [ { name => 'error' } ],
                output_template => 'error: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{instance} = [
        { label => 'status', type => COUNTER_KIND_TEXT, threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                output_template => 'status %s',
                output_use => 'status',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_instance_threshold')
            }
        }
    ];
}

# Error and Frozen are always critical. Stopped is critical only with
# --alert-stopped. A status expression cannot express that flag, so this
# stays a callback instead of catalog_status_threshold_ng.
sub custom_instance_threshold {
    my ($self, %options) = @_;

    my $alert_stopped = $self->{instance_mode}->{option_results}->{alert_stopped} ? 1 : 0;
    return instance_is_critical($self->{result_values}->{status}, $alert_stopped) ? 'critical' : 'ok';
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->instances(recursion => 1);
    my $instances = $options{custom}->filter_records(records => $metadata, name_key => 'name');
    my $counts = count_statuses($instances);

    $self->{counts} = {
        running => $counts->{Running},
        stopped => $counts->{Stopped},
        frozen => $counts->{Frozen},
        error => $counts->{Error}
    };
    $self->{instance} = {};
    foreach my $instance (@$instances) {
        $self->{instance}->{instance_id($instance)} = {
            display => defined($instance->{name}) ? $instance->{name} : '',
            status => defined($instance->{status}) ? $instance->{status} : ''
        };
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'status', 'type', 'project', 'location']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->instances(recursion => 1);
    my $instances = $options{custom}->filter_records(records => $metadata, name_key => 'name');
    foreach my $instance (@$instances) {
        $self->{output}->add_disco_entry(
            name => $instance->{name} // '',
            status => $instance->{status} // '',
            type => $instance->{type} // '',
            project => $instance->{project} // '',
            location => $instance->{location} // ''
        );
    }
}

1;

__END__

=head1 MODE

Check instance status from GET /1.0/instances?recursion=1.

Error and Frozen are critical. Stopped does not change the state unless
--alert-stopped is set. Running is ok.

=over 8

=item B<--alert-stopped>

Critical when an instance status is Stopped.

=item B<--warning-running>

Warning threshold for the number of running instances. Empty by default.

=item B<--critical-running>

Critical threshold for the number of running instances. Empty by default.

=item B<--warning-stopped>

Warning threshold for the number of stopped instances. Empty by default.

=item B<--critical-stopped>

Critical threshold for the number of stopped instances. Empty by default.

=item B<--warning-frozen>

Warning threshold for the number of frozen instances. Empty by default.

=item B<--critical-frozen>

Critical threshold for the number of frozen instances. Empty by default.

=item B<--warning-error>

Warning threshold for the number of instances in error. Empty by default.

=item B<--critical-error>

Critical threshold for the number of instances in error. Empty by default.

=back

=cut
