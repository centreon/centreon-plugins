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

package os::linux::local::mode::paging;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'pgpgin', nlabel => 'system.pgpin.usage.bytespersecond', set => {
                key_values => [ { name => 'pgpgin', per_second => 1 } ],
                output_template => 'pgpgin : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'pgpgin', template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'pgpgout', nlabel => 'system.pgpgout.usage.bytespersecond', set => {
                key_values => [ { name => 'pgpgout', per_second => 1 } ],
                output_template => 'pgpgout : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'pgpgout', template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'pswpin', nlabel => 'system.pswpin.usage.bytespersecond', set => {
                key_values => [ { name => 'pswpin', per_second => 1 } ],
                output_template => 'pswpin : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'pswpin', template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'pswpout', nlabel => 'system.pswpout.usage.bytespersecond', set => {
                key_values => [ { name => 'pswpout', per_second => 1 } ],
                output_template => 'pswpout : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'pswpout', template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'pgfault', nlabel => 'system.pgfault.usage.bytespersecond', set => {
                key_values => [ { name => 'pgfault', per_second => 1 } ],
                output_template => 'pgfault : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'pgfault', template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'pgmajfault', nlabel => 'system.pgmajfault.usage.bytespersecond', set => {
                key_values => [ { name => 'pgmajfault', per_second => 1 } ],
                output_template => 'pgmajfault : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'pgmajfault', template => '%d', unit => 'B/s', min => 0 }
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
    });

    return $self;
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Paging ';
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'cat',
        command_options => '/proc/vmstat 2>&1'
    );
        
    $self->{global} = {};
    $self->{global}->{pgpgin} = $stdout =~ /^pgpgin.*?(\d+)/msi ? $1 * 1024 : undef;
    $self->{global}->{pgpgout} = $stdout =~ /^pgpgout.*?(\d+)/msi ? $1 * 1024 : undef;
    $self->{global}->{pswpin} = $stdout =~ /^pswpin.*?(\d+)/msi ? $1 * 1024 : undef;
    $self->{global}->{pswpout} = $stdout =~ /^pswpout.*?(\d+)/msi ? $1 * 1024: undef;
    $self->{global}->{pgfault} = $stdout =~ /^pgfault.*?(\d+)/msi ? $1 * 1024: undef;
    $self->{global}->{pgmajfault} = $stdout =~ /^pgmajfault.*?(\d+)/msi ? $1 * 1014: undef;
    
    $self->{cache_name} = 'cache_linux_local_' . $options{custom}->get_identifier()  . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check paging informations.

Command used: cat /proc/vmstat 2>&1

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'pgpgin', 'pgpgout', 'pswpin', 'pswpout', 'pgfault', 'pgmajfault'.

=item B<--critical-*>

Threshold critical.
Can be: 'pgpgin', 'pgpgout', 'pswpin', 'pswpout', 'pgfault', 'pgmajfault'.

=back

=cut
