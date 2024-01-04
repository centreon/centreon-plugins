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

package network::aruba::orchestrator::restapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "alarm [severity: %s] [name: %s] [hostname: %s] %s",
        $self->{result_values}->{severity},
        $self->{result_values}->{name},
        $self->{result_values}->{hostname},
        $self->{result_values}->{timeraised}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Alarms severity ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'alarms', type => 2, message_multiple => '0 alarm detected', format_output => '%s alarms detected', display_counter_problem => { nlabel => 'alerms.problems.current.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('minor', 'warning', 'major', 'critical') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'severity-' . $_, nlabel => 'alarms.severity.' . $_ . '.count', display_ok => 0, set => {
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
            warning_default => '%{severity} =~ /minor|warning/i',
            critical_default => '%{severity} =~ /major|critical/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'hostname' },
                    { name => 'severity' }, { name => 'timeraised' }
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
        'filter-hostname:s' => { name => 'filter_hostname' },
        'timezone:s'        => { name => 'timezone' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        minor => 0, warning => 0, major => 0, critical => 0
    };
    $self->{alarms}->{global} = { alarm => {} };

    my $appliances = $options{custom}->request_api(endpoint => '/appliance');
    my $post = { ids => [] };

    foreach my $appliance (@$appliances) {
        next if (defined($self->{option_results}->{filter_hostname}) && $self->{option_results}->{filter_hostname} ne '' &&
            $appliance->{hostName} !~ /$self->{option_results}->{filter_hostname}/);

        push @{$post->{ids}}, $appliance->{id};
    }

    if (scalar(@{$post->{ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'no appliances selected');
        $self->{output}->option_exit();
    }

    my $results = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/alarm/appliance',
        get_param => ['view=active'],
        query_form_post => $post
    );

    foreach my $entry (@$results) {
        my $dt = DateTime->from_epoch(epoch => $entry->{timeOccurredInMills} / 1000, time_zone => $self->{option_results}->{timezone});
        my $timeraised = sprintf(
            '%02d-%02d-%02dT%02d:%02d:%02d (%s)', $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second, $self->{option_results}->{timezone}
        );

        $self->{global}->{ lc($entry->{severity}) }++;
        $self->{alarms}->{global}->{alarm}->{ $entry->{id} } = {
            hostname => $entry->{hostName},
            name => $entry->{name},
            severity => lc($entry->{severity}),
            timeraised => $timeraised
        };
    }
}
        
1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--filter-hostname>

Filter alarms by hostname (can be a regexp).

=item B<--timezone>

Set timezone for creation time (default is 'UTC').

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{severity} =~ /minor|warning/i')
You can use the following variables: %{severity}, %{hostname}, %{name}, %{timeraised}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{severity} =~ /major|critical/i').
You can use the following variables: %{severity}, %{hostname}, %{name}, %{timeraised}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'severity-minor', 'severity-warning', 'severity-major', 'severity-critical'.

=back

=cut
