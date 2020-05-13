#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::snmp::mode::trunks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

my $thresholds = {
    trunk => [
        ['up', 'OK'],
        ['down', 'CRITICAL'],
        ['disable', 'CRITICAL'],
        ['uninitialized', 'CRITICAL'],
        ['loopback', 'OK'],
        ['unpopulated', 'OK'],
    ],
};

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return $self->{instance_mode}->get_severity(section => 'trunk', value => $self->{result_values}->{sysTrunkStatus});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{sysTrunkStatus} = $options{new_datas}->{$self->{instance} . '_sysTrunkStatus'};
    return 0;
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} > 0) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    my $speed = $self->{result_values}->{speed} > 0 ? $self->{result_values}->{speed} : undef;
    
    $self->{output}->perfdata_add(
        label => 'traffic_' . $self->{result_values}->{label}, unit => 'b/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic_per_seconds}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $speed
    );
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} > 0) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    my $msg = sprintf("Traffic %s : %s/s (%s)",
                      ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-');
    return $msg;
}

sub custom_traffic_calc {
    my ($self, %options) = @_;
    
    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }
  
    my $diff_traffic = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    
    $self->{result_values}->{speed} = defined($self->{instance_mode}->{option_results}->{speed}) && $self->{instance_mode}->{option_results}->{speed} ne '' ? $self->{instance_mode}->{option_results}->{speed} : $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{speed}};
    $self->{result_values}->{speed} = $self->{result_values}->{speed} * 1000 * 1000; # bits
    $self->{result_values}->{traffic_per_seconds} = $diff_traffic * 8 / $options{delta_time};
    $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $self->{result_values}->{speed} if ($self->{result_values}->{speed} > 0);
    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_errors_perfdata {
    my ($self, %options) = @_;
    
    my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
    my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    
    $self->{output}->perfdata_add(
        label => 'packets_error_' . $self->{result_values}->{label}, unit => '%',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{errors_prct}),
        warning => $warning,
        critical => $critical,
        min => 0, max => 100
    );
}

sub custom_errors_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{errors_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    
    return $exit;
}

sub custom_errors_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Packets %s Error : %s",
                      ucfirst($self->{result_values}->{label}), defined($self->{result_values}->{errors_prct}) ? sprintf("%.2f%%", $self->{result_values}->{errors_prct}) : '-');
    return $msg;
}

sub custom_errors_calc {
    my ($self, %options) = @_;
    
    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{errors}})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }
  
    my $diff_errors = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{errors}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{errors}});
    my $diff_packets = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}});
    
    $self->{result_values}->{errors_prct} = ($diff_packets != 0) ? $diff_errors * 100 / $diff_packets : 0;
    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_drops_perfdata {
    my ($self, %options) = @_;
    
    my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
    my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    
    $self->{output}->perfdata_add(
        label => 'packets_drop_' . $self->{result_values}->{label}, unit => '%',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{drops_prct}),
        warning => $warning,
        critical => $critical,
        min => 0, max => 100
    );
}

sub custom_drops_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{drops_prct}, threshold => [ { label => 'critial-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    
    return $exit;
}

sub custom_drops_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Packets %s Drop : %s",
                      ucfirst($self->{result_values}->{label}), defined($self->{result_values}->{drops_prct}) ? sprintf("%.2f%%", $self->{result_values}->{drops_prct}) : '-');
    return $msg;
}

