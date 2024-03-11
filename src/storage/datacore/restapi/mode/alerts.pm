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
package storage::datacore::restapi::mode::alerts;
use strict;
use warnings;
use centreon::plugins::misc qw(empty);

use base qw(centreon::plugins::templates::counter);

my %alerts_level = ('trace' => 0, 'info' => 1, 'warning' => 2, 'error' => 3);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alerts', type => 0},
    ];
    $self->{maps_counters}->{alerts} = [
        {
            label  => 'error',
            nlabel => 'datacore.event.error.count',
            set    => {
                key_values      => [ { name => 'error' } ],
                output_template => 'number of error alerts : %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }, {
        label  => 'warning',
        nlabel => 'datacore.alerts.warning.count',
        set    => {
            key_values      => [ { name => 'warning' } ],
            output_template => 'number of warning alerts : %s',
            perfdatas       => [ { template => '%d', min => 0 } ]
        }
    }, {
        label  => 'info',
        nlabel => 'datacore.alerts.info.count',
        set    => {
            key_values      => [ { name => 'info' } ],
            output_template => 'number of info alerts : %s',
            perfdatas       => [ { template => '%d', min => 0 } ]
        }
    }, {
        label  => 'trace',
        nlabel => 'datacore.alerts.trace.count',
        set    => {
            key_values      => [ { name => 'trace' } ],
            output_template => 'number of trace alerts : %s',
            perfdatas       => [ { template => '%d', min => 0 } ]
        }
    },
    ];

}

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    $options{options}->add_options(arguments => {
        'filter-server:s' => { name => 'filter_server' },
        'max-alert-age:s' => { name => 'max_alert_age' } });

    $self->{output} = $options{output};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $alerts = $options{custom}->request_api(
        url_path => '/RestService/rest.svc/1.0/alerts'
    );

    my %alerts_count = (
        0 => { count => 0, list => [] },
        1 => { count => 0, list => [] },
        2 => { count => 0, list => [] },
        3 => { count => 0, list => [] });

    for my $alert (@$alerts) {

        # spec require to filter on time of the log.
        $alert->{TimeStamp} =~ /\/Date\((\d+)\)\/$/;
        my $alert_date = $1;
        if (centreon::plugins::misc::is_empty($alert_date) or $alert_date !~ /^[0-9]*[.,]?\d*$/){
            $self->{output}->output_add(long_msg => "alert on $alert->{MachineName} have an invalid date : $alert->{TimeStamp}\n", debug => 1);
            next;
        }

        # filter on age of the alert with a user defined max age
        next if (defined($self->{option_results}->{max_alert_age})
            and $alert_date < (time - $self->{option_results}->{max_alert_age}) * 1000);
        # filter on the machine issuing the alert with a user defined regex

        if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_server})
            and $alert->{MachineName} !~ $self->{option_results}->{filter_server}) {
            $self->{output}->output_add(long_msg => "excluding alert from machine $alert->{MachineName}\n", debug => 1);
            next;
        }

        $alerts_count{$alert->{Level}}->{count}++;
        # we don't want to clog the long output, so we keep only the few first logs.
        # we use a array instead of directly adding to long_output because we need to sort errors
        if (scalar(@{$alerts_count{$alert->{Level}}->{list}}) < 50) {
            push(@{$alerts_count{$alert->{Level}}->{list}}, $alert->{MessageText})
        }
    }

    $self->{output}->output_add(long_msg => "error : " . join("\n", @{$alerts_count{$alerts_level{error}}->{list}}));
    $self->{output}->output_add(long_msg => "warning : " . join("\n", @{$alerts_count{$alerts_level{warning}}->{list}}));



    $self->{alerts} = {
        trace   => $alerts_count{$alerts_level{trace}}->{count},
        info    => $alerts_count{$alerts_level{info}}->{count},
        warning => $alerts_count{$alerts_level{warning}}->{count},
        error   => $alerts_count{$alerts_level{error}}->{count},
    };

}

1;

__END__

=head1 MODE

Check Datacore alerts number exposed through the rest api

=over 8

=item B<--max-alert-age>

filter alerts to check those newer than this parameter (s)

=item B<--filter-server>

Define which devices should be monitored based on the MachineName. This option will be treated as a regular expression.
By default all machine will be checked.

=item B<--warning/critical-*>

Warning and critical threshold on the number of alerts of a type before changing state.
Replace * with trace, alert, warning, or error.

=back


