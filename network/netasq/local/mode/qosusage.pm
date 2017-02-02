#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::netasq::local::mode::qosusage;

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
                key_values => [ { name => 'in_prct' }, { name => 'in' }, { name => 'total_in' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_qos_output'),
                threshold_use => 'in_prct_absolute',
                perfdatas => [
                    { label => 'traffic_in', value => 'in_absolute', template => '%s', unit => 'b/s',
                      min => 0, max => 'total_in_absolute', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'out', set => {
                key_values => [ { name => 'out_prct' }, { name => 'out' }, { name => 'total_out' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_qos_output'),
                threshold_use => 'out_prct_absolute',
                perfdatas => [
                    { label => 'traffic_out', value => 'out_absolute', template => '%s', unit => 'b/s',
                      min => 0, max => 'total_out_absolute', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub custom_qos_output {
    my ($self, %options) = @_;
    
    my $label = defined($self->{result_values}->{in_absolute}) ? 'in' : 'out';
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{$label . '_absolute'}, network => 1);
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{'total_' . $label . '_absolute'}, network => 1);
    my $msg = sprintf("Traffic %s : %s/s (%.2f %%) on %s/s",
                      ucfirst($label), $traffic_value . $traffic_unit,
                      $self->{result_values}->{$label . '_prct_absolute'},
                      $total_value . $total_unit);
    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "filter-vlan:s"       => { name => 'filter_vlan' },
                                  "hostname:s"          => { name => 'hostname' },
                                  "ssh-option:s@"       => { name => 'ssh_option' },
                                  "ssh-path:s"          => { name => 'ssh_path' },
                                  "ssh-command:s"       => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'tail' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-1 /log/l_monitor 2>&1' },
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

sub manage_selection {
    my ($self, %options) = @_;
    
    #id=firewall time="2017-01-31 16:56:36" fw="XXXX" tz=+0100 startime="2017-01-31 16:56:36" security=70 system=1 CPU=3,2,1 Pvm=0,0,0,0,0,0,0,0,0,0,0 Vlan96=VLAN-XXX-DMZ,15140,17768,21952,28280 Vlan76=dmz-xxx-xxx,769592,948320,591584,795856
    my $content = centreon::plugins::misc::execute(output => $self->{output},
                                                   options => $self->{option_results},
                                                   sudo => $self->{option_results}->{sudo},
                                                   command => $self->{option_results}->{command},
                                                   command_path => $self->{option_results}->{command_path},
                                                   command_options => $self->{option_results}->{command_options});
    
    $self->{qos} = {};
    
    while ($content =~ /(\S+?)=([^,]+?),(\d+),(\d+),(\d+),(\d+)(?:\s|\Z)/msg) {
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
        $in_max = undef if ($in_max == 0);
        $out_max = undef if ($out_max == 0);
        if (!defined($in_max) && !defined($out_max)) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no max values.", debug => 1);
            next;
        }
        
        $self->{qos}->{$name} = { 
            display => $name, 
            in => $in, in_prct => defined($in_max) ? $in * 100 / $in_max : undef, total_in => $in_max,
            out => $out, out_prct => defined($out_max) ? $out * 100 / $out_max : undef, total_out => $out_max };
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

Command options (Default: '-1 /log/l_monitor 2>&1').

=item B<--warning-*>

Threshold warning.
Can be: 'in' (%), 'out' (%).

=item B<--critical-*>

Threshold critical.
Threshold warning.
Can be: 'in' (%), 'out' (%).

=back

=cut
