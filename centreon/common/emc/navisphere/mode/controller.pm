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

package centreon::common::emc::navisphere::mode::controller;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_busy_calc {
    my ($self, %options) = @_;
    my $diff_busy = ($options{new_datas}->{$self->{instance} . '_busy_ticks'} - $options{old_datas}->{$self->{instance} . '_busy_ticks'});
    my $total = $diff_busy
                + ($options{new_datas}->{$self->{instance} . '_idle_ticks'} - $options{old_datas}->{$self->{instance} . '_idle_ticks'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{busy_prct} = $diff_busy * 100 / $total;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -2 => 1, -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'read-iops', nlabel => 'controller.io.read.usage.iops', set => {
                key_values => [ { name => 'read', per_second => 1 } ],
                output_template => 'Read IOPs : %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'controller.io.write.usage.iops', set => {
                key_values => [ { name => 'write', per_second => 1 } ],
                output_template => 'Write IOPs : %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0 }
                ]
            }
        },
        { label => 'busy', nlabel => 'controller.busy.usage.percentage', set => {
                key_values => [ { name => 'idle_ticks', diff => 1 }, { name => 'busy_ticks', diff => 1 } ],
                closure_custom_calc => $self->can('custom_busy_calc'),
                output_template => 'Busy : %.2f %%',
                output_use => 'busy_prct',  threshold_use => 'busy_prct',
                perfdatas => [
                    { value => 'busy_prct', template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Global Controller ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute_command(cmd => 'getcontrol -cbt -busy -write -read -idle');

    $self->{global} = {};
    $self->{global}->{read} = $response =~ /^Total Reads:\s*(\d+)/msi ? $1 : undef;
    $self->{global}->{write} = $response =~ /^Total Writes:\s*(\d+)/msi ? $1 : undef;;
    $self->{global}->{idle_ticks} = $response =~ /^Controller idle ticks:\s*(\d+)/msi ? $1 : undef;
    $self->{global}->{busy_ticks} = $response =~ /^Controller busy ticks:\s*(\d+)/msi ? $1 : undef;
    
    $self->{cache_name} = "cache_clariion_" . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check global controller (busy usage, iops). 

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'busy', 'read-iops', 'write-iops'.

=item B<--critical-*>

Threshold critical.
Can be: 'busy', 'read-iops', 'write-iops'.

=back

=cut
