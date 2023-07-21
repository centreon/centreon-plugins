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

package os::linux::local::mode::lvm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub prefix_vg_output {
    my ($self, %options) = @_;

    return sprintf(
        "VG '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_dlv_output {
    my ($self, %options) = @_;

    return sprintf(
        "direct LV '%s' [VG: %s] ",
        $options{instance_value}->{lvName},
        $options{instance_value}->{vgName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'vg', type => 1, cb_prefix_output => 'prefix_vg_output', message_multiple => 'All VGs are ok' },
        { name => 'dlv', type => 1, cb_prefix_output => 'prefix_dlv_output', message_multiple => 'All direct LVs are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'lv-detected', display_ok => 0, nlabel => 'lv.detected.count', set => {
                key_values => [ { name => 'lv_detected' } ],
                output_template => 'number of direct LV detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vg-detected', display_ok => 0, nlabel => 'vg.detected.count', set => {
                key_values => [ { name => 'vg_detected' } ],
                output_template => 'number of direct VG detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{dlv} = [
        { label => 'lv-data-usage', nlabel => 'lv.data.usage.percentage', set => {
                key_values => [ { name => 'data' }, { name => 'vgName' }, { name => 'lvName' } ],
                output_template => 'data usage: %.2f %%',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{vgName}, $self->{result_values}->{lvName}],
                        value => sprintf('%.2f', $self->{result_values}->{data}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        },
        { label => 'lv-meta-usage', nlabel => 'lv.meta.usage.percentage', set => {
                key_values => [ { name => 'meta' }, { name => 'vgName' }, { name => 'lvName' } ],
                output_template => 'meta usage: %.2f %%',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{vgName}, $self->{result_values}->{lvName}],
                        value => sprintf('%.2f', $self->{result_values}->{meta}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{vg} = [
        { label => 'vg-space-usage', nlabel => 'vg.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'vg-space-usage-free', nlabel => 'vg.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'vg-space-usage-prct', nlabel => 'vg.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-lv:s'       => { name => 'filter_lv' },
        'filter-vg:s'       => { name => 'filter_vg' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = $options{custom}->execute_command(
        command => 'lvs',
        command_options => '--separator=, 2>&1',
        no_quit => 1
    );

    $self->{global} = { lv_detected => 0, vg_detected => 0 };
    $self->{dlv} = {};
    #  LV,VG,Attr,LSize,Pool,Origin,Data%,Meta%,Move,Log,Cpy%Sync,Convert
    #  thinpool,docker,twi-aot---,71.25g,,,1.95,0.06,,,,
    #  lv_controlm,vg_sys,-wi-ao----,5.00g,,,,,,,,
    my @lines = split(/\n/, $stdout);
    shift @lines;
    my $i = 0;
    foreach my $line (@lines) {
        my @fields = split(/,/, $line);
        next if (!defined($fields[6]) || $fields[6] !~ /[0-9]/);
        my ($vg, $lv, $data, $meta) = (centreon::plugins::misc::trim($fields[1]), centreon::plugins::misc::trim($fields[0]), $fields[6], $fields[7]);

        next if (defined($self->{option_results}->{filter_lv}) && $self->{option_results}->{filter_lv} ne '' &&
            $lv !~ /$self->{option_results}->{filter_lv}/);
        next if (defined($self->{option_results}->{filter_vg}) && $self->{option_results}->{filter_vg} ne '' &&
            $vg !~ /$self->{option_results}->{filter_vg}/);

        $self->{lv_detected}++;
        $self->{dlv}->{$i} = { lvName => $lv, vgName => $vg, data => $data, meta => $meta };
        $i++;
    }

    ($stdout, $exit_code) = $options{custom}->execute_command(
        command => 'vgs',
        command_options => '--separator=, --units=b 2>&1',
        no_quit => 1
    );

    #  VG,#PV,#LV,#SN,Attr,VSize,VFree
    #  test,1,1,0,wz--n-,5364514816B,3217031168B
    $self->{vg} = {};
    @lines = split(/\n/, $stdout);
    shift @lines;
    foreach my $line (@lines) {
        my @fields = split(/,/, $line);
        next if (!defined($fields[5]) || $fields[5] !~ /[0-9]/);
        my $vg = centreon::plugins::misc::trim($fields[0]);
        $fields[5] =~ /^(\d+)/;
        my $size = $1;
        $fields[6] =~ /^(\d+)/;
        my $free = $1;

        next if (defined($self->{option_results}->{filter_vg}) && $self->{option_results}->{filter_vg} ne '' &&
            $vg !~ /$self->{option_results}->{filter_vg}/);

        $self->{vg_detected}++;
        $self->{vg}->{$vg} = {
            name => $vg,
            total => $size,
            free => $free,
            used => $size - $free,
            prct_free => $free * 100 / $size,
            prct_used => ($size - $free) * 100 / $size
        };
    }
}

1;

__END__

=head1 MODE

Check direct LV and VG free space.

Command used: lvs --separator="," 2>&1

=over 8

=item B<--filter-vg>

Filter volume group (regexp can be used).

=item B<--filter-lv>

Filter logical volume (regexp can be used).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'lv-detected', 'vg-detected',
'vg-space-usage', 'vg-space-usage-free', 'vg-space-usage-prct',
'lv-data-usage', 'lv-meta-usage'.

=back

=cut
