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

package apps::monitoring::logs::mode::parse;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::logs::read;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_logs_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Log message: '%s'", $self->{result_values}->{message});

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'logs', type => 2, display_counter_problem => { nlabel => 'logs.problem.count', min => 0 },
          group => [ { name => 'log', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'logs-total', nlabel => 'logs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of logs: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{log} = [
        { label => 'status', type => 2, set => {
                key_values => [ { name => 'message' } ],
                closure_custom_output => $self->can('custom_logs_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "parse-regexp:s"    => { name => 'parse_regexp' },
        "parse-mapping:s@"  => { name => 'parse_mapping' },
        "date-regexp:s"     => { name => 'date_regexp' },
        "date-mapping:s@"   => { name => 'date_mapping' },
        "memory"            => { name => 'memory' },
        "timezone:s"        => { name => 'timezone' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
    
    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $last_time = 0;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_logs_' . $options{custom}->get_uuid());
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    $self->{logs}->{global} = { log => {} };

    my $data = centreon::common::monitoring::logs::read::parse(
        %options,
        parse_regexp => $self->{option_results}->{parse_regexp},
        parse_mapping => $self->{option_results}->{parse_mapping},
        date_regexp => $self->{option_results}->{date_regexp},
        date_mapping => $self->{option_results}->{date_mapping},
        timezone => $self->{option_results}->{timezone}
    );

    my ($i, $current_time) = (1, time());

    foreach my $log (@{$data}) {        
        next if (defined($self->{option_results}->{memory}) &&
            defined($log->{date_parsed}->{timestamp}) && $last_time > $log->{date_parsed}->{timestamp});

        $self->{logs}->{global}->{log}->{$i}->{message} = $log->{message};
        $i++;
    }

    $self->{global} = { total => scalar(keys %{$self->{logs}->{global}->{log}}) };
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}

1;

__END__

=head1 MODE

Parse logs.

To use thresholds, you need to map at least a message key.

Example:

perl centreon_plugins.pl --plugin=apps::monitoring::logs::plugin --mode=parse
--custommode=file --file='/var/log/centreon-broker/central-broker-master.log'
--parse-regexp='\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}).*\]\s\[(.*)\]\s\[(.*)\]\s(.*)'
--parse-mapping='date=$1' --parse-mapping='module=$2' --parse-mapping='level=$3'
--parse-mapping='message=$4'
--date-regexp='(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})' 
--date-mapping='year=$1' --date-mapping='month=$2' --date-mapping='day=$3'
--date-mapping='hour=$4' --date-mapping='minute=$5' --date-mapping='second=$6'
--critical-status='%{message} =~ /Duplicate entry/'

=over 8

=item B<--parse-regexp>

Regexp to parse each log.

=item B<--parse-mapping>

Define mapping between variables and captured groups index.

=item B<--date-regexp>

Regexp to parse date retrieve from log parsing.

=item B<--date-mapping>

Define mapping between keys and captured groups index for each part of
date/time.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING
You can use the following variables: %{message}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL
You can use the following variables: %{message}

=item B<--timezone>

Timezone if parsing date. Default is 'GMT'.

=item B<--memory>

Only check new logs (based on last timestamp if date is captured).

=back

=cut
