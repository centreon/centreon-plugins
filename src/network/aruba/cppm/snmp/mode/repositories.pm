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

package network::aruba::cppm::snmp::mode::repositories;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_repository_output {
    my ($self, %options) = @_;

    return "Authentication repository '" . $options{instance}. "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'repositories', type => 1, cb_prefix_output => 'prefix_repository_output', message_multiple => 'All authentication repositories are ok' }
    ];

    $self->{maps_counters}->{repositories} = [
        { label => 'requests-time', nlabel => 'authentication_repository.requests.milliseconds', set => {
                key_values => [ { name => 'timeReq' } ],
                output_template => 'requests time: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'requests', nlabel => 'authentication_repository.requests.count', set => {
                key_values => [ { name => 'totalReq' } ],
                output_template => 'total requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'requests-failed', nlabel => 'authentication_repository.requests.failed.count', set => {
                key_values => [ { name => 'failedReq' } ],
                output_template => 'failed requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'requests-succeeded', nlabel => 'authentication_repository.requests.succeeded.count', set => {
                key_values => [ { name => 'successReq' } ],
                output_template => 'succeeded requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        sourceName => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.2' }, # radAuthSourceName
        successReq => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.3' }, # radAuthCounterSuccess
        failedReq  => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.4' }, # radAuthCounterFailure
        totalReq   => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.5' }, # radAuthCounterCount
        timeReq    => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1.6' }  # radAuthCounterTime
    };
    my $oid_authEntry = '.1.3.6.1.4.1.14823.1.6.1.1.2.2.1';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_authEntry,
        nothing_quit => 1
    );

    $self->{repositories} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{sourceName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sourceName} !~ /$self->{option_results}->{filter_name}/);

        $self->{repositories}->{ $result->{sourceName} } = $result;
    }
}

1;

__END__

=head1 MODE

Check ClearPass authentication repository statistics.

=over 8

=item B<--filter-name>

Filter authentification repositories by system hostname (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'requests-time', 'requests', 'requests-failed',
'requests-succeeded'.

=back

=cut
