#
# Copyright 2024-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::qos;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);

sub custom_qos_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic}, network => 1);
    my ($total_value, $total_unit);
    if (defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} =~ /[0-9]/) {
        ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{speed}, network => 1);
    }
   
    return sprintf(
        'traffic %s: %s/s (%s on %s)',
            $self->{result_values}->{label}, 
            $traffic_value . $traffic_unit,
            defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-',
            defined($total_value) ? $total_value . $total_unit : '-'
    );
}

sub custom_qos_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $traffic_key = $self->{instance} . '_traffic_' . $self->{result_values}->{label};
    $self->{result_values}->{traffic} = ($options{new_datas}->{$traffic_key} - $options{old_datas}->{$traffic_key}) / $options{delta_time};

    if ($options{new_datas}->{$self->{instance} . '_speed_' . $self->{result_values}->{label}} > 0) {
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $self->{result_values}->{label}};
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / $self->{result_values}->{speed};
    } elsif ($options{extra_options}->{type} eq 'percent') {
        return NO_VALUE;
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'qos', type => COUNTER_TYPE_INSTANCE, prefix_output => "QoS '%{display}' ", message_multiple => 'All QoS are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{qos} = [
        { label => 'traffic-in', nlabel => 'qos.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' }, { name => 'speed_in' } ],
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'in', type => 'abs' },
                closure_custom_output => $self->can('custom_qos_output'),
                threshold_use => 'traffic',
                perfdatas => [
                    { value => 'traffic', template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in-prct', nlabel => 'qos.traffic.in.percentage', display_ok => 0, set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' }, { name => 'speed_in' } ],
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'in', type => 'percent' },
                closure_custom_output => $self->can('custom_qos_output'),
                threshold_use => 'traffic_prct',
                perfdatas => [
                    { value => 'traffic_prct', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in-peak', nlabel => 'qos.traffic.in.peak.bitspersecond', set => {
                key_values => [ { name => 'traffic_in_peak' }, { name => 'display' } ],
                output_template => 'traffic in peak: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'qos.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' }, { name => 'speed_out' } ],
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'out', type => 'abs' },
                closure_custom_output => $self->can('custom_qos_output'),
                threshold_use => 'traffic',
                perfdatas => [
                    { value => 'traffic', template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out-prct', nlabel => 'qos.traffic.out.percentage', display_ok => 0, set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' }, { name => 'speed_out' } ],
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'out', type => 'percent' },
                closure_custom_output => $self->can('custom_qos_output'),
                threshold_use => 'traffic_prct',
                perfdatas => [
                    { value => 'traffic_prct', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out-peak', nlabel => 'qos.traffic.out.peak.bitspersecond', set => {
                key_values => [ { name => 'traffic_out_peak' }, { name => 'display' } ],
                output_template => 'traffic out peak: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' },
        'filter-name:s'  => { redirect => 'include_name' },
        'speed-in:s'     => { name => 'speed_in' },
        'speed-out:s'    => { name => 'speed_out' }
    });

    return $self;
}

my $mapping = {
    traffic_in       => { oid => '.1.3.6.1.4.1.11256.1.15.1.1.4' }, # snsQosEntryInCounter    
    traffic_in_peak  => { oid => '.1.3.6.1.4.1.11256.1.15.1.1.5' }, # snsQosEntryInMaxPeak
    speed_in         => { oid => '.1.3.6.1.4.1.11256.1.15.1.1.6' }, # snsQosEntryInSpeedLimit
    traffic_out      => { oid => '.1.3.6.1.4.1.11256.1.15.1.1.7' }, # snsQosEntryOutCounter    
    traffic_out_peak => { oid => '.1.3.6.1.4.1.11256.1.15.1.1.8' }, # snsQosEntryOutMaxPeak
    speed_out        => { oid => '.1.3.6.1.4.1.11256.1.15.1.1.9' }  # snsQosEntryOutSpeedLimit
};
my $oid_snsQosEntryName = '.1.3.6.1.4.1.11256.1.15.1.1.2';


sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->option_exit(short_msg => 'Need to use SNMP v2c or v3.');
    }

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_snsQosEntryName,
        nothing_quit => 1
    );

    $self->{qos} = {};
    foreach (keys %$snmp_result) {
        /^$oid_snsQosEntryName\.(.*)$/;
        my $instance = $1;

        my $name = $snmp_result->{$_};
        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output}));

        $self->{qos}->{$instance} = { display => $name };
    }

    if (scalar(keys %{$self->{qos}}) <= 0) {
        $self->{output}->option_exit(short_msg => 'No QoS found.');
    }

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [keys %{$self->{qos}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{qos}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        foreach (('in', 'out')) {
            $result->{'speed_' . $_} = defined($self->{option_results}->{'speed_' . $_}) && $self->{option_results}->{'speed_' . $_} =~ /(\d+)/
                ? ($1 * 1000 * 1000) : (defined($result->{'speed_' . $_}) ? ($result->{'speed_' . $_} * 1024 * 8) : 0);
            $result->{'traffic_' . $_} *= 8;
            $result->{'traffic_' . $_ . '_peak'} *= 8;
        }
        $self->{qos}->{$_} = {
            %{$self->{qos}->{$_}},
            %$result
        };
    }

    $self->{cache_name} = 'stormshield_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port()
        . '_' . sha256_hex(
            ($self->{option_results}->{filter_counters} // '')
            . '_' . $self->{option_results}->{include_name}
            . '_' . $self->{option_results}->{exclude_name}
        );
}

1;

__END__

=head1 MODE

Check QoS usage.

=over 8

=item B<--include-name>

Filter by QoS name (can be a regexp). Option C<--filter-name> is a deprecated alias.

=item B<--exclude-name>

Exclude QoS by name (can be a regexp).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--warning-traffic-in>

Threshold in b/s.

=item B<--critical-traffic-in>

Threshold in b/s.

=item B<--warning-traffic-in-prct>

Threshold in percentage of the incoming speed.

=item B<--critical-traffic-in-prct>

Threshold in percentage of the incoming speed.

=item B<--warning-traffic-in-peak>

Threshold in b/s.

=item B<--critical-traffic-in-peak>

Threshold in b/s.

=item B<--warning-traffic-out>

Threshold in b/s.

=item B<--critical-traffic-out>

Threshold in b/s.

=item B<--warning-traffic-out-prct>

Threshold in percentage of the outgoing speed.

=item B<--critical-traffic-out-prct>

Threshold in percentage of the outgoing speed.

=item B<--warning-traffic-out-peak>

Threshold in b/s.

=item B<--critical-traffic-out-peak>

Threshold in b/s.

=back

=cut
