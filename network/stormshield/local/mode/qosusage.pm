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

package network::stormshield::local::mode::qosusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'qos', type => 1, cb_prefix_output => 'prefix_qos_output', message_multiple => 'All QoS are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{qos} = [
        { label => 'in', set => {
                key_values => [ { name => 'in' }, { name => 'display' }, { name => 'speed_in' } ],
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_qos_output'),
                closure_custom_perfdata => $self->can('custom_qos_perfdata'),
                closure_custom_threshold_check => $self->can('custom_qos_threshold'),
            }
        },
        { label => 'in-peak', set => {
                key_values => [ { name => 'in_peak' }, { name => 'display' } ],
                output_template => 'In Peak : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in_peak', value => 'in_peak', template => '%.2f',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'out', set => {
                key_values => [ { name => 'out' }, { name => 'display' }, { name => 'speed_out' } ],
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_qos_output'),
                closure_custom_perfdata => $self->can('custom_qos_perfdata'),
                closure_custom_threshold_check => $self->can('custom_qos_threshold'),
            }
        },
        { label => 'out-peak', set => {
                key_values => [ { name => 'out_peak' }, { name => 'display' } ],
                output_template => 'Out Peak : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out_peak', value => 'out_peak', template => '%.2f',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub custom_qos_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }
    
    $self->{output}->perfdata_add(
        label => 'traffic_' . $self->{result_values}->{label}, unit => 'b/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $self->{result_values}->{speed}
    );
}

sub custom_qos_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_qos_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic}, network => 1);
    my ($total_value, $total_unit);
    if (defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} =~ /[0-9]/) {
        ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{speed}, network => 1);
    }
   
    my $msg = sprintf("Traffic %s : %s/s (%s on %s)",
                      ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-',
                      defined($total_value) ? $total_value . $total_unit : '-');
    return $msg;
}

sub custom_qos_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}};
    if ($options{new_datas}->{$self->{instance} . '_speed_' . $self->{result_values}->{label}} > 0) {
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $self->{result_values}->{label}} * 1000 * 1000;
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / $self->{result_values}->{speed};
    } elsif (defined($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}}) && $self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} =~ /[0-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / ($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000);
        $self->{result_values}->{speed} = $self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"       => { name => 'filter_name' },
        "filter-vlan:s"       => { name => 'filter_vlan' },
        "speed-in:s"          => { name => 'speed_in' },
        "speed-out:s"         => { name => 'speed_out' },
        "units-traffic:s"     => { name => 'units_traffic', default => '%' },
        "hostname:s"          => { name => 'hostname' },
        "ssh-option:s@"       => { name => 'ssh_option' },
        "ssh-path:s"          => { name => 'ssh_path' },
        "ssh-command:s"       => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"           => { name => 'timeout', default => 30 },
        "sudo"                => { name => 'sudo' },
        "command:s"           => { name => 'command', default => 'tail' },
        "command-path:s"      => { name => 'command_path' },
        "command-options:s"   => { name => 'command_options', default => '-1 /log/l_monitor' },
        "config-speed-file:s" => { name => 'config_speed_file' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
    }    
}

sub prefix_qos_output {
    my ($self, %options) = @_;
    
    return "QoS '" . $options{instance_value}->{display} . "' ";
}

sub load_speed_config {
    my ($self, %options) = @_;
    
    $self->{config_speeds} = {};
    return if (!defined($self->{option_results}->{config_speed_file}) || $self->{option_results}->{config_speed_file} eq '');
    $self->{content} = do {
        local $/ = undef;
        if (open my $fh, "<", $self->{option_results}->{config_speed_file}) {
            <$fh>;
        }
    };
    return if (!defined($self->{content}));
    #[TEST]
    #Type=CBQ
    #Min=0
    #Max=5000
    #Min_Rev=0
    #Max_Rev=5000
    #QLength=0
    #PrioritizeAck=1
    #PrioritizeLowDelay=1
    #Color=000000
    #Comment=
    #
    # Units: Kb
    while ($self->{content} =~ /\[(.*?)\].*?Max=(.*?)\n.*?Max_Rev=(.*?)\n/msg) {
        $self->{config_speeds}->{$1} = { speed_in => $3 / 1000, speed_out => $2 / 1000 }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    #id=firewall time="2017-01-31 16:56:36" fw="XXXX" tz=+0100 startime="2017-01-31 16:56:36" security=70 system=1 CPU=3,2,1 Pvm=0,0,0,0,0,0,0,0,0,0,0 Vlan96=VLAN-XXX-DMZ,15140,17768,21952,28280 Vlan76=dmz-xxx-xxx,769592,948320,591584,795856
    my $content = centreon::plugins::misc::execute(output => $self->{output},
                                                   options => $self->{option_results},
                                                   sudo => $self->{option_results}->{sudo},
                                                   command => $self->{option_results}->{command},
                                                   command_path => $self->{option_results}->{command_path},
                                                   command_options => $self->{option_results}->{command_options});
    
    $self->load_speed_config();    
    $self->{qos} = {};
    
    # Version 3, there is 7 fields (5 before)
    my $pattern = '(\S+?)=([^,]+?),(\d+),(\d+),(\d+),(\d+)(?:\s|\Z)';
    if ($content !~ /$pattern/) {
        $pattern = '(\S+?)=([^,]+?),(\d+),(\d+),(\d+),(\d+),\d+,\d+(?:\s|\Z)';
    }
    
    while ($content =~ /$pattern/msg) {
        my ($vlan, $name, $in, $in_max, $out, $out_max) = ($1, $2, $3, $4, $5, $6);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_vlan}) && $self->{option_results}->{filter_vlan} ne '' &&
            $vlan !~ /$self->{option_results}->{filter_vlan}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $vlan . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{qos}->{$name} = { 
            display => $name, 
            in => $in, in_peak => $in_max,
            out => $out, out_peak => $out_max,
            speed_in => defined($self->{config_speeds}->{$name}->{speed_in}) ? $self->{config_speeds}->{$name}->{speed_in} : 0,
            speed_out => defined($self->{config_speeds}->{$name}->{speed_out}) ? $self->{config_speeds}->{$name}->{speed_out} : 0};
    }
    
    if (scalar(keys %{$self->{qos}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No QoS found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check QoS usage.

=over 8

=item B<--filter-name>

Filter by QoS name (can be a regexp).

=item B<--filter-vlan>

Filter by vlan name (can be a regexp).

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'tail').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-1 /log/l_monitor').

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--config-speed-file>

File with speed configurations.

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--warning-*>

Threshold warning.
Can be: 'in', 'in-peak', 'out', 'out-peak'.

=item B<--critical-*>

Threshold critical.
Threshold warning.
Can be: 'in', 'in-peak', 'out', 'out-peak'.

=back

=cut
