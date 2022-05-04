#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::monitoring::kadiska::mode::watcherstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Watcher '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'watchers', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All Watchers are OK' }
    ];

    $self->{maps_counters}->{watchers} = [
        { label => 'errors-prct', nlabel => 'watcher.errors.percentage', set => {
                key_values => [ { name => 'errors_prct' } ],
                output_template => 'errors: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'sessions', nlabel => 'watcher.sessions.count', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'requests', nlabel => 'watcher.requests.count', set => {
                key_values => [ { name => 'requests' } ],
                output_template => 'requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'pages', nlabel => 'watcher.pages.count', set => {
                key_values => [ { name => 'pages' } ],
                output_template => 'pages: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 },
                ],
            }
        }              
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-watcher-name:s' => { name => 'filter_watcher_name' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_form_post = {
        "select" => [
            {
                "watcher_id:group" => "watcher_name"
            },
            {
                "\%errors:avg|hits" => 
                    [
                        "*",100,["/",["sumFor","hits","error_count"],["countFor","hits"]]
                    ]                
            },
            {
                "session:sum|hits" => ["sumFor","hits","session_count"]
            },
            {
                "item:count|requests" => ["countFor","requests"]
            },
            {
                "item:count|pages" => ["countFor","pages"]
            }
        ],
        "from" => "rum",
        "groupby" => [
            "watcher_name"
        ],
        "offset" => 0,
        "options" => {"sampling" => \1 }
    };  

    if (defined($self->{option_results}->{filter_watcher_name}) && $self->{option_results}->{filter_watcher_name} ne ''){
        $raw_form_post->{where} = ["=","watcher_name",["\$", $self->{option_results}->{filter_watcher_name}]],
    }

    my $results = $options{custom}->request_api(
        method => 'POST',
        endpoint => 'query',
        query_form_post => $raw_form_post
    );

    $self->{watchers} = {};
    foreach my $watcher (@{$results->{data}}) {

        my $instance = $watcher->{'watcher_id:group'};

        $self->{watchers}->{$instance} = {
            errors_prct => $watcher->{'%errors:avg|hits'},
            sessions => $watcher->{'session:sum|hits'},
            requests => $watcher->{'item:count|requests'},
            pages => $watcher->{'item:count|pages'} 
        };
    };

    if (scalar(keys %{$self->{watchers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No instances or results found.");
        $self->{output}->option_exit();
    }

}

1;

__END__

=head1 MODE

Check Kadiska application watchers' statistics during the period specified.

=over 8

=item B<--filter-watcher-name>

Filter on an application watcher to only display related statistics.

=item B<--warning-errors-prct>

Warning threshold for web browser errors (4xx and 5xx types) in percentage.

=item B<--critical-errors-prct>

Critical threshold for web browser errors (4xx and 5xx types) in percentage.

=item B<--warning-sessions>

Warning threshold for web sessions number.

=item B<--critical-sessions>

Critical threshold for web sessions number.

=item B<--warning-request>

Warning threshold for requests number.

=item B<--critical-request>

Critical threshold for requests number.

=item B<--warning-pages>

Warning threshold for requested pages by the application.

=item B<--critical-pages>

Critical threshold for requested pages by the application.

=back

=cut
