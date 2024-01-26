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

package apps::monitoring::ntopng::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_type_perfdata {
    my ($self, %options) = @_;

    my $instances = [ $self->{result_values}->{name} ];
    if (defined($self->{result_values}->{type})) {
        push @$instances, $self->{result_values}->{type};
    }

    $self->{output}->perfdata_add(
        nlabel => 'alerts.type.detected.count',
        instances => [ $self->{result_values}->{type} ],
        value => $self->{result_values}->{value},
        min => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "alert [severity: %s] [type: %s] %s",
        $self->{result_values}->{severity},
        $self->{result_values}->{type},
        scalar(localtime($self->{result_values}->{timeraised}))
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
        { 
            name => 'alarms', type => 2, message_multiple => '0 alerts detected', format_output => '%s alerts detected', display_counter_problem => { nlabel => 'alerts.detected.count', min => 0 },
            group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        },
        { name => 'alarm_types', type => 1 }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('info', 'warning', 'error') {
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
            warning_default => '%{severity} =~ /warning/i',
            critical_default => '%{severity} =~ /error/i',
            set => {
                key_values => [
                    { name => 'timeraised' }, { name => 'type' }, { name => 'severity' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{alarm_types} = [
        { label => 'type', threshold => 0, display_ok => 0, set => {
                key_values => [ { name => 'value' }, { name => 'type' } ],
                output_template => '',
                closure_custom_threshold_check => sub { return 'ok'; },
                closure_custom_perfdata => $self->can('custom_type_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-type:s'     => { name => 'filter_type' },
        'filter-severity:s' => { name => 'filter_severity' },
        'interface:s'       => { name => 'interface', default => 0 },
        'period:s'          => { name => 'period', default => 'last-5mns' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ( $self->{option_results}->{period} eq 'last-5mns') {
        $self->{option_results}->{epochend} = time();
        $self->{option_results}->{epochbegin} = time() - 300;
    } elsif ($self->{option_results}->{period} eq 'last-hour') {
        $self->{option_results}->{epochend} = time();
        $self->{option_results}->{epochbegin} = time() - 3600;
    } else {
        $self->{output}->add_option_msg(short_msg => "Period " . $self->{option_results}->{period} . " not known !");
        $self->{output}->option_exit();
    }
}

my $map_severity = {
    3 => 'info', 4 => 'warning', 5 => 'error'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(
        endpoint => "/lua/rest/v2/get/flow/alert/list.lua",
        get_param => ['ifid=' . $self->{option_results}->{interface}, 'epoch_begin=' . $self->{option_results}->{epochbegin} , 'epoch_end=' . $self->{option_results}->{epochend}]
    );

    $self->{global} = { info => 0, warning => 0, error => 0 };
    $self->{alarms}->{global} = { alarm => {} };
    $self->{alarm_types} = {};
    for my $entry (@{$results->{rsp}->{records}}) {
        my $severity = $map_severity->{ $entry->{severity}->{value} };

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $entry->{msg}->{name} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $entry->{msg}->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_severity}) && $self->{option_results}->{filter_severity} ne '' &&
            $severity !~ /$self->{option_results}->{filter_severity}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $entry->{msg}->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{$severity}++;
        $self->{alarms}->{global}->{alarm}->{ $entry->{row_id} } = {
            type => $entry->{msg}->{name},
            severity => $severity,
            timeraised => $entry->{tstamp}->{value}
        };
        if (!defined($self->{alarm_types}->{ $entry->{msg}->{name} })) {
            $self->{alarm_types}->{ $entry->{msg}->{name} } = { type => $entry->{msg}->{name}, value => 0 };
        }
        $self->{alarm_types}->{ $entry->{msg}->{name} }->{value}++;
    }
}
        
1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--filter-type>

Filter alerts by type (can be a regexp).

=item B<--filter-severity>

Only get alerts by severity (can be a regexp).

=item B<--interface>

Interface name to check (0 by default)

=item B<--period>

Set period to check new alarms.
Can be: 'last-5mns' (default), 'last-hour'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{severity} =~ /minor/i')
You can use the following variables: %{severity}, %{type}, %{timeraised}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{severity} =~ /major|critical/i').
You can use the following variables: %{severity}, %{type}, %{timeraised}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'severity-info', 'severity-warning', 'severity-error'.

=back

=cut
