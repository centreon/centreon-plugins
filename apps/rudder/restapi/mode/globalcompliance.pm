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

package apps::rudder::restapi::mode::globalcompliance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'value',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{detail} : undef,
        value => $self->{result_values}->{value},
        min => 0, max => 100, unit => '%'
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("value is '%.2f%%'", $self->{result_values}->{value});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{detail} = $options{new_datas}->{$self->{instance} . '_detail'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'compliances', type => 1, cb_prefix_output => 'prefix_compliances_output',
            message_multiple => 'All compliance details are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'global-compliance', set => {
                key_values => [ { name => 'compliance' } ],
                output_template => 'Global Compliance: %.2f%%',
                perfdatas => [
                    { label => 'global_compliance', value => 'compliance', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{compliances} = [
        { label => 'status', set => {
                key_values => [ { name => 'value' }, { name => 'detail' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_compliances_output {
    my ($self, %options) = @_;

    return "Compliance Detail '" . $options{instance_value}->{detail} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{compliances} = {};

    my $results = $options{custom}->request_api(url_path => '/compliance');

    $self->{global}->{compliance} = $results->{globalCompliance}->{compliance};
    
    foreach my $detail (keys %{$results->{globalCompliance}->{complianceDetails}}) {
        $self->{compliances}->{$detail} = {
            detail => $detail,
            value => $results->{globalCompliance}->{complianceDetails}->{$detail},
        }            
    }
}

1;

__END__

=head1 MODE

Check global compliance and compliance details.

=over 8

=item B<--warning-global-compliance>

Set warning threshold on global compliance.

=item B<--critical-global-compliance>

Set critical threshold on global compliance.

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{detail}, %{value}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{detail}, %{value}

Example :
  --critical-status='%{detail} eq "error" && %{value} > 5'

=back

=cut
