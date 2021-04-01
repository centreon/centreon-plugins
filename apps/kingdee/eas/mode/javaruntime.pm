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

package apps::kingdee::eas::mode::javaruntime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'uptime', nlabel => 'java.uptime.milliseconds', set => {
                key_values => [ { name => 'uptime' }, { name => 'uptime_date' } ],
                output_template => 'java uptime: %s',
                output_use => 'uptime_date',
                perfdatas => [
                    { value => 'uptime', template => '%s',
                      unit => 'ms' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s' => { name => 'url_path', default => "/easportal/tools/nagios/checkjavaruntime.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
    if ($webcontent !~ /VmName=/mi) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find java runtime status.');
        $self->{output}->option_exit();
    }

    my ($vmname, $specversion, $vmversion, $vendor, $uptime);
    $vmname = $1 if ($webcontent =~ /VmName=\'(.*?)\'/i);
    $specversion = $1 if ($webcontent =~ /SpecVersion=([\d\.]+)/i);
    $vmversion = $1 if ($webcontent =~ /VmVersion=(.*?)\s/i);
    $vendor = $1 if ($webcontent =~ /VmVendor=\'(.*?)\'/i);
    $uptime = $1 if ($webcontent =~ /Uptime=(\d*)/i);   #unit:ms

    $self->{output}->output_add(
        long_msg => sprintf(
            '%s %s (build %s), %s', 
            $vmname, $specversion, $vmversion, $vendor
        )
    );

    $self->{global} = { 
        uptime => $uptime,
        uptime_date => centreon::plugins::misc::change_seconds(value => floor($uptime / 1000), start => 'd')
    };
}

1;

__END__

=head1 MODE

Check EAS application java runtime status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkjavaruntime.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'uptime'.

=back

=cut