sub custom_drops_calc {
    my ($self, %options) = @_;
    
    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{drops}})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }
  
    my $diff_drops = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{drops}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{drops}});
    my $diff_packets = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}});
    
    $self->{result_values}->{drops_prct} = ($diff_packets != 0) ? $diff_drops * 100 / $diff_packets : 0;
    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'trunks', type => 1, cb_prefix_output => 'prefix_trunks_output', message_multiple => 'All trunks are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{trunks} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'sysTrunkStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => "status is '%s'", output_error_template => 'Status : %s',
                output_use => 'sysTrunkStatus',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output')
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'sysTrunkStatBytesIn', diff => 1 }, { name => 'sysTrunkOperBw', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'),
                closure_custom_calc_extra_options => { label_ref => 'sysTrunkStatBytesIn', speed => 'sysTrunkOperBw', label => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'sysTrunkStatBytesOut', diff => 1 }, { name => 'sysTrunkOperBw', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'),
                closure_custom_calc_extra_options => { label_ref => 'sysTrunkStatBytesOut', speed => 'sysTrunkOperBw', label => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'packets-error-in', set => {
                key_values => [ { name => 'sysTrunkStatErrorsIn', diff => 1 }, { name => 'sysTrunkStatPktsIn', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => { errors => 'sysTrunkStatErrorsIn', packets => 'sysTrunkStatPktsIn', label => 'in' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'packets-error-out', set => {
                key_values => [ { name => 'sysTrunkStatErrorsOut', diff => 1 }, { name => 'sysTrunkStatPktsOut', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => { errors => 'sysTrunkStatErrorsOut', packets => 'sysTrunkStatPktsOut', label => 'out' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'packets-drop-in', set => {
                key_values => [ { name => 'sysTrunkStatDropsIn', diff => 1 }, { name => 'sysTrunkStatPktsIn', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_drops_calc'),
                closure_custom_calc_extra_options => { drops => 'sysTrunkStatDropsIn', packets => 'sysTrunkStatPktsIn', label => 'in' },
                closure_custom_output => $self->can('custom_drops_output'), output_error_template => 'Packets In Drop : %s',
                closure_custom_perfdata => $self->can('custom_drops_perfdata'),
                closure_custom_threshold_check => $self->can('custom_drops_threshold')
            }
        },
        { label => 'packets-drop-out', set => {
                key_values => [ { name => 'sysTrunkStatDropsOut', diff => 1 }, { name => 'sysTrunkStatPktsOut', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_drops_calc'),
                closure_custom_calc_extra_options => { drops => 'sysTrunkStatDropsOut', packets => 'sysTrunkStatPktsOut', label => 'out' },
                closure_custom_output => $self->can('custom_drops_output'), output_error_template => 'Packets Out Drop : %s',
                closure_custom_perfdata => $self->can('custom_drops_perfdata'),
                closure_custom_threshold_check => $self->can('custom_drops_threshold')
            }
        }
    ];
}

sub prefix_trunks_output {
    my ($self, %options) = @_;
    
    return "Trunk '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'         => { name => 'filter_name' },
        'threshold-overload:s@' => { name => 'threshold_overload' },
        'units-traffic:s'       => { name => 'units_traffic', default => '%' },
        'speed:s'               => { name => 'speed' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

my %map_trunk_status = (
    0 => 'up',
    1 => 'down',
    2 => 'disable',
    3 => 'uninitialized',
    4 => 'loopback',
    5 => 'unpopulated',
);

my $mapping_sysTrunk = {
    sysTrunkName            => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.1' },
    sysTrunkStatus          => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.2', map => \%map_trunk_status },
    sysTrunkOperBw          => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.5' },
};
my $oid_sysTrunkTable = '.1.3.6.1.4.1.3375.2.1.2.12.1.2';

my $mapping_sysTrunkStat = {
    sysTrunkStatPktsIn      => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.2' },
    sysTrunkStatBytesIn     => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.3' }, # Bytes
    sysTrunkStatPktsOut     => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.4' },
    sysTrunkStatBytesOut    => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.5' }, # Bytes
    sysTrunkStatErrorsIn    => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.8' },
    sysTrunkStatErrorsOut   => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.9' },
    sysTrunkStatDropsIn     => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.10' },
    sysTrunkStatDropsOut    => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.11' },
};
my $oid_sysTrunkStatTable = '.1.3.6.1.4.1.3375.2.1.2.12.2.3';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_sysTrunkTable, end => $mapping_sysTrunk->{sysTrunkOperBw}->{oid}  },
            { oid => $oid_sysTrunkStatTable }
        ],
        nothing_quit => 1
    );
    
    $self->{trunks} = {};
    foreach my $oid (keys %{$results->{$oid_sysTrunkTable}}) {
        next if ($oid !~ /^$mapping_sysTrunk->{sysTrunkName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result_sysTrunk = $options{snmp}->map_instance(mapping => $mapping_sysTrunk, results => $results->{$oid_sysTrunkTable}, instance => $instance);
        my $result_sysTrunkStat = $options{snmp}->map_instance(mapping => $mapping_sysTrunkStat, results => $results->{$oid_sysTrunkStatTable}, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result_sysTrunk->{sysTrunkName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result_sysTrunk->{sysTrunkName} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{trunks}->{$result_sysTrunk->{sysTrunkName}} = { 
            display => $result_sysTrunk->{sysTrunkName},
            %$result_sysTrunk, %$result_sysTrunkStat,
        };
    }
    
    if (scalar(keys %{$self->{trunks}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No trunks found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "f5_bipgip_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Trunks usage.

=over 8

=item B<--filter-name>

Filter by trunks name (regexp can be used).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='trunk,CRITICAL,^(?!(up)$)'

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out', 'packets-error-in' (%),
'packets-error-out' (%), 'packets-drop-in' (%), 'packets-drop-out' (%)

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out', 'packets-error-in' (%),
'packets-error-out' (%), 'packets-drop-in' (%), 'packets-drop-out' (%)

=item B<--speed>

Set trunk speed in Mbps (Default: sysTrunkOperBw).
If not set and sysTrunkOperBw OID value is 0,
percentage thresholds will not be applied on traffic metrics.

=back

=cut
