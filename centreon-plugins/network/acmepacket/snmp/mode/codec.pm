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

package network::acmepacket::snmp::mode::codec;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_resources_output {
    my ($self, %options) = @_;

    return sprintf(
        'resources usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used}, $self->{result_values}->{prct_used},
        $self->{result_values}->{free}, $self->{result_values}->{prct_free}
    );
}

sub codec_long_output {
    my ($self, %options) = @_;

    return 'checking codec transcoding';
}

sub prefix_codec_output {
    my ($self, %options) = @_;
    
    return 'Codec transcoding ';
}

sub prefix_sessions_output {
    my ($self, %options) = @_;

    return 'sessions ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'codec', type => 3, cb_prefix_output => 'prefix_codec_output', cb_long_output => 'codec_long_output', indent_long_output => '    ', message_multiple => 'All server pools are ok',
            group => [
                { name => 'sessions', type => 0, display_short => 0, cb_prefix_output => 'prefix_sessions_output' },
                { name => 'resources', type => 0, display_short => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{sessions} = [
        { label => 'sessions-active', nlabel => 'transcoding.sessions.active.count', set => {
                key_values => [ { name => 'sessions_active' } ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{resources} = [
        { label => 'resources-usage', nlabel => 'transcoding.resources.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_resources_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'resources-usage-free', nlabel => 'transcoding.resources.free.count', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_resources_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'resources-usage-prct', nlabel => 'transcoding.resources.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_resources_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
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
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

     my $mapping = {
        resources_total   => { oid => '.1.3.6.1.4.1.9148.3.7.2.2.1' }, # apCodecTranscodingResourcesTotal
        resources_used    => { oid => '.1.3.6.1.4.1.9148.3.7.2.2.2' }, # apCodecTranscodingResourcesCurrent
        sessions_active   => { oid => '.1.3.6.1.4.1.9148.3.7.2.5.1' }  # apCodecTranscodingLicensedTotalSessions
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => 'Codec transcoding is ok');

    $self->{codec} = {
        global => {
            sessions => { sessions_active => $result->{sessions_active} },
            resources => {
                total => $result->{resources_total},
                used => $result->{resources_used},
                free => $result->{resources_total} - $result->{resources_used},
                prct_used => $result->{resources_used} * 100 / $result->{resources_total},
                prct_free => 100 - ($result->{resources_used} * 100 / $result->{resources_total})
            }
        }
    };
}

1;

__END__

=head1 MODE

Check codec transcoding.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory-usage$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sessions-active', 
'resources-usage', 'resources-usage-free', 'resources-usage-prct'.

=back

=cut
