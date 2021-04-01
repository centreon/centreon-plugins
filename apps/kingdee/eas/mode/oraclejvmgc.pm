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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::oraclejvmgc;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'gc-minor', nlabel => 'java.gc.minor.count', set => {
                key_values => [ { name => 'minor_gc_count', diff => 1 } ],
                output_template => 'minor count: %s',
                perfdatas => [
                    { value => 'minor_gc_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'gc-minor-time', nlabel => 'java.gc.minor.time.milliseconds', set => {
                key_values => [ { name => 'minor_gc_time', diff => 1 } ],
                output_template => 'minor time: %s ms',
                perfdatas => [
                    { value => 'minor_gc_time', template => '%s', min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'gc-full', nlabel => 'java.gc.full.count', set => {
                key_values => [ { name => 'full_gc_count', diff => 1 } ],
                output_template => 'full count: %s',
                perfdatas => [
                    { value => 'full_gc_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'gc-full-time', nlabel => 'java.gc.full.time.milliseconds', set => {
                key_values => [ { name => 'full_gc_time', diff => 1 } ],
                output_template => 'full time: %s ms',
                perfdatas => [
                    { value => 'full_gc_time', template => '%s', min => 0, unit => 'ms' },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'garbage collector ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s' => { name => 'url_path', default => "/easportal/tools/nagios/checkgc_ps.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /MinorGCCount=(\d+)/mi) {
        $self->{output}->add_option_msg(short_msg => 'cannot find jvm gc status.');
        $self->{output}->option_exit();
    }

    $self->{global} = { minor_gc_count => 0 };
    $self->{global}->{minor_gc_time} = $1 if ($webcontent =~ /MinorGCTime=\s*(\d+)/mi);
    $self->{global}->{full_gc_count} = $1 if ($webcontent =~ /FullGCCount=\s*(\d+)/mi);
    $self->{global}->{full_gc_time} = $1 if ($webcontent =~ /FullGCTime=\s*(\d+)/mi);

    $self->{cache_name} = 'kingdee_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check EAS application jvm gc status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkgc_ps.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'gc-minor', 'gc-minor-time', 'gc-full', 'gc-full-time'.

=back

=cut
