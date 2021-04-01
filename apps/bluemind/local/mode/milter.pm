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

package apps::bluemind::local::mode::milter;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_milter_output {
    my ($self, %options) = @_;
    
    return 'Milter service ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_milter', type => 0, cb_prefix_output => 'prefix_milter_output' }
    ];
    
    $self->{maps_counters}->{bm_milter} = [
        { label => 'connections-total', nlabel => 'milter.connections.total.count', set => {
                key_values => [ { name => 'connections', diff => 1 } ],
                output_template => 'total connections: %s',
                perfdatas => [
                    { value => 'connections', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'traffic-class-inbound', nlabel => 'milter.traffic.class.inbound.count', display_ok => 0, set => {
                key_values => [ { name => 'traffic_class_inbound', diff => 1 } ],
                output_template => 'traffic class inbound: %s',
                perfdatas => [
                    { value => 'traffic_class_inbound', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'traffic-class-outbound', nlabel => 'milter.traffic.class.outbound.count', display_ok => 0, set => {
                key_values => [ { name => 'traffic_class_outbound', diff => 1 } ],
                output_template => 'traffic class outbound: %s',
                perfdatas => [
                    { value => 'traffic_class_outbound', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'traffic-size-inbound', nlabel => 'milter.traffic.size.inbound.bytes', display_ok => 0, set => {
                key_values => [ { name => 'traffic_size_inbound', diff => 1 } ],
                output_template => 'traffic size inbound: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'traffic_size_inbound', template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'traffic-size-outbound', nlabel => 'milter.traffic.size.outbound.bytes', display_ok => 0, set => {
                key_values => [ { name => 'traffic_size_outbound', diff => 1 } ],
                output_template => 'traffic size outbound: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'traffic_size_outbound', template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'sessions-duration-total', nlabel => 'milter.sessions.duration.total.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'session_duration_total', diff => 1 } ],
                output_template => 'total sessions duration: %s ms',
                perfdatas => [
                    { value => 'session_duration_total', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'sessions-duration-mean', nlabel => 'milter.sessions.duration.mean.milliseconds', set => {
                key_values => [ { name => 'session_duration_mean' } ],
                output_template => 'mean sessions duration: %s ms',
                perfdatas => [
                    { value => 'session_duration_mean', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # bm-milter.connectionsCount,meterType=Counter count=2017123
    # bm-milter.sessionDuration,meterType=Timer count=11553431,totalTime=21943249233042775,mean=1899284224
    # bm-milter.traffic.class,type=INBOUND,meterType=Counter count=1289087
    # bm-milter.traffic.class,type=OUTBOUND,meterType=Counter count=415711
    # bm-milter.traffic.size,type=INBOUND,meterType=Counter count=29063863392
    # bm-milter.traffic.size,type=OUTBOUND,meterType=Counter count=10763275492
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-milter.sock http://127.0.0.1/metrics',
        filter => 'connectionsCount|sessionDuration|traffic\.class|traffic\.size'
    );

    $self->{bm_milter} = {};
    foreach (keys %$result) {
        $self->{bm_milter}->{'traffic_class_' . lc($1)} = $result->{$_}->{count} if (/bm-milter\.traffic\.class.*type=(INBOUND|OUTBOUND)/i);
        $self->{bm_milter}->{'traffic_size_' . lc($1)} = $result->{$_}->{count} if (/bm-milter\.traffic\.size.*type=(INBOUND|OUTBOUND)/i);
        $self->{bm_milter}->{connections} = $result->{$_}->{count} if (/bm-milter\.connectionsCount/);
        if (/bm-milter\.sessionDuration/) {
            $self->{bm_milter}->{session_duration_total} = $result->{$_}->{totalTime} / 100000;
            $self->{bm_milter}->{session_duration_mean} = $result->{$_}->{mean} / 100000;
        }
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check milter service.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^deliveries'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections-total', 'traffic-class-inbound', 'traffic-class-outbound',
'traffic-size-inbound', 'traffic-size-outbound', 'sessions-duration-total', 'sessions-duration-mean' .

=back

=cut
