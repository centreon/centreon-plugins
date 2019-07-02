#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::cisco::cms::restapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("alarm '%s' active for %s",
        $self->{result_values}->{type}, centreon::plugins::misc::change_seconds(value => $self->{result_values}->{active_time}));
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{active_time} = $options{new_datas}->{$self->{instance} . '_activeTimeSeconds'};
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'alarms', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { label => 'alerts', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];
    
    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'type' }, { name => 'activeTimeSeconds' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-type:s"           => { name => 'filter_type' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '' },
                                  "memory"                  => { name => 'memory' },
                                });
    
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alarms}->{global} = { alarm => {} };
    
    my $results = $options{custom}->get_endpoint(method => '/system/alarms');

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_cisco_cms_" . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }
    
    my ($i, $current_time) = (1, time());
    foreach my $alarm (@{$results->{alarm}}) {    
        my $create_time = $current_time - $alarm->{activeTimeSeconds};
    
        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $alarm->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alarm->{type} . "': no matching filter.", debug => 1);
            next;
        }
        
        my $diff_time = $current_time - $create_time;
        
        $self->{alarms}->{global}->{alarm}->{$i} = { %$alarm, since => $diff_time };
        $i++;
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}
        
1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--filter-type>

Filter by type (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{type}, %{active_time}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{type}, %{active_time}

=item B<--memory>

Only check new alarms.

=back

=cut
