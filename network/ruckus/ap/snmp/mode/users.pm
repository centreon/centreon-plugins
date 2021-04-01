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

package network::ruckus::ap::snmp::mode::users;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_global_perfdata {
    my ($self, %options) = @_;
    
    if ($self->{result_values}->{limit} > 0) {
        $self->{output}->perfdata_add(label => 'total', unit => 'users',
                                      value => $self->{result_values}->{total},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{limit}, cast_int => 1),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{limit}, cast_int => 1),
                                      min => 0, max => $self->{result_values}->{limit});
    } else {
        $self->{output}->perfdata_add(label => 'total', unit => 'users',
                                      value => $self->{result_values}->{total},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
                                      min => 0);
    }
}

sub custom_global_threshold {
    my ($self, %options) = @_;
    
    my $exit;
    if ($self->{result_values}->{limit} > 0) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{total}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_global_output {
    my ($self, %options) = @_;
    
    my $msg = 'Total Users : ' . $self->{result_values}->{total};
    if ($self->{result_values}->{limit} > 0) {
        $msg .= " (" . sprintf("%.2f", $self->{result_values}->{prct_used}) . '% used on ' . $self->{result_values}->{limit} . ")";
    }

    return $msg;
}

sub custom_global_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{limit} = $options{new_datas}->{$self->{instance} . '_limit'};
    if ($self->{result_values}->{limit} > 0) {
        $self->{result_values}->{prct_used} = $self->{result_values}->{total} * 100 / $self->{result_values}->{limit};
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ssid', type => 1, cb_prefix_output => 'prefix_ssid_output', message_multiple => 'All users by SSID are ok', cb_init => 'skip_ssid', },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' }, { name => 'limit' } ],
                closure_custom_calc => $self->can('custom_global_calc'),
                closure_custom_output => $self->can('custom_global_output'),
                closure_custom_perfdata => $self->can('custom_global_perfdata'),
                closure_custom_threshold_check => $self->can('custom_global_threshold'),
            }
        },
    ];
    
    $self->{maps_counters}->{ssid} = [
        { label => 'ssid', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users : %s',
                perfdatas => [
                    { label => 'ssid', value => 'total', template => '%s', 
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_ssid_output {
    my ($self, %options) = @_;
    
    return "SSID '" . $options{instance_value}->{display} . "' ";
}

sub skip_ssid {
    my ($self, %options) = @_;

    scalar(keys %{$self->{ssid}}) > 1 ? return(0) : return(1);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-ssid:s'   => { name => 'filter_ssid' },
    });
    
    return $self;
}

my $oid_ruckusUnleashedSystemMaxSta = '.1.3.6.1.4.1.25053.1.15.1.1.1.1.13.0';
my $oid_ruckusUnleashedSystemStatsNumSta = '.1.3.6.1.4.1.25053.1.15.1.1.1.15.2.0';
my $mapping = {
    ruckusWLANStatsSSID     => { oid => '.1.3.6.1.4.1.25053.1.1.6.1.1.1.4.1.1' },
    ruckusWLANStatsNumSta   => { oid => '.1.3.6.1.4.1.25053.1.1.6.1.1.1.4.1.3' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => -1, limit => -1 };
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_ruckusUnleashedSystemMaxSta, $oid_ruckusUnleashedSystemStatsNumSta]);
    $self->{global}->{limit} = $snmp_result->{$oid_ruckusUnleashedSystemMaxSta} if (defined($snmp_result->{$oid_ruckusUnleashedSystemMaxSta}));
    $self->{global}->{total} = $snmp_result->{$oid_ruckusUnleashedSystemStatsNumSta} if (defined($snmp_result->{$oid_ruckusUnleashedSystemStatsNumSta}));
    
    return if ($self->{global}->{total} != -1);
    
    $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
        { oid => $mapping->{ruckusWLANStatsSSID}->{oid} }, 
        { oid => $mapping->{ruckusWLANStatsNumSta}->{oid} } ], return_type => 1, nothing_quit => 1);
    
    $self->{ssid} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{ruckusWLANStatsNumSta}->{oid}\.(\d+)/);
        $self->{global}->{total} = 0 if ($self->{global}->{total} == -1);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $result->{ruckusWLANStatsSSID} !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ruckusWLANStatsSSID} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{ssid}->{$result->{ruckusWLANStatsSSID}} = { display => $result->{ruckusWLANStatsSSID}, total => $result->{ruckusWLANStatsNumSta} };
        $self->{global}->{total} += $result->{ruckusWLANStatsNumSta};
    }
    
    if ($self->{global}->{total} == -1) {
        $self->{output}->add_option_msg(short_msg => "Cannot find informations");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check users connected.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'ssid'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'ssid'.

=item B<--filter-ssid>

Filter by SSID (can be a regexp).

=back

=cut
