#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::huawei::wlc::snmp::mode::apradio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Access points ';
}

sub ap_long_output {
    my ($self, %options) = @_;

    return "checking access point '" . $options{instance_value}->{display} . "'";
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "access point '" . $options{instance_value}->{display} . "' ";
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'run state: ' . $self->{result_values}->{runstate};
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name                 => 'ap',
            type               => 3,
            cb_prefix_output   => 'prefix_ap_output',
            cb_long_output     => 'ap_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All access points are ok',
            group              => [
                { name => 'ap_radio', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{ap_radio} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{runstate} ne "up"',
            set              =>
                {
                    key_values                     =>
                        [ { name => 'runstate' }, { name => 'display' } ],
                    closure_custom_output          =>
                        $self->can('custom_status_output'),
                    closure_custom_perfdata        =>
                        sub {return 0;},
                    closure_custom_threshold_check =>
                        \&catalog_status_threshold_ng
                }
        },
        { label => 'package-error-rate', nlabel => 'ap.radio.packageerror.percentage', set => {
            key_values      => [ { name => 'package_error_rate' }, { name => 'display' } ],
            output_template => 'radio package error rate: %.2f%%',
            perfdatas       => [
                { template => '%.2f', unit => '%', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'noise', nlabel => 'ap.radio.noise.dbm', set => {
            key_values      => [ { name => 'noise' }, { name => 'display' } ],
            output_template => 'radio noise: %d dBm',
            perfdatas       => [
                { template => '%d', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'channel-utilization-rate', nlabel => 'ap.radio.channel.utilization.percentage', set => {
            key_values      => [ { name => 'channel_utilization_rate' }, { name => 'display' } ],
            output_template => 'radio channel utilization rate: %.2f%%',
            perfdatas       => [
                { template => '%.2f', unit => '%', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'channel-interference-rate', nlabel => 'ap.radio.channel.interference.percentage', set => {
            key_values      => [ { name => 'channel_interference_rate' }, { name => 'display' } ],
            output_template => 'radio channel interference rate: %.2f%%',
            perfdatas       => [
                { template => '%.2f', unit => '%', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'receive-rate', nlabel => 'ap.radio.receive.bitspersecond', set => {
            key_values      => [ { name => 'receive_rate' }, { name => 'display' } ],
            output_template => 'radio channel receive rate: %d b/s',
            perfdatas       => [
                { template => '%d', unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'send-rate', nlabel => 'ap.radio.send.bitspersecond', set => {
            key_values      => [ { name => 'send_rate' }, { name => 'display' } ],
            output_template => 'radio channel send rate: %d b/s',
            perfdatas       => [
                { template => '%d', unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s"    => { name => 'filter_name' },
        "filter-address:s" => { name => 'filter_address' },
        "filter-group:s"   => { name => 'filter_group' }
    });

    return $self;
}

my $map_runstate = {
    1   => 'up',
    2   => 'down',
    255 => 'invalid'
};

my $mapping = {
    name => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.3' },# hwWlanApName
};

my $mapping_stat = {
    ap_group                  => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.55' },# hwWlanRadioApGroup
    runstate                 => {
        oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.6', map => $map_runstate
    },# hwWlanRadioRunState
    package_error_rate        => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.23' },# hwWlanRadioPER
    noise                     => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.24' },# hwWlanRadioNoise
    channel_utilization_rate  => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.25' },# hwWlanRadioChUtilizationRate
    channel_interference_rate => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.29' },# hwWlanRadioChInterferenceRate
    receive_rate              => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.32' },# hwWlanRadioRecvRate
    send_rate                 => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.37' },# hwWlanRadioSendRate
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};

    my $request = [ { oid => $mapping->{name}->{oid} } ];
    push @$request, { oid => $mapping->{ap_group}->{oid} }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '');

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => $request,
        return_type  => 1,
        nothing_quit => 1
    );

    foreach (sort keys %$snmp_result) {
        next if (!/^$mapping->{name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(long_msg =>
                "skipping WLC '$instance': cannot get a name. please set it.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{name} . "': no matching name filter.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{group} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{group} . "': no matching group filter.",
                debug                            =>
                    1);
            next;
        }

        $self->{ap}->{ $result->{name} } = {
            instance => $instance,
            display  => $result->{name},
            ap_radio => {
                display => $result->{name}
            }
        };
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no AP associated');
        return;
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping_stat)) ],
        instances       => [ map($_->{instance}, values %{$self->{ap}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (sort keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping_stat,
            results  => $snmp_result,
            instance => $self->{ap}->{$_}->{instance}
        );

        $self->{ap}->{$_}->{ap_radio}->{runstate} = $result->{runstate};
        $self->{ap}->{$_}->{ap_radio}->{package_error_rate} = $result->{package_error_rate};
        $self->{ap}->{$_}->{ap_radio}->{noise} = $result->{noise};
        $self->{ap}->{$_}->{ap_radio}->{channel_utilization_rate} = $result->{channel_utilization_rate};
        $self->{ap}->{$_}->{ap_radio}->{channel_interference_rate} = $result->{channel_interference_rate};
        $self->{ap}->{$_}->{ap_radio}->{receive_rate} = $result->{receive_rate} * 1000;
        $self->{ap}->{$_}->{ap_radio}->{send_rate} = $result->{send_rate} * 1000;
    }
}

1;

__END__

=head1 MODE

Check AP radio status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^temperature|onlinetime$'

=item B<--filter-name>

Filter access point radio name (can be a regexp)

=item B<--filter-address>

Filter access point radio IP address (can be a regexp).

=item B<--filter-group>

Filter access point group (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{runstate}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{runstate} ne "up"').
You can use the following variables: %{runstate}, %{display}

=item B<--warning-package-error-rate>

Thresholds.

=item B<--critical-package-error-rate>

Thresholds.

=item B<--warning-noise>

Thresholds.

=item B<--critical-noise>

Thresholds.

=item B<--warning-channel-utilization-rate>

Thresholds.

=item B<--critical-channel-utilization-rate>

Thresholds.

=item B<--warning-channel-interference-rate>

Thresholds.

=item B<--critical-channel-interference-rate>

Thresholds.

=item B<--warning-receive-rate>

Thresholds.

=item B<--critical-receive-rate>

Thresholds.

=item B<--warning-send-rate>

Thresholds.

=item B<--critical-send-rate>

Thresholds.

=back

=cut
