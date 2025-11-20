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

package network::mikrotik::snmp::mode::lte;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Current operator '%s' IMSI: '%s' ICCID: '%s'",
        $self->{result_values}->{current_operator},
        $self->{result_values}->{imsi},
        $self->{result_values}->{iccid}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, set => {
                key_values => [
                    { name => 'current_operator' }, { name => 'imsi' },
                    { name => 'iccid' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $lte_values = {
        'lte-current-operator' => '',
        'lte-imsi'             => '',
        'lte-iccid'            => '' 
    };

    my $mtxrScriptName = '.1.3.6.1.4.1.14988.1.1.8.1.1.2'; # mtxrScriptName
    my $mtxrScriptRunOutput = '.1.3.6.1.4.1.14988.1.1.18.1.1.2'; # mtxrScriptRunOutput
    my $mtxrScrip_results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mtxrScriptName },
            { oid => $mtxrScriptRunOutput },
        ],
        nothing_quit => 1
    );
    
    my ($instance, $result, $result2);

    foreach my $oid (keys %{$mtxrScrip_results->{$mtxrScriptName}}) {
        for my $key (keys %{$lte_values}) {
            if ($mtxrScrip_results->{$mtxrScriptName}->{$oid} eq $key) {
                $oid =~ /\.(\d+)$/;
                $lte_values->{$key} = $mtxrScrip_results->{$mtxrScriptRunOutput}->{$mtxrScriptRunOutput . "." . $1};
            }
        }
    }

    $self->{global} = {
        current_operator => $lte_values->{"lte-current-operator"},
        imsi             => $lte_values->{"lte-imsi"},
        iccid            => $lte_values->{"lte-iccid"}
    };
}

1;

__END__

=head1 MODE

Check LTE information.

=over 8

=item B<--warning-status --critical-status>

Define the conditions to match for the status to be WARNING or CRITICAL.
You can use the following variables: C<%{current_operator}>, C<%{imsi}>, C<%{iccid}>.

=back

=cut
