#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package storage::dell::powerstore::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "alert [severity: %s] [name: %s] [resource: %s] %s",
        $self->{result_values}->{severity},
        $self->{result_values}->{name},
        $self->{result_values}->{resource},
        $self->{result_values}->{timeraised}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Alerts severity ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'alarms', type => 2, message_multiple => '0 alerts detected', format_output => '%s alerts detected', display_counter_problem => { nlabel => 'alerts.problems.current.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('none', 'info', 'minor', 'major', 'critical') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'severity-' . $_, nlabel => 'alerts.severity.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{alarm} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{severity} =~ /minor/i',
            critical_default => '%{severity} =~ /major|critical/i',
            set => {
                key_values => [
                    { name => 'resource' }, { name => 'name' },
                    { name => 'severity' }, { name => 'timeraised' },
                    { name => 'acknowledged' } 
                ],
                closure_custom_output => $self->can('custom_status_output'),
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
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'memory'        => { name => 'memory' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        'none' => 0, 'info' => 0, 'minor' => 0, 'major' => 0, 'critical' => 0
    };
    $self->{alarms}->{global} = { alarm => {} };
    my $results = $options{custom}->request_api(
        endpoint => '/api/rest/alert',
        get_param => ['select=*']
    );

    my $alerts_mem;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'dell_powerstore_' . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port(). '_' . $self->{mode});
        $alerts_mem = $self->{statefile_cache}->get(name => 'alerts');
    }

    foreach my $entry (@$results) {
        next if ($entry->{state} eq 'CLEARED');

        if (defined($self->{option_results}->{memory})) {
            if (defined($alerts_mem) && defined($alerts_mem->{ $entry->{id} })) {
                next;
            }
            $alerts_mem->{ $entry->{id} } = 1;
        }

        my $name = '-';
        if (defined($entry->{name})) {
            $name = $entry->{name};
        } elsif (defined($entry->{events}->[0]->{name})) {
            $name = $entry->{events}->[0]->{name};
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{ lc($entry->{severity}) }++;
        $self->{alarms}->{global}->{alarm}->{ $entry->{id} } = {
            resource => $entry->{resource_name},
            name => $name,
            severity => lc($entry->{severity}),
            timeraised => $entry->{generated_timestamp},
            acknowledged => ($entry->{is_acknowledged} =~ /True|1/i) ? 'yes' : 'no'
        };
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { alerts => $alerts_mem });
    }
}
        
1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--filter-name>

Filter alerts by name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{severity} =~ /minor/i')
You can use the following variables: %{severity}, %{resource}, %{name}, %{timeraised}, %{acknowledged}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{severity} =~ /major|critical/i').
You can use the following variables: %{severity}, %{resource}, %{name}, %{timeraised}, %{acknowledged}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'severity-none', 'severity-info', 'severity-minor', 'severity-major', 'severity-critical'.

=item B<--memory>

Only check new alarms.

=back

=cut
