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

package database::elasticsearch::restapi::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "License Status '%s' [type: %s] [issued to: %s] [issue date: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{issued_to},
        $self->{result_values}->{issue_date}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
         { label => 'status', type => 2, critical_default => '%{status} !~ /active/i', set => {
                key_values => [
                    { name => 'status' }, { name => 'type' }, { name => 'issued_to' },
                    { name => 'issue_date' }, { name => 'expiry_date_in_seconds' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
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

    my $result = $options{custom}->get(path => '/_license');

    $self->{global} = { 
        type => $result->{license}->{type},
        status => $result->{license}->{status},
        issued_to => $result->{license}->{issued_to},
        issue_date => $result->{license}->{issue_date},
        expiry_date_in_seconds => int($result->{license}->{expiry_date_in_millis} / 1000)
    };
}

1;

__END__

=head1 MODE

Check license.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{type}, %{issued_to}, %{expiry_date_in_seconds}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /active/i').
Can used special variables like: %{status}, %{type}, %{issued_to}, %{expiry_date_in_seconds}.

=back

=cut
