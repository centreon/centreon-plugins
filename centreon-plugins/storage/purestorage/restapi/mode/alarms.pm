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

package storage::purestorage::restapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "alarm [component: %s] [severity: %s] [category: %s] [event: %s] %s",
        $self->{result_values}->{component_name},
        $self->{result_values}->{severity}, $self->{result_values}->{category}, 
        $self->{result_values}->{event}, centreon::plugins::misc::change_seconds(value => $self->{result_values}->{opened})
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{category} = $options{new_datas}->{$self->{instance} . '_category'};
    $self->{result_values}->{code} = $options{new_datas}->{$self->{instance} . '_code'};
    $self->{result_values}->{severity} = $options{new_datas}->{$self->{instance} . '_current_severity'};
    $self->{result_values}->{component_name} = $options{new_datas}->{$self->{instance} . '_component_name'};
    $self->{result_values}->{opened} = $options{new_datas}->{$self->{instance} . '_opened'};
    $self->{result_values}->{event} = $options{new_datas}->{$self->{instance} . '_event'};
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
        {
            label => 'status',
            type => 2,
            warning_default => '%{severity} =~ /warning/i',
            critical_default => '%{severity} =~ /critical/i',
            set => {
                key_values => [ { name => 'category' }, { name => 'code' }, { name => 'current_severity' }, { name => 'opened' }, { name => 'event' }, { name => 'component_name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-category:s"   => { name => 'filter_category' },
        "memory"              => { name => 'memory' }
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    # recent boolean:
    #   Lists recent messages. An audit record is considered recent if it relates to a command issued within the past 24 hours.
    #   An alert is considered recent if the situation that triggered it is unresolved, or has only been resolved within the past 24 hours.
    #   A user session log event is considered recent if the login, logout, or authentication event occurred within the past 24 hours
    my $alarm_results = $options{custom}->get_object(path => '/message?recent=true');

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_purestorage_' . $self->{mode} . '_' . $options{custom}->get_connection_infos());
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }
    
    #[
    # {"category": "hardware", "code": 39, "actual": "2", "opened": "2017-11-27T11:32:51Z", "component_type": "hardware", "event": "Fibre Channel link failure", "current_severity": "warning", "details": "", "expected": null, "id": 10088813, "component_name": "ct1.fc3"},
    # ...
    #

    $self->{alarms}->{global} = { alarm => {} };

    my ($i, $current_time) = (1, time());
    foreach my $alarm (@{$alarm_results}) {        
        my $create_time = Date::Parse::str2time($alarm->{opened});
        if (!defined($create_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "Can't Parse date '" . $alarm->{opened} . "'"
            );
            next;
        }
        
        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);
        if (defined($self->{option_results}->{filter_category}) && $self->{option_results}->{filter_category} ne '' &&
            $alarm->{category} !~ /$self->{option_results}->{filter_category}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alarm->{category} . "': no matching filter.", debug => 1);
            next;
        }

        my $diff_time = $current_time - $create_time;

        $self->{alarms}->{global}->{alarm}->{$i} = { 
            %$alarm,
            opened => $diff_time
        };
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

=item B<--filter-category>

Filter by category name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /warning/i')
Can used special variables like: %{category}, %{code}, %{severity}, %{opened}, %{event}, %{component_name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /critical/i').
Can used special variables like: %{category}, %{code}, %{severity}, %{opened}, %{event}, %{component_name}

=item B<--memory>

Only check new alarms.

=back

=cut
