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

package apps::backup::commvault::commserve::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'alert [severity: %s] [status: %s] [name: %s] [type: %s] %s',
        $self->{result_values}->{severity},
        $self->{result_values}->{status},
        $self->{result_values}->{name},
        $self->{result_values}->{type},
        $self->{result_values}->{generation_time}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Alerts ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'alarms', type => 2, message_multiple => '0 alert(s) detected', display_counter_problem => { nlabel => 'alerts.problems.current.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alerts-total', nlabel => 'alerts.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    foreach (('critical', 'warning', 'info')) {
        push @{$self->{maps_counters}->{global}},
            { label => 'alerts-' . $_, nlabel => 'alerts.' . $_ . '.count', display_ok => 0, set => {
                    key_values => [ { name => $_ }, { name => 'total' } ],
                    output_template => $_ . ': %s',
                    perfdatas => [
                        { template => '%s', min => 0, max => 'total' }
                    ]
                }
            };
    }

    $self->{maps_counters}->{alarm} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{severity} =~ /warning/',
            critical_default => '%{severity} =~ /critical/',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'type' },
                    { name => 'severity' }, { name => 'status' },
                    { name => 'since' }, { name => 'generation_time' }
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
        'filter-alert-name:s' => { name => 'filter_alert_name' },
        'filter-alert-type:s' => { name => 'filter_alert_type' },
        'memory'              => { name => 'memory' }
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

my $map_severity = {
    0 => 'autoPick', 1 => 'critical',
    2 => 'warning', 3 => 'info'
};
my $map_status = {
    4 => 'read', 8 => 'unread'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $alarms = $options{custom}->request_paging(
        type => 'alert',
        endpoint => '/Alert'
    );

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(
            statefile => 'commvault_commserve_' . $options{custom}->get_connection_infos() . '_' . $self->{mode} . '_' .
                (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
                (defined($self->{option_results}->{filter_alert_name}) ? md5_hex($self->{option_results}->{filter_alert_name}) : md5_hex('all')) . '_' .
                (defined($self->{option_results}->{filter_alert_type}) ? md5_hex($self->{option_results}->{filter_alert_type}) : md5_hex('all'))
        );
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    $self->{global} = { total => 0, critical => 0, warning => 0, info => 0 };
    $self->{alarms} = { global => { alarm => {} } };
    my ($i, $current_time) = (1, time());
    foreach my $alarm (@$alarms) {
        my $create_time = $alarm->{detectedTime}->{time};
        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);

        if (defined($self->{option_results}->{filter_alert_name}) && $self->{option_results}->{filter_alert_name} ne '' &&
            $alarm->{alertName} !~ /$self->{option_results}->{filter_alert_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alarm->{alertName} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_alert_type}) && $self->{option_results}->{filter_alert_type} ne '' &&
            $alarm->{alertType} !~ /$self->{option_results}->{filter_alert_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alarm->{alertName} . "': no matching filter.", debug => 1);
            next;
        }

        my $diff_time = $current_time - $create_time;
        $self->{alarms}->{global}->{alarm}->{$i} = {
            name => $alarm->{alertName},
            type => $alarm->{alertType},
            severity => $map_severity->{ $alarm->{severity} },
            status => $map_status->{ $alarm->{status} },
            since => $diff_time,
            generation_time => centreon::plugins::misc::change_seconds(value => $diff_time)
        };
        $self->{global}->{total}++;
        $self->{global}->{ $map_severity->{ $alarm->{severity} } }++
            if (defined($self->{global}->{ $map_severity->{ $alarm->{severity} } }));
        $i++;
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}
        
1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--filter-alert-name>

Filter alerts by name (can be a regexp).

=item B<--filter-alert-type>

Filter alerts by type (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /warning/')
Can used special variables like: %{severity}, %{status}, %{type}, %{name}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /critical/').
Can used special variables like: %{severity}, %{status}, %{type}, %{name}, %{since}

=item B<--memory>

Only check new alerts.

=back

=cut
