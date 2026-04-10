#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::hitachi::eseries::local::mode::efficiency;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw/check_security_command/;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-efficiency-ratio', nlabel => 'storage.efficiency.total.ratio',
          critical_default => '1.01:', warning_default => '2.01:', set => {
                key_values      => [ { name => 'total_eff_r' } ],
                output_template => 'Total Efficiency Ratio: %.2f',
                perfdatas       => [ { template => '%.2f', min => 0 } ]
            }
        },
        { label => 'data-reduction-ratio', nlabel => 'storage.efficiency.data_reduction.ratio', set => {
                key_values      => [ { name => 'tls_r' } ],
                output_template => 'Data Reduction Ratio: %.2f',
                perfdatas       => [ { template => '%.2f', min => 0 } ]
            }
        },
        { label => 'software-saving-ratio', nlabel => 'storage.efficiency.software_saving.ratio', set => {
                key_values      => [ { name => 'pls_r' } ],
                output_template => 'Software Saving Ratio: %.2f',
                perfdatas       => [ { template => '%.2f', min => 0 } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command         => 'raidcom',
        command_options => 'get system -key efficiency -I' . $options{custom}->get_baie_id(),
    );

    # https://docs.hitachivantara.com/r/en-us/command-control-interface/01-87-03/mk-90rd7009/configuration-setting-commands/raidcom-get-system
    # raidcom get system -key efficiency
    # Serial# TOTAL_EFF_R TLS_R PLS_R PLS_CMP_R PLS_DDP_R PLS_RECLAIM_R FMD_SAVING_R FMD_CMP_R FMD_RECLAIM_R SNAPSHOT_EFF_R PROVISIONING_EFF(%) CALCULATION_START CALCULATION_END PLS_EXCUNCMP_R
    # 12345 11.64 1.84 1.52 1.15 1.34 1.11 2.21 2.14 1.08 10.37 70 2015-05-15T10:05 2015-05-15T10:38 1.6
    #
    # TOTAL_EFF_R => Total Efficiency Ratio
    # TLS_R => Data Reduction Ratio
    # PLS_R => Software Saving Ratio
    $self->{global} = {};
    foreach my $line (split /\n/, $stdout) {
        next if $line =~ /^Serial#/;
        next if $line =~ /^\s*$/;

        my @fields = split /\s+/, $line;
        $self->{global} = {
            total_eff_r       => $fields[1],
            tls_r             => $fields[2],
            pls_r             => $fields[3]
        };
        last
    }

    return if $self->{output}->is_disco_show();

    $self->{output}->option_exit(short_msg => "No efficiency data found.")
        unless exists $self->{global}->{total_eff_r};
}

1;

__END__

=head1 MODE

Check Hitachi E-Series storage efficiency ratios.

Command used: C<raidcom get system -key efficiency -I<baie-id>>

=over 8

=item B<--warning-total-efficiency-ratio>

Warning threshold for Total Efficiency Ratio (TOTAL_EFF) (default: C<2.01:> to warn if equal to or below 2).

=item B<--critical-total-efficiency-ratio>

Critical threshold for Total Efficiency Ratio (TOTAL_EFF) (default: C<1.01:> to alert if equal to or below 1).

=item B<--warning-data-reduction-ratio>

Warning threshold for Data Reduction Ratio (TLS_R).

=item B<--critical-data-reduction-ratio>

Critical threshold for Data Reduction Ratio (TLS_R).

=item B<--warning-software-saving-ratio>

Warning threshold for Software Saving Ratio (PLS_R).

=item B<--critical-software-saving-ratio>

Critical threshold for Software Saving Ratio (PLS_R).

=back

=cut
