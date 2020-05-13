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

package os::linux::local::mode::directlvmusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'dlvm', type => 1, cb_prefix_output => 'prefix_dlvm_output', message_multiple => 'All direct LVM are ok' }
    ];

    $self->{maps_counters}->{dlvm} = [
        { label => 'data-usage', set => {
                key_values => [ { name => 'data' }, { name => 'display' } ],
                output_template => 'Data Usage : %.2f %%',
                perfdatas => [
                    { label => 'data_used', value => 'data', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'meta-usage', set => {
                key_values => [ { name => 'meta' }, { name => 'display' } ],
                output_template => 'Meta Usage : %.2f %%',
                perfdatas => [
                    { label => 'meta_used', value => 'meta', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_dlvm_output {
    my ($self, %options) = @_;
    
    return "Direct LVM '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname' },
        'remote'            => { name => 'remote' },
        'ssh-option:s@'     => { name => 'ssh_option' },
        'ssh-path:s'        => { name => 'ssh_path' },
        'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'         => { name => 'timeout', default => 30 },
        'sudo'              => { name => 'sudo' },
        'command:s'         => { name => 'command', default => 'lvs' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '--separator="," 2>&1' },
        'filter-lv:s'       => { name => 'filter_lv' },
        'filter-vg:s'       => { name => 'filter_vg' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
        no_quit => 1
    );
    $self->{dlvm} = {};
    #  LV,VG,Attr,LSize,Pool,Origin,Data%,Meta%,Move,Log,Cpy%Sync,Convert
    #  thinpool,docker,twi-aot---,71.25g,,,1.95,0.06,,,,
    #  lv_controlm,vg_sys,-wi-ao----,5.00g,,,,,,,,
    #  ...
    my @lines = split /\n/, $stdout;
    shift @lines;
    foreach my $line (@lines) {
        my @fields = split /,/, $line;
        my ($vg, $lv, $data, $meta) = ($fields[1], $fields[0], $fields[6], $fields[7]);
        next if (!defined($data) || $data !~ /[0-9]/);

        my $display = centreon::plugins::misc::trim($vg) . '.' . centreon::plugins::misc::trim($lv);
        if (defined($self->{option_results}->{filter_lv}) && $self->{option_results}->{filter_lv} ne '' &&
            $lv !~ /$self->{option_results}->{filter_lv}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_vg}) && $self->{option_results}->{filter_vg} ne '' &&
            $vg !~ /$self->{option_results}->{filter_vg}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }

        $self->{dlvm}->{$display} = { display => $display, data => $data, meta => $meta };
    }
    
    if (scalar(keys %{$self->{dlvm}}) <= 0) {
        if ($exit_code != 0) {
            $self->{output}->output_add(long_msg => "command output:" . $stdout);
        }
        $self->{output}->add_option_msg(short_msg => "No direct lvm found (filters or command issue)");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check directl lvm usage.

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

Command to get information (Default: 'lvs').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '--separator="," 2>&1').

=item B<--warning-*>

Threshold warning.
Can be: 'data-usage' (%), 'meta-usage' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'data-usage' (%), 'meta-usage' (%).

=item B<--filter-vg>

Filter virtual group (regexp can be used).

=item B<--filter-lv>

Filter logical volume (regexp can be used).

=back

=cut
