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

package apps::java::camel::jmx::mode::routes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_exchange_perfdata {
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

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [statistics enabled: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{statisticsEnabled}
    );
}

sub route_long_output {
    my ($self, %options) = @_;

    return "checking route '" . $options{instance} . "'";
}

sub prefix_route_output {
    my ($self, %options) = @_;

    return "Route '" . $options{instance} . "' ";
}

sub prefix_exchange_output {
    my ($self, %options) = @_;

    return "number of exchanges ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'routes', type => 3, cb_prefix_output => 'prefix_route_output', cb_long_output => 'route_long_output', indent_long_output => '    ', message_multiple => 'All routes are ok',
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'exchanges', type => 0, cb_prefix_output => 'prefix_exchange_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, warning_default => '%{statisticsEnabled} eq "no" || %{state} =~ /suspend/i', set => {
                key_values => [ { name => 'state' }, { name => 'statisticsEnabled' }, { name => 'name' }, { name => 'context' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{exchanges} = [
        { label => 'exchanges-completed', nlabel => 'route.exchanges.completed.count', set => {
                key_values => [ { name => 'completed', diff => 1 }, { name => 'name' }, { name => 'context' } ],
                output_template => 'completed: %s',
                closure_custom_perfdata => $self->can('custom_exchange_perfdata')
            }
        },
        { label => 'exchanges-failed', nlabel => 'route.exchanges.failed.count', set => {
                key_values => [ { name => 'failed', diff => 1 }, { name => 'name' }, { name => 'context' } ],
                output_template => 'failed: %s',
                closure_custom_perfdata => $self->can('custom_exchange_perfdata')
            }
        },
        { label => 'exchanges-inflight', nlabel => 'route.exchanges.inflight.count', set => {
                key_values => [ { name => 'inFlight' }, { name => 'name' }, { name => 'context' } ],
                output_template => 'inflight: %s',
                closure_custom_perfdata => $self->can('custom_exchange_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'               => { name => 'filter_name' },
        'filter-context:s'            => { name => 'filter_context' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(name)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { name => 1, context => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        {
            mbean => 'org.apache.camel:context=*,name=*,type=routes',
            attributes => [
                { name => 'StatisticsEnabled' }, { name => 'State' }, 
                { name => 'ExchangesInflight' }, { name => 'ExchangesFailed' },
                { name => 'ExchangesCompleted' }
            ]
        }
    ];

    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{cache_name} = 'apache_camel_' . $self->{mode} . '_' . 
        md5_hex(
            $options{custom}->get_connection_info() . '_' .
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{filter_context}) ? $self->{option_results}->{filter_context} : '')
        );

    $self->{routes} = {};
    foreach my $mbean (keys %$result) {
        my ($name, $context);

        $name = $1 if ($mbean =~ /name=(.*?)(?:,|$)/);
        $context = $1 if ($mbean =~ /context=(.*?)(?:,|$)/);
        $name =~ s/^"(.*)"$/$1/;
        $name =~ s/<.*?>//g;
        $context =~ s/^"(.*)"$/$1/;
        $content =~ s/<.*?>//g;

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_context}) && $self->{option_results}->{filter_context} ne '' &&
            $context !~ /$self->{option_results}->{filter_context}/);

        $self->{routes}->{$name} = {
            global => {
                context => $context,
                name => $name,
                state => $result->{$mbean}->{'State'},
                statisticsEnabled => $result->{$mbean}->{'StatisticsEnabled'} =~ /true|1/i ? 'yes' : 'no'
            },
            exchanges => {
                context => $context,
                name => $name,
                inFlight => $result->{$mbean}->{'ExchangesInflight'},
                failed => $result->{$mbean}->{'ExchangesFailed'},
                completed => $result->{$mbean}->{'ExchangesCompleted'}
            }
        };
    }

    if (scalar(keys %{$self->{routes}}) <= 0) {
        $self->{output}->output_add(short_msg => 'no routes found');
    }
}

1;

__END__

=head1 MODE

Check routes.

=over 8

=item B<--filter-name>

Filter routes by name (can be a regexp).

=item B<--filter-context>

Filter routes by context (can be a regexp).

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(name)')

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{statisticsEnabled}, %{name}, %{context}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{statisticsEnabled} eq "no" || %{state} =~ /suspend/i').
You can use the following variables: %{state}, %{statisticsEnabled}, %{name}, %{context}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{statisticsEnabled}, %{name}, %{context}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 
'exchanges-completed', 'exchanges-failed', 'exchanges-inflight'.

=back

=cut
