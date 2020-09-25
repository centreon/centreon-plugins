#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::vcs::restapi::mode::calls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Date::Parse;
use Digest::MD5 qw(md5_hex);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Calls ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
         { label => 'dummy', threshold => 0, display_ok => 0, set => {
                key_values => [ { name => 'last_cdr_start_time' } ],
                output_template => 'none',
                perfdatas => []
            }
        }
    ];

    foreach ((
        ['traversal', 1, 'traversal'], ['nontraversal', 1, 'non traversal'],
        ['cloud', 1, 'cloud'], ['collaborationedge', 0, 'collaboration edge'],
        ['microsoftcontent', 0, 'microsoft content'], ['microsoftimp', 0, 'microsoft imp']
    )) {
        push @{$self->{maps_counters}->{global}},
            {
                label => $_->[0] . '-current', nlabel => 'calls.' . $_->[0] . '.current.count', display_ok => $_->[1], set => {
                    key_values => [ { name => $_->[0] . '_current' } ],
                    output_template => $_->[2] . ' current: %d',
                    perfdatas => [
                        { template => '%d', min => 0 }
                    ]
                }
            },
            {
                label => $_->[0] . '-total', nlabel => 'calls.' . $_->[0] . '.total.count', display_ok => 0, set => {
                    key_values => [ { name => $_->[0] . '_total', diff => 1 } ],
                    output_template => $_->[2] . ' total: %d',
                    perfdatas => [
                        { template => '%d', min => 0 }
                    ]
                }
            };
    }

    foreach ((
        ['connectionfailed', 1, 'connection failed'], ['disconnected', 1, 'disconnected']
    )) {
        push @{$self->{maps_counters}->{global}}, {
                label => $_->[0] . '-total', nlabel => 'calls.' . $_->[0] . '.total.count', display_ok => $_->[1], set => {
                    key_values => [ { name => $_->[0] } ],
                    output_template => $_->[2] . ': %d',
                    perfdatas => [
                        { template => '%d', min => 0 }
                    ]
                }
        };
    }
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

    $self->{cache_name} = 'cisco_vcs_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $calls = $options{custom}->get_endpoint(
        endpoint => '/getxml?location=/Status/ResourceUsage/Calls'
    );

    $self->{global} = {
        traversal_current => $calls->{ResourceUsage}->{Calls}->{Traversal}->{Current}->{content},
        traversal_total => $calls->{ResourceUsage}->{Calls}->{Traversal}->{Total}->{content},
        nontraversal_current => $calls->{ResourceUsage}->{Calls}->{NonTraversal}->{Current}->{content},
        nontraversal_total => $calls->{ResourceUsage}->{Calls}->{NonTraversal}->{Total}->{content},
        cloud_current => $calls->{ResourceUsage}->{Calls}->{Cloud}->{Current}->{content},
        cloud_total => $calls->{ResourceUsage}->{Calls}->{Cloud}->{Total}->{content},
        collaborationedge_current => $calls->{ResourceUsage}->{Calls}->{CollaborationEdge}->{Current}->{content},
        collaborationedge_total => $calls->{ResourceUsage}->{Calls}->{CollaborationEdge}->{Total}->{content},
        microsoftcontent_current => $calls->{ResourceUsage}->{Calls}->{MicrosoftContent}->{Current}->{content},
        microsoftcontent_total => $calls->{ResourceUsage}->{Calls}->{MicrosoftContent}->{Total}->{content},
        microsoftimp_current => $calls->{ResourceUsage}->{Calls}->{MicrosoftIMP}->{Current}->{content},
        microsoftimp_total => $calls->{ResourceUsage}->{Calls}->{MicrosoftIMP}->{Total}->{content},
        connectionfailed => 0,
        disconnected => 0
    };

    my $last_cdr_start_time = $self->read_statefile_key(key => 'global_last_cdr_start_time');
    $last_cdr_start_time = 0 if (!defined($last_cdr_start_time));

    my $results = $options{custom}->get_endpoint(
        endpoint => '/history.xml?location=/Calls',
        force_array => ['Call']
    );

    #<StartTime item="1">2020-09-24 12:28:52.267179</StartTime>
    my $max_start_time = $last_cdr_start_time;
    foreach my $call (@{$results->{Calls}->{Call}}) {
        my $tmp_time = Date::Parse::str2time($call->{StartTime}->{content});
        if (!defined($tmp_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "can't parse date '" . $call->{StartTime}->{content} . "'"
            );
            next;
        }

        $tmp_time = int($tmp_time * 10000);
        $max_start_time = $tmp_time if ($max_start_time < $tmp_time);
        if ($tmp_time > $last_cdr_start_time) {
            $call->{State}->{content} =~ s/\s+//g;
            $self->{global}->{ lc($call->{State}->{content}) }++
                if (defined($self->{global}->{ lc($call->{State}->{content}) }));
        }
    }

    $self->{global}->{last_cdr_start_time} = $max_start_time;
}

1;

__END__

=head1 MODE

Check current calls and history.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traversal-current', 'traversal-total',
'nontraversal-current', 'nontraversal-total',
'cloud-current', 'cloud-total', '
'collaborationedge-current', 'collaborationedge-total',
'microsoftcontent-current', 'microsoftcontent-total', 
'microsoftimp-current', 'microsoftimp-total',
'connectionfailed-total', 'disconnected-total'.

=back

=cut
