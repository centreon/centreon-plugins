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
                    { label => 'data_used', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'meta-usage', set => {
                key_values => [ { name => 'meta' }, { name => 'display' } ],
                output_template => 'Meta Usage : %.2f %%',
                perfdatas => [
                    { label => 'meta_used', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
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
        'filter-lv:s'       => { name => 'filter_lv' },
        'filter-vg:s'       => { name => 'filter_vg' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = $options{custom}->execute_command(
        command => 'lvs',
        command_options => '--separator="," 2>&1',
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
Command used: lvs --separator="," 2>&1

=over 8

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
