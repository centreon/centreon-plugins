#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package cloud::azure::management::monitor::mode::alert;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "alert severity: '%s', Count: '%d'",
        $self->{result_values}->{severity},
        $self->{result_values}->{count}
    );
}

sub custom_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'alerts.' . lc($self->{result_values}->{severity}) . '.count',
        value => $self->{result_values}->{count},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'alert', type => 1, message_multiple => 'All alerts are ok' },
    ];

    $self->{maps_counters}->{alert} = [
        { label => 'count', set => {
                key_values => [ { name => 'severity' }, { name => 'count' } ],
                closure_custom_output => $self->can('custom_output'),
                threshold_use => 'count',
                closure_custom_perfdata => $self->can('custom_perfdata'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'resource:s'       => { name => 'resource' },
        'resource-group:s' => { name => 'resource_group', default => '' },
        'group-by:s'       => { name => 'group_by', default => 'severity' },
        'time-range:s'     => { name => 'time_range', default => '1h' },
        'filter:s'         => { name => 'filter', default => '.*' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{api_version} = '2018-05-05';
    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify either --resource <name> with --resource-group option or --resource <id>.");
        $self->{output}->option_exit();
    }

    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));
    $self->{az_group_by} = $self->{option_results}->{group_by}  if ($self->{option_results}->{group_by} =~ /^(alertRule|alertState|monitorCondition|monitorService|severity|signalType)$/i);
    $self->{az_time_range} = $self->{option_results}->{time_range} if ($self->{option_results}->{time_range} =~ /^(1d|1h|30d|7d)$/);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $resource_group = $self->{az_resource_group};
    my $resource_name = $self->{az_resource};
    my $time_range = $self->{az_time_range};
    my $group_by = $self->{az_group_by};

    if ($self->{az_resource} =~ /^\/subscriptions\/.*\/providers\/Microsoft\.AlertsManagement\/alertsSummary\?api-version=.*&groupby=(.*)\&targetResourceGroup=(.*)\&targetResourceName=(.*)\&timeRange=(.*)$/i) {
        $group_by = $1;
        $resource_group = $2;
        $resource_name = $3;
        $time_range = $4;
    }

    my $status = $options{custom}->azure_get_resource_alert(
        group_by => $group_by,
        resource => $resource_name,
        resource_group => $resource_group,
        time_range => $time_range,
    );

    foreach my $values (@{$status->{properties}->{values}}) {
        next if ($values->{name} !~ /$self->{option_results}->{filter}/); 
        $self->{alert}->{$values->{name}} = {
            severity => $values->{name},
            count => $values->{count}
        };
    }
}

1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--filter>

Filter on alert name Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'count'.

=back

=cut
