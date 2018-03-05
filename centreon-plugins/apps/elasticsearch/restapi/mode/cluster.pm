#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package apps::elasticsearch::restapi::mode::cluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = "Cluster '" . $self->{result_values}->{display} . "' Status : " . $self->{result_values}->{status};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'active-primary-shards', set => {
                key_values => [ { name => 'active_primary_shards' } ],
                output_template => 'Active Primary Shards : %s',
                perfdatas => [
                    { label => 'active_primary_shards', value => 'active_primary_shards_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'active-shards', set => {
                key_values => [ { name => 'active_shards' } ],
                output_template => 'Active Shards : %s',
                perfdatas => [
                    { label => 'active_shards', value => 'active_shards_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'unassigned-shards', set => {
                key_values => [ { name => 'unassigned_shards' } ],
                output_template => 'Unassigned Shards : %s',
                perfdatas => [
                    { label => 'unassigned_shards', value => 'unassigned_shards_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "elastic-path:s"      => { name => 'elastic_path', default => '/_cluster/health' },
                                  "warning-status:s"    => { name => 'warning_status', default => '%{status} =~ /yellow/i' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{status} =~ /red/i' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $result = $options{custom}->get(path => $self->{option_results}->{elastic_path});
    $self->{global} = { 
        display => $result->{cluster_name},
        status => $result->{status},
        active_primary_shards => $result->{active_primary_shards},
        active_shards => $result->{active_shards},
        unassigned_shards => $result->{unassigned_shards},
    };
}

1;

__END__

=head1 MODE

Check Elasticsearch cluster.

=over 8

=item B<--elastic-path>

Set path to get Elasticsearch information (Default: '/_cluster/health')

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-*>

Threshold warning.
Can be: 'active-primary-shards', 'active-shards', 'unassigned-shards'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-primary-shards', 'active-shards', 'unassigned-shards'.

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /yellow/i')
Can used special variables like: %{status}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /red/i').
Can used special variables like: %{status}.

=back

=cut
