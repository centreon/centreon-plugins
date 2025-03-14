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

package storage::purestorage::flasharray::v2::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "alert [component: %s] [severity: %s] [category: %s] [issue: %s] %s",
        $self->{result_values}->{component_name},
        $self->{result_values}->{severity}, $self->{result_values}->{category}, 
        $self->{result_values}->{issue}, centreon::plugins::misc::change_seconds(value => $self->{result_values}->{opened})
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'alerts', type => 2, message_multiple => '0 alert(s) detected', display_counter_problem => { nlabel => 'alerts.detected.count', min => 0 },
          group => [ { name => 'alert', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{alert} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{state} ne "closed" and %{severity} =~ /warning/i',
            critical_default => '%{state} ne "closed" and %{severity} =~ /critical/i',
            set => {
                key_values => [
                    { name => 'category' }, { name => 'code' },
                    { name => 'severity' }, { name => 'opened' }, { name => 'state' },
                    { name => 'component_name' }, { name => 'issue' }, { name => 'flagged' }
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
        'filter-category:s'   => { name => 'filter_category' },
        'memory'              => { name => 'memory' }
    });

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

    my $items = $options{custom}->request(endpoint => '/alerts');

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'purestorage_' . $self->{mode} . '_' . $options{custom}->get_connection_info());
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }
    
    #{
    #  "created": 1536744300846,
    #  "description": "(hardware:ct1.eth0): failure Expected: , Actual: ",
    #  "state": "closed",
    #  "component_type": "hardware",
    #  "name": "10088780",
    #  "id": "18525aa28bee4eb3a68eb901c1483fea",
    #  "category": "array",
    #  "severity": "warning",
    #  "code": 42,
    #  "flagged": false,
    #  "updated": 1536763089543,
    #  "closed": 1536763264862,
    #  "notified": null,
    #  "component_name": "ct1.eth0",
    #  "expected": "",
    #  "actual": "",
    #  "knowledge_base_url": "https://support.purestorage.com/?cid=Alert_0042",
    #  "issue": "failure",
    #  "summary": "(hardware:ct1.eth0): failure"
    #}

    $self->{alerts}->{global} = { alert => {} };

    my ($i, $current_time) = (1, time());
    foreach my $alert (@$items) {       
        $alert->{created} /= 1000;

        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $alert->{created});

        next if (defined($self->{option_results}->{filter_category}) && $self->{option_results}->{filter_category} ne '' &&
            $alert->{category} !~ /$self->{option_results}->{filter_category}/);

        my $diff_time = $current_time - $alert->{created};

        $self->{alerts}->{global}->{alert}->{$i} = { 
            %$alert,
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

Check alerts.

=over 8

=item B<--filter-category>

Filter by category name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{state} ne "closed" and %{severity} =~ /warning/i')
You can use the following variables: %{category}, %{code}, %{severity}, %{opened}, %{state}, %{issue}, %{component_name}, %{flagged}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} ne "closed" and %{severity} =~ /critical/i').
You can use the following variables: %{category}, %{code}, %{severity}, %{opened}, %{state}, %{issue}, %{component_name}, %{flagged}

=item B<--memory>

Only check new alarms.

=back

=cut
