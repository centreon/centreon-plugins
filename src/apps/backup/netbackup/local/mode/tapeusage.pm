#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::backup::netbackup::local::mode::tapeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $nlabel = $self->{option_results}->{units} eq '%' ? 'tape.usage.percentage' : 'tape.usage.bytes';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $nlabel = $self->{option_results}->{units} eq '%' ? 'tape.free.usage.percentage' : 'tape.free.usage.bytes';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label,
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        "total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used}, $self->{result_values}->{prct_used},
        $self->{result_values}->{free}, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};

    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'total' }, { name => 'used' } ],
                closure_custom_calc => \&custom_usage_calc,
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-scratch:s'  => { name => 'filter_scratch', default => 'scratch' },
        'units:s'           => { name => 'units', default => '%' },
        'free'              => { name => 'free' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'vmquery',
        command_options => '-a -w'
    );

    if (defined($self->{option_results}->{exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    $self->{global} = { total => 0, used => 0 };
    #media   optical media                       barcode           robot         robot  robot  robot  side/  volume                                                   prev                    # of     max       # of            create          assigned       first mount        last mount        expiration                                             off sent        off return     off     off                                     
    #ID      partner type      barcode           partner           host          type       #   slot  face   group                      pool                  pool #  pool                  mounts  mounts  cleanings          datetime          datetime          datetime          datetime          datetime  status  offsite location                   datetime          datetime    slot  ses id   version  description              
    #--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #000001  -       HCART2    000001L5          -                 -             NONE       -      -  -      ---                        VP-05WEEKS-EXT             9  VP-SCRATCH              1250       0          -  30/11/2012 15:30  29/02/2016 20:43  27/01/2013 17:57  02/03/2016 01:36  00/00/0000 00:00       0  -                          00/00/0000 00:00  00/00/0000 00:00  -       -             50  ---                      
    #000002  -       HCART2    000002L5          -                 XXX-NBU-XXX   TLD        0       8  -      000_00000_TLD              VP-SCRATCH                 4  VP-05WEEKS-EXT 

    # Remove header
    $stdout =~ s/\x00//msg;
    $stdout =~ s/^.*?----.*?\n//ms;
    foreach my $line (split /\n/, $stdout) {
        $line =~ /^\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)/;
        my ($robot_host, $robot_slot, $pool) = ($1, $2, $3);

        next if ($robot_slot !~ /[0-9]/);

        $self->{global}->{total}++;
        if (defined($self->{option_results}->{filter_scratch}) && $self->{option_results}->{filter_scratch} ne '' &&
            $pool !~ /$self->{option_results}->{filter_scratch}/i) {
            $self->{global}->{used}++;
        }
    }

    if ($self->{global}->{total} == 0) {
        $self->{output}->add_option_msg(short_msg => 'No tape found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check tapes available in library.

Command used: vmquery -a -w

=over 8

=item B<--exec-only>

Print command output

=item B<--filter-scratch>

Filter tape scratch (default: 'scratch').

=item B<--units>

Units of thresholds (default: '%') ('%', 'absolute').

=item B<--free>

Thresholds are on free tape left.

=item B<--warning-*>

Warning threshold.
Can be: 'usage'.

=item B<--critical-*>

Critical threshold.
Can be: 'usage'.

=back

=cut
