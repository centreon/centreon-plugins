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

package os::linux::local::mode::packeterrors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status : %s', $self->{result_values}->{status});
}

sub custom_packet_output {
    my ($self, %options) = @_;

    return sprintf(
        'Packet %s %s : %.2f %% (%s)',
        ucfirst($self->{result_values}->{type}),
        ucfirst($self->{result_values}->{label}), 
        $self->{result_values}->{result_prct},
        $self->{result_values}->{diff_value}
    );
}

sub custom_packet_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{type} = $options{extra_options}->{type};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{diff_value} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{type} . '_' . $self->{result_values}->{label}} - 
        $options{old_datas}->{$self->{instance} . '_' . $self->{result_values}->{type} . '_' . $self->{result_values}->{label}};
    my $diff_total = $options{new_datas}->{$self->{instance} . '_total_' . $self->{result_values}->{label}} - 
        $options{old_datas}->{$self->{instance} . '_total_' . $self->{result_values}->{label}};

    $self->{result_values}->{result_prct} = ($diff_total == 0) ? 0 : ($self->{result_values}->{diff_value} * 100 / $diff_total);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interface', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All interfaces are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{interface} = [
        { label => 'status', type => 2, critical_default => '%{status} ne "RU"', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'in-discard', set => {
                key_values => [ { name => 'discard_in', diff => 1 }, { name => 'total_in', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_packet_calc'), closure_custom_calc_extra_options => { type => 'discard', label_ref => 'in' },
                closure_custom_output => $self->can('custom_packet_output'), output_error_template => 'Discard In : %s',
                threshold_use => 'result_prct',
                perfdatas => [
                    { label => 'packets_discard_in', value => 'result_prct', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-discard', set => {
                key_values => [ { name => 'discard_out', diff => 1 }, { name => 'total_out', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_packet_calc'), closure_custom_calc_extra_options => { type => 'discard', label_ref => 'out' },
                closure_custom_output => $self->can('custom_packet_output'), output_error_template => 'Discard Out : %s',
                threshold_use => 'result_prct',
                perfdatas => [
                    { label => 'packets_discard_out', value => 'result_prct', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'in-error', set => {
                key_values => [ { name => 'error_in', diff => 1 }, { name => 'total_in', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_packet_calc'), closure_custom_calc_extra_options => { type => 'error', label_ref => 'in' },
                closure_custom_output => $self->can('custom_packet_output'), output_error_template => 'Error In : %s',
                threshold_use => 'result_prct',
                perfdatas => [
                    { label => 'packets_error_in', value => 'result_prct', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-error', set => {
                key_values => [ { name => 'error_out', diff => 1 }, { name => 'total_out', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_packet_calc'), closure_custom_calc_extra_options => { type => 'error', label_ref => 'out' },
                closure_custom_output => $self->can('custom_packet_output'), output_error_template => 'Error In : %s',
                threshold_use => 'result_prct',
                perfdatas => [
                    { label => 'packets_error_out', value => 'result_prct', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-state:s'     => { name => 'filter_state', },
        'filter-interface:s' => { name => 'filter_interface' },
        'no-loopback'        => { name => 'no_loopback' }
    });

    return $self;
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub do_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'ip',
        command_path => '/sbin',
        command_options => '-s addr 2>&1'
    );

    my $mapping = {
        ifconfig => {
            get_interface => '^(\S+)(.*?)(\n\n|\n$)',
            total => 'RX packets:(\d+).*?TX packets:(\d+)',
            discard_in => 'RX packets:\d+\s+?errors:\d+\s+?dropped:(\d+)',
            discard_out => 'TX packets:\d+\s+?errors:\d+\s+?dropped:(\d+)',
            error_in => 'RX packets:\d+\s+?errors:(\d+)',
            error_out => 'TX packets:\d+\s+?errors:(\d+)',
        },
        iproute => {
            get_interface => '^\d+:\s+(\S+)(.*?)(?=\n\d|\Z$)',
            total => 'RX:\s+bytes\s+packets.*?\d+\s+(\d+).*?TX:\s+bytes\s+packets.*?\d+\s+(\d+)',
            discard_in => 'RX:.*?dropped.*?\d+.*?\d+.*?\d+.*?(\d+)',
            discard_out => 'TX:.*?dropped.*?\d+.*?\d+.*?\d+.*?(\d+)',
            error_in => 'RX:.*?errors.*?\d+.*?\d+.*?(\d+)',
            error_out => 'TX:.*?errors.*?\d+.*?\d+.*?(\d+)',
        },
    };

    my $type = 'ifconfig';
    if ($stdout =~ /^\d+:\s+\S+:\s+</ms) {
        $type = 'iproute';
    }

    $self->{interface} = {};
    while ($stdout =~ /$mapping->{$type}->{get_interface}/msg) {
        my ($interface_name, $values) = ($1, $2);
        my $states = '';
        $states .= 'R' if ($values =~ /RUNNING|LOWER_UP/ms);
        $states .= 'U' if ($values =~ /UP/ms);
        $interface_name =~ s/:$//;

        next if (defined($self->{option_results}->{no_loopback}) && $values =~ /LOOPBACK/ms);
        next if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $states !~ /$self->{option_results}->{filter_state}/);
        next if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
            $interface_name !~ /$self->{option_results}->{filter_interface}/);

        $self->{interface}->{$interface_name} = {
            display => $interface_name,
            status => $states,
        };
        if ($values =~ /$mapping->{$type}->{total}/msi) {
            $self->{interface}->{$interface_name}->{total_in} = $1;
            $self->{interface}->{$interface_name}->{total_out} = $2;
        }
        
        foreach ('discard_in', 'discard_out', 'error_in', 'error_out') {
            if ($values =~ /$mapping->{$type}->{$_}/msi) {
                $self->{interface}->{$interface_name}->{$_} = $1;
            }
        }
    }

    if (scalar(keys %{$self->{interface}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interface found.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->do_selection(custom => $options{custom});
    $self->{cache_name} = 'cache_linux_local_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_interface}) ? md5_hex($self->{option_results}->{filter_interface}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check packets errors and discards on interfaces.

Command used: /sbin/ip -s addr 2>&1

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

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

Command to get information (Default: 'ip').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/sbin').

=item B<--command-options>

Command options (Default: '-s addr 2>&1').

=item B<--warning-*>

Threshold warning in percent of total packets. Can be:
in-error, out-error, in-discard, out-discard

=item B<--critical-*>

Threshold critical in percent of total packets. Can be:
in-error, out-error, in-discard, out-discard

=item B<--filter-interface>

Filter interface name (regexp can be used).

=item B<--filter-state>

Filter filesystem type (regexp can be used).

=item B<--no-loopback>

Don't display loopback interfaces.

=back

=cut
