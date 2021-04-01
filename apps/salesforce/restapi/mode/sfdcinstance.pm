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

package apps::salesforce::restapi::mode::sfdcinstance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' (active:'%s') ",
        $self->{result_values}->{status},
        $self->{result_values}->{active}
    );
}

sub prefix_salesforce_output {
    my ($self, %options) = @_;

    return "Salesforce '" . $options{instance_value}->{name} . "' instance ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'salesforce', type => 1, cb_prefix_output => 'prefix_salesforce_output', message_multiple => 'All salesforce instances are ok' }
    ];

    $self->{maps_counters}->{salesforce} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'active' }, { name => 'name' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'incident', nlabel => 'salesforce.incident.current.count', set => {
                key_values => [ { name => 'incident' } ],
                output_template => '%s incidents currently',
                perfdatas => [
                    { label => 'incident', value => 'incident', template => '%s',
                      min => 0, label_extra_instance => 1 },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'instance:s@'       => { name => 'instance' },
        'alias'             => { name => 'use_alias' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /OK/' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $instance_path = (defined($self->{option_results}->{use_alias})) ? '/instanceAliases/' : '/instances/';
 
    foreach my $instance (@{$self->{option_results}->{instance}}) {
        my $result = $options{custom}->request_api(path => $instance_path . $instance . '/status');
    
        $self->{salesforce}->{$instance} = {
            active   => $result->{isActive},
            incident => scalar(@{$result->{Incidents}}), 
            name     => $instance,
            status   => $result->{status}
        };
    }
}

1;

__END__

=head1 MODE

Check instance status and incident count through Salesforce API

=over 8

=item B<--instance>

Set your instance identifier

=item B<--alias>

Add this option if your want to use your instance alias

=item B<--unknown-status>

Set unknown threshold for instance status (Default: '').

=item B<--warning-status>

Set warning threshold for instance status (Default: '').

=item B<--critical-status>

Set critical threshold for instance status (Default: '%{status} !~ /OK/').

=back

=cut
