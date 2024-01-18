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

package hardware::devices::pexip::infinity::managementapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_license_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub licenses_long_output {
    my ($self, %options) = @_;

    return 'checking licenses';
}

sub prefix_audio_output {
    my ($self, %options) = @_;

    return 'audio ';
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return 'port ';
}

sub prefix_vmr_output {
    my ($self, %options) = @_;

    return 'vmr ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'licenses', type => 3, cb_long_output => 'licenses_long_output', indent_long_output => '    ',
            group => [
                { name => 'audio', type => 0, display_short => 0, cb_prefix_output => 'prefix_audio_output', skipped_code => { -10 => 1 } },
                { name => 'port', type => 0, display_short => 0, cb_prefix_output => 'prefix_port_output', skipped_code => { -10 => 1 } },
                { name => 'vmr', type => 0, display_short => 0, cb_prefix_output => 'prefix_vmr_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach (('audio', 'port', 'vmr')) {
        $self->{maps_counters}->{$_} = [
            { label => 'license-' . $_ . '-usage', nlabel => 'license.' . $_ . '.usage.count', set => {
                    key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                    closure_custom_output => $self->can('custom_license_output'),
                    perfdatas => [
                        { template => '%d', min => 0, max => 'total' }
                    ]
                }
            },
            { label => 'license-'. $_ . '-free', display_ok => 0, nlabel => 'license.' . $_ . '.free.count', set => {
                    key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                    closure_custom_output => $self->can('custom_license_output'),
                    perfdatas => [
                        { template => '%d', min => 0, max => 'total' }
                    ]
                }
            },
            { label => 'license-' . $_ . '-usage-prct', display_ok => 0, nlabel => 'license.' . $_ . '.usage.percentage', set => {
                    key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                    closure_custom_output => $self->can('custom_license_output'),
                    perfdatas => [
                        { template => '%.2f', min => 0, max => 100, unit => '%' }
                    ]
                }
            }
        ];
    }
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

    my $licenses = $options{custom}->request_api(
        endpoint => '/api/admin/status/v1/licensing/'
    );

    $self->{output}->output_add(short_msg => 'Licenses are ok');

    $self->{licenses} = {
        global => {
            audio => {},
            port => {},
            vmr => {}
        }
    };

    if ($licenses->[0]->{audio_total} > 0) {
        $self->{licenses}->{global}->{audio}->{used} = $licenses->[0]->{audio_count};
        $self->{licenses}->{global}->{audio}->{total} = $licenses->[0]->{audio_total};
        $self->{licenses}->{global}->{audio}->{free} = $licenses->[0]->{audio_total} - $licenses->[0]->{audio_count};
        $self->{licenses}->{global}->{audio}->{prct_used} = $self->{licenses}->{global}->{audio}->{used} * 100 / $self->{licenses}->{global}->{audio}->{total};
        $self->{licenses}->{global}->{audio}->{prct_free} = 100 - $self->{licenses}->{global}->{audio}->{prct_used};
    }

    if ($licenses->[0]->{port_total} > 0) {
        $self->{licenses}->{global}->{port}->{used} = $licenses->[0]->{port_count};
        $self->{licenses}->{global}->{port}->{total} = $licenses->[0]->{port_total};
        $self->{licenses}->{global}->{port}->{free} = $licenses->[0]->{port_total} - $licenses->[0]->{port_count};
        $self->{licenses}->{global}->{port}->{prct_used} = $self->{licenses}->{global}->{port}->{used} * 100 / $self->{licenses}->{global}->{port}->{total};
        $self->{licenses}->{global}->{port}->{prct_free} = 100 - $self->{licenses}->{global}->{port}->{prct_used};
    }

    if ($licenses->[0]->{vmr_total} > 0) {
        $self->{licenses}->{global}->{vmr}->{used} = $licenses->[0]->{vmr_count};
        $self->{licenses}->{global}->{vmr}->{total} = $licenses->[0]->{vmr_total};
        $self->{licenses}->{global}->{vmr}->{free} = $licenses->[0]->{vmr_total} - $licenses->[0]->{vmr_count};
        $self->{licenses}->{global}->{vmr}->{prct_used} = $self->{licenses}->{global}->{vmr}->{used} * 100 / $self->{licenses}->{global}->{vmr}->{total};
        $self->{licenses}->{global}->{vmr}->{prct_free} = 100 - $self->{licenses}->{global}->{vmr}->{prct_used};
    }
}

1;

__END__

=head1 MODE

Check licenses.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='audio'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'license-port-usage', 'license-port-free', 'license-port-usage-prct',
'license-vmr-usage', 'license-vmr-free', 'license-vmr-usage-prct', 
'license-audio-usage', 'license-audio-free', 'license-audio-usage-prct'.

=back

=cut
