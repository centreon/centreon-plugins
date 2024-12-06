#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package network::nokia::timos::snmp::mode::sasalarm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub prefix_output {
    my ($self, %options) = @_;

    return "Alarm input '" . $options{instance_value}->{display} . "' ";
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'Alarm input status : ' . $self->{result_values}->{alarm_input_status}
        . ' (Alarm input admin state: ' . $self->{result_values}->{alarm_input_admin_state}
        . ' (Alarm output severity: ' . $self->{result_values}->{alarm_output_severity}
        . ')';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{alarm_output_severity} = $options{new_datas}->{$self->{instance} . '_alarm_output_severity'};
    $self->{result_values}->{alarm_input_status} = $options{new_datas}->{$self->{instance} . '_alarm_input_status'};
    $self->{result_values}->{alarm_input_admin_state} = $options{new_datas}->{$self->{instance} . '_alarm_input_admin_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'sas_alarm_input',
            type             => 1,
            cb_prefix_output => 'prefix_output',
            message_multiple => 'All sas alarm inputs are ok'
        }
    ];

    $self->{maps_counters}->{sas_alarm_input} = [
        { label => 'status', threshold => 0, set => {
            key_values                     =>
                [
                    { name => 'alarm_output_severity' },
                    { name => 'alarm_input_status' },
                    { name => 'alarm_input_admin_state' },
                    { name => 'display' }
                ],
            closure_custom_calc            =>
                $self->can('custom_status_calc'),
            closure_custom_output          =>
                $self->can('custom_status_output'),
            closure_custom_perfdata        =>
                sub {return 0;},
            closure_custom_threshold_check =>
                \&catalog_status_threshold,
        }
        },
    ]
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            "filter-name:s"     =>
                { name => 'filter_name' },
            "warning-status:s"  =>
                { name      =>
                    'warning_status',
                    default =>
                        '%{alarm_input_admin_state} eq "up" and %{alarm_input_status} eq "alarm" and %{alarm_output_severity} =~ /minor/' },
            "critical-status:s" =>
                { name      =>
                    'critical_status',
                    default =>
                        '%{alarm_input_admin_state} eq "up" and %{alarm_input_status} eq "alarm" and %{alarm_output_severity} =~ /major|critical/' },
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [ 'warning_status', 'critical_status' ]);
}

my %alarm_output_severity = (1 => 'none', 2 => 'minor', 3 => 'major', 4 => 'critical');
my %alarm_input_status = (1 => 'noAlarm', 2 => 'alarm');
my %alarm_input_admin_state = (1 => 'up', 2 => 'down');

my $mapping = {
    tmnxSasAlarmOutputSeverity   => { oid => '.1.3.6.1.4.1.6527.6.2.2.2.9.1.1.5', map => \%alarm_output_severity },
    tmnxSasAlarmInputDescription => { oid => '.1.3.6.1.4.1.6527.6.2.2.2.9.1.1.2' },
    tmnxSasAlarmInputStatus      => { oid => '.1.3.6.1.4.1.6527.6.2.2.2.9.1.1.6', map => \%alarm_input_status },
    tmnxSasAlarmInputAdminState  => { oid => '.1.3.6.1.4.1.6527.6.2.2.2.9.1.1.3', map => \%alarm_input_admin_state },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
        { oid => $mapping->{tmnxSasAlarmInputDescription}->{oid} },
        { oid => $mapping->{tmnxSasAlarmInputStatus}->{oid} },
        { oid => $mapping->{tmnxSasAlarmInputAdminState}->{oid} },
        { oid => $mapping->{tmnxSasAlarmOutputSeverity}->{oid} }
    ],
        return_type                                           => 1,
        nothing_quit                                          => 1
    );

    $self->{sas_alarm_input} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{tmnxSasAlarmOutputSeverity}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (!defined($result->{tmnxSasAlarmInputDescription}) || $result->{tmnxSasAlarmInputDescription} eq '') {
            $result->{tmnxSasAlarmInputDescription} = "AlarmInput-Instance-$instance";
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{tmnxSasAlarmInputDescription} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg =>
                "skipping Input '" . $result->{tmnxSasAlarmInputDescription} . "'.",
                debug                            =>
                    1);
            next;
        }

        $self->{sas_alarm_input}->{$instance} = {
            display                 => $result->{tmnxSasAlarmInputDescription},
            alarm_output_severity   => $result->{tmnxSasAlarmOutputSeverity},
            alarm_input_status      => $result->{tmnxSasAlarmInputStatus},
            alarm_input_admin_state => $result->{tmnxSasAlarmInputAdminState}
        };

        $self->{cache_name} = "nokia_timos_" . $self->{mode} . '_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' .
            (defined($self->{option_results}->{filter_counters}) ?
                md5_hex($self->{option_results}->{filter_counters}) :
                md5_hex('all')) . '_' .
            (defined($self->{option_results}->{filter_name}) ?
                md5_hex($self->{option_results}->{filter_name}) :
                md5_hex('all'));
    }
}

1;

__END__

=head1 MODE

Check SAS alarm input usage.


=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '%{alarm_input_admin_state} eq "up" and %{alarm_input_status} eq "alarm" and %{alarm_output_severity} =~ /minor/')
You can use the following variables: %{alarm_input_admin_state}, %{alarm_input_status}, %{alarm_output_severity}

=item B<--critical-status>

Set critical threshold for status (Default: '%{alarm_input_admin_state} eq "up" and %{alarm_input_status} eq "alarm" and %{alarm_output_severity} =~ /major|critical/').
You can use the following variables: %{ipv4_oper_state}, %{admin_state}, %{display}

=item B<--filter-name>

Filter alarm input (tmnxSasAlarmInputDescription) (can be a regexp).

=back

=cut
