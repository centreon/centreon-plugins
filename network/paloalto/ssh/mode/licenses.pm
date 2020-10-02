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

package network::paloalto::ssh::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("expired status is '%s'", $self->{result_values}->{expired});
    if ($self->{result_values}->{expiry_date} eq '') {
        $msg .= ', never expires';
    } else {
        $msg .= sprintf(
            ", expires in %d days [%s]",
            $self->{result_values}->{expiry_days},
            $self->{result_values}->{expiry_date}
        );
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{feature} = $options{new_datas}->{$self->{instance} . '_feature'};
    $self->{result_values}->{expired} = $options{new_datas}->{$self->{instance} . '_expired'};
    $self->{result_values}->{expiry_date} = $options{new_datas}->{$self->{instance} . '_expiry_date'};
    $self->{result_values}->{expiry_seconds} = $options{new_datas}->{$self->{instance} . '_expiry_seconds'};
    $self->{result_values}->{expiry_days} = ($self->{result_values}->{expiry_seconds} ne '') ? $self->{result_values}->{expiry_seconds} / 86400 : 0;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'features', type => 1, cb_prefix_output => 'prefix_feature_output', message_multiple => 'All features licensing are ok' },
    ];

    $self->{maps_counters}->{features} = [
        { label => 'status', type => 2, critical_default => '%{expired} eq "yes"', set => {
                key_values => [ { name => 'feature' }, { name => 'expired' }, { name => 'expiry_date' }, { name => 'expiry_seconds' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub prefix_feature_output {
    my ($self, %options) = @_;

    return "Feature '" . $options{instance_value}->{feature} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(command => 'request license info', ForceArray => ['entry']);

    my $months = {
        january => 1, february => 2, march => 3, april => 4, may => 5, june => 6, 
        july => 7, august => 8, september => 9, october => 10, november => 11, december => 12
    };

    $self->{features} = {};
    foreach my $feature (@{$result->{licenses}->{entry}}) {
        $feature->{expires} = lc($feature->{expires});

        # January 30, 2022
        my $dt;
        if ($feature->{expires} =~ /^(\w+)\s+(\d+).*?(\d+)$/) {
            $dt = DateTime->new(year => $3, month => $months->{$1}, day => $2);
        }

        $self->{features}->{$feature->{feature}} = {
            feature => $feature->{feature},
            expired => $feature->{expired},
            expiry_date => $feature->{expires} ne 'never' ? $feature->{expires} : '',
            expiry_seconds => $feature->{expires} ne 'never' ?  $dt->epoch - time() : ''
        };
    }

    if (scalar(keys %{$self->{features}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No features found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check features licensing.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{expired}, %{expiry_days}, %{feature}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{expired} eq "yes"').
Can use special variables like: %{expired}, %{expiry_days}, %{feature}

=back

=cut
