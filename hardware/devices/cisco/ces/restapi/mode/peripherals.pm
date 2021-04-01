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

package hardware::devices::cisco::ces::restapi::mode::peripherals;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'peripherals-connected', nlabel => 'system.peripherals.connected.count', set => {
                key_values => [ { name => 'connected' } ],
                output_template => 'peripherals connected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
         'filter-since:s' => { name => 'filter_since', default => 86400 }
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'POST',
        url_path => '/putxml',
        query_form_post => '<Command><Peripherals><List/></Peripherals></Command>',
        ForceArray => ['Device']
    );

    $self->{global} = { connected => 0 };

    return if (!defined($result->{PeripheralsListResult}->{Device}));

    foreach (@{$result->{PeripheralsListResult}->{Device}}) {
        if (defined($self->{option_results}->{filter_since}) && $self->{option_results}->{filter_since} =~ /\d+/) {
            my $last_seen = Date::Parse::str2time($_->{LastSeen});
            if (!defined($last_seen)) {
                $self->{output}->output_add(
                    severity => 'UNKNOWN',
                    short_msg => "can't parse date '" . $_->{LastSeen} . "'"
                );
                next;
            }
            next if ($last_seen < time() - $self->{option_results}->{filter_since});
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                'peripheral [name: %s] [Last Seen: %s] [NetworkAddress: %s] [SerialNumber: %s]',
                $_->{Name},
                $_->{LastSeen},
                $_->{NetworkAddress},
                $_->{SerialNumber}
            )
        );
        $self->{global}->{connected}++;
    }
}

1;

__END__

=head1 MODE

Check peripherals device connected (since TC 7.2).

=over 8

=item B<--filter-since>

Filter by since X seconds (Default: 86400).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'peripherals-connected'.

=back

=cut
