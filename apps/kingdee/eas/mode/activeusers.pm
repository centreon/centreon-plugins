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

package apps::kingdee::eas::mode::activeusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'global_time', type => 0, cb_prefix_output => 'prefix_time_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'users-active-total', nlabel => 'system.users.active.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total users active: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        }
    ];

    $self->{maps_counters}->{global_time} = [];
    foreach (('1m', '5m', '15m', '30m', '1h', '3h', '8h')) {
        push @{$self->{maps_counters}->{global_time}},
        { label => 'users-active-' . $_, nlabel => 'system.users.active.' . $_ . '.count', set => {
                key_values => [ { name => 'users_' . $_ } ],
                output_template => '%s (' . $_ . ')',
                perfdatas => [
                    { value => 'users_' . $_  , template => '%s', min => 0 },
                ],
            }
        };
    }
}

sub prefix_time_output {
    my ($self, %options) = @_;

    return 'active users: ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s' => { name => 'url_path', default => "/easportal/tools/nagios/checkactiveusers.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /.*ActiveUsers_1m=.*/i) {
        $self->{output}->add_option_msg(short_msg => 'cannot find eas actvie users info.');
        $self->{output}->option_exit();
    }

    # ActiveUsers_1m=0 ActiveUsers_5m=0 ActiveUsers_15m=0 ActiveUsers_30m=0 ActiveUsers_1h=0 ActiveUsers_3h=0 ActiveUsers_8h=0 TotalUsers=0
    $self->{global} = {};
    $self->{global}->{total} = $1 if ($webcontent =~ /TotalUsers=(\d+)/mi);
    $self->{global_time} = {};
    while ($webcontent =~ /activeusers_(\S+?)=(\d+)/mig) {
        $self->{global_time}->{'users_' . $1} = $2;
    }
}

1;

__END__

=head1 MODE

Check eas active users info.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkclassloading.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sers-active-total', 'users-active-1m',
'users-active-5m', 'users-active-15m', 'users-active-30m', 
'users-active-1h', 'users-active-3h', 'users-active-8h'.

=back

=cut
