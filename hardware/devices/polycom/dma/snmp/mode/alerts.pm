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

package hardware::devices::polycom::dma::snmp::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "alarm [code: %s] [severity: %s] [description: %s] %s", $self->{result_values}->{code},
        $self->{result_values}->{severity}, $self->{result_values}->{description}, $self->{result_values}->{timestamp}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{code} = $options{new_datas}->{$self->{instance} . '_alActAlertCode'};
    $self->{result_values}->{severity} = $options{new_datas}->{$self->{instance} . '_alActAlertSeverity'};
    $self->{result_values}->{description} = $options{new_datas}->{$self->{instance} . '_alActAlertDescription'};
    $self->{result_values}->{timestamp} = $options{new_datas}->{$self->{instance} . '_alActAlertTimestamp'};
    $self->{result_values}->{since} = $options{new_datas}->{$self->{instance} . '_since'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alerts', type => 2, message_multiple => 'No problem detected', display_counter_problem => { label => 'dma.alerts.total.count', min => 0 },
          group => [ { name => 'alert', skipped_code => { -11 => 1 } } ]
        }
    ];

    $self->{maps_counters}->{alert} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'alActAlertCode' }, { name => 'alActAlertSeverity' },
                                { name => 'since' }, { name => 'alActAlertDescription' }, { name => 'alActAlertTimestamp' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
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
        'filter-msg:s'      => { name => 'filter_msg' },
        'warning-status:s'  => { name => 'warning_status', default => '%{severity} =~ /warn/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{severity} =~ /severe/i' },
        'memory'            => { name => 'memory' }
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );

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

my %map_severity = (0 => 'warn', 1 => 'severe', 2 => 'critical');

my $mapping = {
    alActAlertTimestamp   => { oid => '.1.3.6.1.4.1.13885.13.2.4.1.2.1.3' },
    alActAlertCode        => { oid => '.1.3.6.1.4.1.23916.3.1.4.1.4' },
    alActAlertSeverity    => { oid => '.1.3.6.1.4.1.23916.3.1.4.1.6' },
    alActAlertDescription => { oid => '.1.3.6.1.4.1.23916.3.1.4.1.13', map => \%map_severity }
};

my $oid_alActiveAlertsEntry = '.1.3.6.1.4.1.13885.13.2.4.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alerts}->{global} = { alarm => {} };

    my $alert_result = $options{snmp}->get_table(
        oid => $oid_alActiveAlertsEntry,
        nothing_quit => 0
    );

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_polycom_dma_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    foreach my $oid (keys %{$alert_result}) {
        next if ($oid !~ /^$mapping->{alActAlertSeverity}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $alert_result, instance => $instance);

        my $create_time = Date::Parse::str2time($result->{msgGenerationTime});
        if (!defined($create_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "Can't Parse date '" . $result->{msgGenerationTime} . "'"
            );
            next;
        }

        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);
        if (defined($self->{option_results}->{filter_msg}) && $self->{option_results}->{filter_msg} ne '' &&
            $result->{filter_severity} !~ /$self->{option_results}->{filter_msg}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $result->{filter_severity} . "': no matching filter.", debug => 1);
                next;
        }
        if (defined($self->{option_results}->{filter_severity}) && $self->{option_results}->{filter_severity} ne '' &&
            $result->{alActAlertSeverity} !~ /$self->{option_results}->{filter_severity}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $result->{alActAlertSeverity} . "': no matching filter.", debug => 1);
                next;
        }

        my $diff_time = $current_time - $create_time;

        $self->{alerts}->{global}->{alert}->{$i} = { %$result, since => $diff_time };
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

=item B<--filter-msg>

Filter by message (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /warn/i')
Can use special variables like: %{severity}, %{text}, %{code}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /severe/i').
Can use special variables like: %{severity}, %{text}, %{source}, %{since}

=item B<--memory>

Only check new alarms.

=back

=cut
