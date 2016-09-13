#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::hp::storeonce::restapi::mode::fcsusage;

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
    
    my $msg = 'status : ' . $self->{result_values}->{health};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{health} = $options{new_datas}->{$self->{instance} . '_health'};
    $self->{result_values}->{is_online} = $options{new_datas}->{$self->{instance} . '_is_online'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'fcs', type => 1, cb_prefix_output => 'prefix_fcs_output', message_multiple => 'All federated catalyst stores are ok' }
    ];
    
    $self->{maps_counters}->{fcs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'is_online' }, { name => 'health' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'display' } ],
                output_template => 'Used : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'used', value => 'used_absolute', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'dedup', set => {
                key_values => [ { name => 'dedup' }, { name => 'display' } ],
                output_template => 'Dedup Ratio : %.2f',
                perfdatas => [
                    { label => 'dedup_ratio', value => 'dedup_absolute', template => '%.2f', 
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'items', set => {
                key_values => [ { name => 'num_items' }, { name => 'display' } ],
                output_template => 'Num Items : %s',
                perfdatas => [
                    { label => 'items', value => 'num_items_absolute', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
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
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '%{is_online} == 1 and %{health} =~ /warning/i' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{is_online} == 1 and %{health} =~ /critical/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_fcs_output {
    my ($self, %options) = @_;
    
    return "Federated catalyst store '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %mapping_health_level = (
    0 => 'unknown',
    1 => 'ok',
    2 => 'information',
    3 => 'warning',
    4 => 'critical',
);

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{fcs} = {};
    my $result = $options{custom}->get(path => '/cluster/servicesets/*all*/teaming/services/cat/stores', ForceArray => ['store']);
    if (defined($result->{stores}->{store})) {
        foreach my $entry (@{$result->{stores}->{store}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $entry->{properties}->{name} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $entry->{properties}->{name} . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{fcs}->{$entry->{properties}->{id}} = { 
                display => $entry->{properties}->{name}, 
                health => $mapping_health_level{$entry->{properties}->{healthLevel}},
                is_online => $entry->{properties}->{isOnline} eq 'true' ? 1 : 0,
                used => $entry->{properties}->{diskBytes},
                dedup => $entry->{properties}->{dedupeRatio},
                num_items => $entry->{properties}->{numItems} };
        }
    }
    
    if (scalar(keys %{$self->{fcs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No federated catalyst store found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check federated catalyst store usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{is_online} == 1 and %{health} =~ /warning/i').
Can used special variables like: %{health}, %{is_online}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{is_online} == 1 and %{health} =~ /critical/i').
Can used special variables like: %{health}, %{is_online}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'dedup', 'items'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'dedup', 'items'.

=back

=cut
