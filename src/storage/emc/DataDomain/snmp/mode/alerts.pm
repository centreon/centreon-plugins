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

package storage::emc::DataDomain::snmp::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alerts-current', nlabel => 'alerts.current.count', set => {
                key_values => [ { name => 'current_alerts' } ],
                output_template => 'current alerts: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ]
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'display-alerts' => { name => 'display_alerts' },
        'truly-alert:s'  => { name => 'truly_alert' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{truly_alert}) || $self->{option_results}->{truly_alert} eq '') {
        $self->{option_results}->{truly_alert} = '%{severity} =~ /emergency|alert|warning|critical/i';
    }

    $self->{option_results}->{truly_alert} =~ s/%\{(.*?)\}/\$values->{$1}/g;
    $self->{option_results}->{truly_alert} =~ s/%\((.*?)\)/\$values->{$1}/g;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        timestamp   => { oid => '.1.3.6.1.4.1.19746.1.4.1.1.1.2' },
        description => { oid => '.1.3.6.1.4.1.19746.1.4.1.1.1.3' },
        severity    => { oid => '.1.3.6.1.4.1.19746.1.4.1.1.1.4' }
    };

    my $oid_currentAlertEntry = '.1.3.6.1.4.1.19746.1.4.1.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_currentAlertEntry
    );

    $self->{global} = { current_alerts => 0 };
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{timestamp}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{severity} = lc($result->{severity});

        if ($self->{output}->test_eval(
            test => $self->{option_results}->{truly_alert},
            values => $result)) {
            $self->{global}->{current_alerts}++;
        }

        if (defined($self->{option_results}->{display_alerts})) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    'alert [raised: %s] [severity: %s]: %s',
                    $result->{timestamp},
                    $result->{severity},
                    $result->{description}
                )
            );
        }
    }
}

1;

__END__

=head1 MODE

Check current alerts.

=over 8

=item B<--display-alerts>

Display alerts in verbose output.

=item B<--truly-alert>

Expression to define a truly alert (default: '%{severity} =~ /emergency|alert|warning|critical/i').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'alerts-current'.

=back

=cut
