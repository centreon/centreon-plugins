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

package network::paloalto::snmp::mode::loggingstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);



sub prefix_log_output {
    my ($self, %options) = @_;

    return "Logging '" . $options{instance_value}->{device} . "/". $options{instance_value}->{log_type}. " ";
}


sub custom_last_log_forwarded_created_seconds_perfdata {
    my ($self, %options) = @_;

    if(defined $self->{result_values}->{diff}) {
        $self->{output}->perfdata_add(
            nlabel => $self->{instance}."#".$self->{nlabel},
            value => $self->{result_values}->{diff},
            unit => 's',
            min => 0
        );
    }
}

sub custom_last_log_forwarded_created_seconds_threshold {
    my ($self, %options) = @_;

    if(defined $self->{result_values}->{diff}) {
        my $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{diff},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
            ]
        );
        return $exit;
    } else {
        return 'critical';
    }
}

sub custom_last_forwarded_output {
    my ($self, %options) = @_;

    if(defined  $self->{result_values}->{diff}) {
        return sprintf(
                    'Last log forwarded: %s [%s]',
                    centreon::plugins::misc::change_seconds(value => $self->{result_values}->{diff}), $self->{result_values}->{date_time_str}
        );
    } else {
        return sprintf('Last log forwarded: Not Available');
    }
}

sub custom_last_created_output {
    my ($self, %options) = @_;

    if(defined $self->{result_values}->{diff}) {
        return sprintf(
                    'Last log created: %s [%s]',
                    centreon::plugins::misc::change_seconds(value => $self->{result_values}->{diff}), $self->{result_values}->{date_time_str}
        );
    } else {
        return sprintf('Last log created: Not Available');
    }
}

sub custom_last_log_forwarded_created_seconds_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label};

    my $time = $options{new_datas}->{$self->{instance}."_".$self->{result_values}->{label}};
    #2025/09/30 08:16:08
    if ($time =~ /^\s*(\d+)\/(\d+)\/(\d+)\s(\d+):(\d+):(\d+)/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            %{$self->{instance_mode}->{tz}}
        );
        $self->{result_values}->{diff} = time() - $dt->epoch;
        $self->{result_values}->{date_time_str} = $dt->strftime('%Y-%m-%d %H:%M:%S %Z');

    }

    return 0;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'log_stats', type => 1, cb_prefix_output => 'prefix_log_output', message_separator => ' ', message_multiple => 'All device logging stats are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{log_stats} = [
        { label => 'last-log-created', nlabel => 'logging.last.log.created.seconds', set => {
                key_values => [ { name => 'last_log_created' } ],
                closure_custom_output => $self->can('custom_last_created_output'),
                closure_custom_calc => $self->can('custom_last_log_forwarded_created_seconds_calc'),
                closure_custom_calc_extra_options => { label => 'last_log_created' },
                closure_custom_threshold_check => $self->can('custom_last_log_forwarded_created_seconds_threshold'),
                closure_custom_perfdata => $self->can('custom_last_log_forwarded_created_seconds_perfdata')
            }
        },
        { label => 'last-log-fwded', nlabel => 'logging.last.log.fwded.seconds', set => {
                key_values => [ { name => 'last_log_fwded' } ],
                closure_custom_calc => $self->can('custom_last_log_forwarded_created_seconds_calc'),
                closure_custom_calc_extra_options => { label => 'last_log_fwded' },
                closure_custom_output => $self->can('custom_last_forwarded_output'),
                closure_custom_threshold_check => $self->can('custom_last_log_forwarded_created_seconds_threshold'),
                closure_custom_perfdata => $self->can('custom_last_log_forwarded_created_seconds_perfdata')
            }
        },
        { label => 'total-logs-fwded', nlabel => 'logging.total.logs.fwded.count', set => {
                key_values => [ { name => 'total_logs_fwded' } ],
                output_template => 'Total logs forwarded: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{tz} = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timezone:s'     => { name => 'timezone', default => 'GMT'},
        'filter-device:s' => { name => 'filter_device' },
        'filter-log-type:s'  => { name => 'filter_log_type' }
    });

    return $self;
}

my $mapping = {
    device             => { oid => '.1.3.6.1.4.1.25461.2.1.2.7.2.1.1' }, # panDeviceLoggingDevice
    device_index       => { oid => '.1.3.6.1.4.1.25461.2.1.2.7.2.1.2' }, # panDeviceLoggingDeviceIndex
    log_type           => { oid => '.1.3.6.1.4.1.25461.2.1.2.7.2.1.3' }, # panDeviceLoggingLogType
    last_log_created   => { oid => '.1.3.6.1.4.1.25461.2.1.2.7.2.1.4' }, # panDeviceLoggingLogLastLogCreated
    last_log_fwded     => { oid => '.1.3.6.1.4.1.25461.2.1.2.7.2.1.5' }, # panDeviceLoggingLogLastLogFwded
    total_logs_fwded   => { oid => '.1.3.6.1.4.1.25461.2.1.2.7.2.1.8' }  # panDeviceLoggingLogTotalLogsFwded
};

my $oid_log_table = '.1.3.6.1.4.1.25461.2.1.2.7.2'; # panDeviceLoggingLogTypeStatTable

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_log_table,
        nothing_quit => 1
    );

    $self->{log_stats} = {};

    foreach my $oid (keys %$snmp_result) {
        if ($oid =~ /^\Q$mapping->{device}->{oid}\E\.(.*)$/) {
            my $raw_instance = $1;

            my $result = $options{snmp}->map_instance(
                mapping  => $mapping,
                results  => $snmp_result,
                instance => $raw_instance
            );

            my $device = $result->{device};
            my $log_type = $result->{log_type};

            if (defined($self->{option_results}->{filter_device}) && $self->{option_results}->{filter_device} ne '' &&
                $device !~ /$self->{option_results}->{filter_device}/) {
                $self->{output}->output_add(long_msg => "skipping device '" . $device . "': no matching filter.", debug => 1);
                next;
            }

            if (defined($self->{option_results}->{filter_log_type}) && $self->{option_results}->{filter_log_type} ne '' &&
                $log_type !~ /$self->{option_results}->{filter_log_type}/) {
                $self->{output}->output_add(long_msg => "skipping log_type '" . $log_type . "': no matching filter.", debug => 1);
                next;
            }

            my $instance_name = $device . '/' . $log_type;

            $self->{log_stats}->{$instance_name} = {
                instance => $instance_name,
                %$result
            };

        }
    }

    if (scalar(keys %{$self->{log_stats}}) <= 0 ) {
        $self->{output}->add_option_msg(short_msg => "No result matched with applied filters.");
        $self->{output}->option_exit();
    }

}



1;

__END__

=head1 MODE

Check logging status.

=over 8

=item B<--warning-*>

Warning threshold.
Can be: 'last-log-created', 'last-log-fwded', 'total-logs-fwded'.

=item B<--critical-*>

Critical threshold.
Can be: 'last-log-created', 'last-log-fwded', 'total-logs-fwded'.

=item B<--timezone>

Timezone options. Default is 'GMT'.

=item B<--filter-log-type>

Filter log type (can be a regexp).

=item B<--filter-device>

Filter device (can be a regexp).

=back

=cut