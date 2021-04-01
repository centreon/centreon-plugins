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

package apps::toshiba::storemate::sql::mode::maintenanceplan;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use DateTime;

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("alarm [workstation: %s] [text: %s] %s", $self->{result_values}->{workstation_id},
        $self->{result_values}->{description}, $self->{result_values}->{generation_time});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{description} = $options{new_datas}->{$self->{instance} . '_description'};
    $self->{result_values}->{workstation_id} = $options{new_datas}->{$self->{instance} . '_workstation_id'};
    $self->{result_values}->{since} = $options{new_datas}->{$self->{instance} . '_since'};
    $self->{result_values}->{generation_time} = $options{new_datas}->{$self->{instance} . '_generation_time'};
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
                key_values => [ { name => 'description' }, { name => 'workstation_id' }, { name => 'since' }, { name => 'generation_time' } ],
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
                                  "database:s"          => { name => 'database', default => 'Framework' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '1 == 1' },
                                  "memory"              => { name => 'memory' },
                                  "timezone:s"          => { name => 'timezone' },
                                });
    
    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'DateTime',
                                           error_msg => "Cannot load module 'DateTime'.");
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
    
    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{sql}->query(query => "SELECT CONVERT(varchar, LOGDATE, 120) as LOGDATE, WORKSTATION_ID, USER_ID, DESCRIPTION, DESCRIPTION_PARAMETERS
        FROM " . $self->{option_results}->{database} . ".dbo.log
        WHERE (TYPE <> 1) AND (DESCRIPTION_PARAMETERS LIKE N'\%FO\%') AND (TASKNAME = 'FOCleanup')");
    $self->{alarms}->{global} = { alarm => {} };
    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_toshiba_storemate_' . $self->{mode} . '_' . $self->{sql}->get_unique_id4save());
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }
    
    my ($i, $current_time) = (1, time());
    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    while (my $row = $self->{sql}->fetchrow_hashref()) {
        # date form: 2017-09-22 01:01:08.133
        $row->{LOGDATE} =~ /^(\d+)-(\d+)-(\d+)\s+(\d+)[:\/](\d+)[:\/](\d+)/;
        
        my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6,
                               %$tz);

        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $dt->epoch);

        my $diff_time = $current_time - $dt->epoch;

        $self->{alarms}->{global}->{alarm}->{$i} = {
            description => $row->{DESCRIPTION},
            workstation_id => $row->{WORKSTATION_ID},
            since => $diff_time, generation_time => centreon::plugins::misc::change_seconds(value => $diff_time)
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

Check the maintenance plan error logs.

=over 8

=item B<--database>

Database name (default: 'Framework').

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{description}, %{workstation_id}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '1 == 1'. We match all errors).
Can used special variables like: %{description}, %{workstation_id}, %{since}

=item B<--timezone>

Timezone of time options. Default is 'GMT'.

=item B<--memory>

Only check new alarms.

=back

=cut

