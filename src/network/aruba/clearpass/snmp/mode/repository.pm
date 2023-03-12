#
# Copyright 2023 Centreon (http://www.centreon.com/)
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
# Authors : Alexandre Moreau <alexandre.moreau@cheops.fr> (@SpyL1nk)

package network::aruba::clearpass::snmp::mode::repository;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "warning:s"         => { name => 'warning' },
        "critical:s"        => { name => 'critical' },
        "filter-name:s"     => { name => 'filter_name' },
        "filter-counter:s"  => { name => 'filter_counter' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $mapping = {
        radAuthSourceName       => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.2' },
        radAuthCounterSuccess   => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.3' },
        radAuthCounterFailure   => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.4' },
        radAuthCounterCount     => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.5' },
        radAuthCounterTime      => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.6' },
    };

    my $oid_radiusServerAuthTableEntry = '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1';

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_radiusServerAuthTableEntry,
                start => $mapping->{radAuthSourceName}->{oid},
                end => $mapping->{radAuthCounterTime}->{oid}
            },
        ],
    );

    my $authsource_count = 0;
    foreach my $oid (keys %{$snmp_result->{$oid_radiusServerAuthTableEntry}}) {
        next if ($oid !~ /^$mapping->{radAuthSourceName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_radiusServerAuthTableEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{radAuthSourceName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping authentication source '" . $result->{radAuthSourceName} . "'.", debug => 1);
            next;
        }

        $authsource_count++;
        my $exit = $self->{perfdata}->threshold_check(value => $result->{radAuthCounterTime}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "%s: total request (success/failure): %s (%s/%s) average request time: %sms",
                            $result->{radAuthSourceName},
                            $result->{radAuthCounterCount},
                            $result->{radAuthCounterSuccess},
                            $result->{radAuthCounterFailure},
                            $result->{radAuthCounterTime}
            )
        );

        if (defined($self->{option_results}->{filter_counter}) && $self->{option_results}->{filter_counter} ne '') {
            if  ("auth_total" =~ /$self->{option_results}->{filter_counter}/) {
                $self->{output}->perfdata_add(
                    label => $result->{radAuthSourceName} . "_auth_total",
                    value => $result->{radAuthCounterCount},
                    min => 0,
                );
            }

            if  ("auth_success" =~ /$self->{option_results}->{filter_counter}/) {
                $self->{output}->perfdata_add(
                    label => $result->{radAuthSourceName} . "_auth_success",
                    value => $result->{radAuthCounterSuccess},
                    min => 0,
                );
            }

            if  ("auth_failure" =~ /$self->{option_results}->{filter_counter}/) {
                $self->{output}->perfdata_add(
                    label => $result->{radAuthSourceName} . "_auth_failure",
                    value => $result->{radAuthCounterFailure},
                    min => 0,
                );
            }

            if  ("auth_time" =~ /$self->{option_results}->{filter_counter}/) {
                $self->{output}->perfdata_add(
                    label => $result->{radAuthSourceName} . "_auth_time", unit => 'ms',
                    value => $result->{radAuthCounterTime},
                    min => 0,
                );
            }
        } else {
            $self->{output}->perfdata_add(
                label => $result->{radAuthSourceName} . "_auth_total",
                value => $result->{radAuthCounterCount},
                min => 0,
            );
            $self->{output}->perfdata_add(
                label => $result->{radAuthSourceName} . "_auth_success",
                value => $result->{radAuthCounterSuccess},
                min => 0,
            );
            $self->{output}->perfdata_add(
                label => $result->{radAuthSourceName} . "_auth_failure",
                value => $result->{radAuthCounterFailure},
                min => 0,
            );
            $self->{output}->perfdata_add(
                label => $result->{radAuthSourceName} . "_auth_time", unit => 'ms',
                value => $result->{radAuthCounterTime},
                min => 0,
            );
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check ClearPass authentication repository statistics.

=over 8

=item B<--warning>

Threshold warning in miliseconds.

=item B<--critical>

Threshold critical in miliseconds.

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^cpu$'

=item B<--filter-name>

Filter authentication source name (can be a regexp).

=back

=cut