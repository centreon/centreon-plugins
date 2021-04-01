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

package apps::mulesoft::restapi::mode::applications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('Id: %s, Status: %s', $self->{result_values}->{id}, $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'applications', type => 1, cb_prefix_output => 'prefix_application_output', message_multiple => 'All applications are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'mulesoft.applications.total.count', set => {
                key_values      => [ { name => 'total' }  ],
                output_template => "Total : %s",
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'started', nlabel => 'mulesoft.applications.status.started.count', set => {
                key_values      => [ { name => 'started' }  ],
                output_template => "Started : %s",
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'stopped', nlabel => 'mulesoft.applications.status.stopped.count', set => {
                key_values      => [ { name => 'stopped' }  ],
                output_template => "Stopped : %s",
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'failed', nlabel => 'mulesoft.applications.status.failed.count', set => {
                key_values      => [ { name => 'failed' }  ],
                output_template => "Failed : %s",
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }
   ];

    $self->{maps_counters}->{applications} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'id' }, { name => 'status' }, { name => 'name'}, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total applications ";
}

sub prefix_application_output {
    my ($self, %options) = @_;

    return "Application '" . $options{instance_value}->{name} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { started => 0, stopped => 0, failed => 0 };
    $self->{applications} = {};
    my $result = $options{custom}->list_objects(api_type => 'arm', endpoint => '/applications');
    foreach ('started', 'stopped', 'failed') { $self->{global}->{$_} = 0; };

    foreach my $application (@{$result}) {
        next if ( defined($self->{option_results}->{filter_name})
            && $self->{option_results}->{filter_name} ne ''
            && $application->{name} !~ /$self->{option_results}->{filter_name}/ );
        $self->{applications}->{$application} = {
            display     => $application,
            id          => $application->{id},
            name        => $application->{name},
            status      => $application->{lastReportedStatus},
        };

        $self->{global}->{started}++ if $application->{lastReportedStatus} =~ m/STARTED/;
        $self->{global}->{stopped}++ if $application->{lastReportedStatus} =~ m/STOPPED/;
        $self->{global}->{failed}++ if $application->{lastReportedStatus} =~ m/FAILED/;
    }

    if (scalar(keys %{$self->{applications}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No application found.");
        $self->{output}->option_exit();
    }

    $self->{global}->{total} = scalar (keys %{$self->{applications}});
}

1;

__END__

=head1 MODE

Check Mulesoft Anypoint Applications status.

Example:
perl centreon_plugins.pl --plugin=apps::mulesoft::restapi::plugin --mode=applications
--environment-id='1234abc-56de-78fg-90hi-1234abcdefg' --organization-id='1234abcd-56ef-78fg-90hi-1234abcdefg'
--api-username='myapiuser' --api-password='myapipassword' --verbose

More information on'https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/'.

=over 8

=item B<--filter-name>

Filter by application name (Regexp can be used).
Example: --filter-name='^application1$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Threshold can be matched on %{name}, %{id} or %{status} and Regexp can be used.
Typical syntax: --warning-status='%{status} ne "STARTED"'

=item B<--critical-status>

Set warning threshold for status (Default: '').
Threshold can be matched on %{name}, %{id} or %{status} and Regexp can be used.
Typical syntax: --critical-status='%{status} ~= m/FAILED/'

=back

=cut
