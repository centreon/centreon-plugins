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

package apps::monitoring::scom::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("alert [severity: %s] [host: %s] [name: %s] %s", $self->{result_values}->{severity},
        $self->{result_values}->{host}, $self->{result_values}->{name}, $self->{result_values}->{timeraised});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'alarms', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { nlabel => 'alerts.problems.current.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('new', 'closed', 'resolved', 'scheduled', 'awaiting_evidence', 'assigned_to_engineering', 'acknowledge') {
        my $label = $_;
        $label =~ s/_/-/g;
        push @{$self->{maps_counters}->{global}}, {
            label => $label, nlabel => 'alerts.resolution.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { value => $_ , template => '%s', min => 0 },
                ],
            }
        };
    }

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'host' }, { name => 'name' },
                    { name => 'severity' }, { name => 'timeraised' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Resolution state ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-host:s'       => { name => 'filter_host' },
        'warning-status:s'    => { name => 'warning_status', default => '%{severity} =~ /warning/i' },
        'critical-status:s'   => { name => 'critical_status', default => '%{severity} =~ /critical/i' },
        'memory'              => { name => 'memory' },
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        'new' => 0, 'closed' => 0, 'resolved' => 0, 'scheduled' => 0, 'awaiting_evidence' => 0, 'assigned_to_engineering' => 0, 'acknowledge' => 0,
    };
    $self->{alarms}->{global} = { alarm => {} };
    my $results = $options{custom}->get_alerts();

    my $alerts_mem;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_scom_" . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port(). '_' . $self->{mode});
        $alerts_mem = $self->{statefile_cache}->get(name => 'alerts');
    }

    foreach my $alert_id (keys %$results) {
        if (defined($self->{option_results}->{memory})) {
            if (defined($alerts_mem) && defined($alerts_mem->{$alert_id})) {
                $alerts_mem->{$alert_id} = 1;
                next;
            }
            $alerts_mem->{$alert_id} = 1;
        }

        if (defined($self->{option_results}->{filter_host}) && $self->{option_results}->{filter_host} ne '' &&
            $results->{$alert_id}->{monitoringobjectdisplayname} !~ /$self->{option_results}->{filter_host}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $results->{$alert_id}->{monitoringobjectdisplayname} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{$results->{$alert_id}->{resolutionstate}}++;
        $self->{alarms}->{global}->{alarm}->{$alert_id} = { %{$results->{$alert_id}} };
    }

    if (defined($alerts_mem)) {
        foreach (keys %$alerts_mem) {
            if (!defined($results->{$_})) {
                delete $alerts_mem->{$_};
            }
        }
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

=item B<--filter-host>

Filter by host name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /warning/i')
Can used special variables like: %{severity}, %{host}, %{name}, %{timeraised}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /critical/i').
Can used special variables like: %{severity}, %{host}, %{name}, %{timeraised}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'new', 'closed', 'resolved', 'scheduled', 'awaiting-evidence', 'assigned-to-engineering', 'acknowledge'.

=item B<--memory>

Only check new alarms.

=back

=cut
