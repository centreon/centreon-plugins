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

package apps::monitoring::splunk::mode::splunkdhealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub features_long_output {
    my ($self, %options) = @_;

    return 'checking features';
}

sub custom_status_output {
    my ($self, %options) = @_;

    return "Feature '". $self->{result_values}->{display} . "'" . " health: '" . $self->{result_values}->{status} . "'";
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'features', type => 3, cb_long_output => 'features_long_output', indent_long_output => '    ',
            group => [
                { name => 'file-monitor-input', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'index-processor', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'resource-usage', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'search-scheduler', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'workload-management', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach ('file-monitor-input', 'index-processor', 'resource-usage', 'search-scheduler', 'workload-management') {
        $self->{maps_counters}->{$_} = [
            {
                label => $_ . '-status', type => 2, 
                critical_default => '%{status} =~ /red/' , 
                warning_default => '%{status} =~ /yellow/', 
                unknown_default => '%{status} !~ /(green|yellow|red)/', 
                set => {
                    key_values => [ { name => 'status' }, { name => 'display' }],
                    closure_custom_output => $self->can('custom_status_output'),
                    closure_custom_perfdata => sub { return 0; },
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
            }
        ];
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

}

sub manage_selection {
    my ($self, %options) = @_;

    my $splunkd_health_details = $options{custom}->get_splunkd_health();

    foreach my $feature (@{$splunkd_health_details}){
        $self->{features}->{global}->{ $feature->{feature_name} } = { 
                display => $feature->{feature_name},
                status => $feature->{global_health}
        };
    }
    
    $self->{output}->output_add(severity => 'OK', short_msg => 'All features are OK.');
}

1;

__END__

=head1 MODE

Check the overall health of splunkd. The health of splunkd is based on the health of all features reporting it.

=over 8

=item B<--warning-*> 

Warning thresholds for features status. (default: '%{status} =~ /yellow/').

Can be: 'file-monitor-input-status', 'index-processor-status', 
'resource-usage-status', 'search-scheduler-status', 'workload-management-status'

=item B<--critical-*>

Critical thresholds for features status. (default: '%{status} =~ /red/').

Can be: 'file-monitor-input-status', 'index-processor-status', 
'resource-usage-status', 'search-scheduler-status', 'workload-management-status'

=back

=cut
