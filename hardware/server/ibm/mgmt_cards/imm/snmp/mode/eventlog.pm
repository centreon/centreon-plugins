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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::eventlog;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("alarm [severity: %s] [text: %s] %s", $self->{result_values}->{severity},
        $self->{result_values}->{text}, $self->{result_values}->{generation_time});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{text} = $options{new_datas}->{$self->{instance} . '_eventLogString'};
    $self->{result_values}->{severity} = $options{new_datas}->{$self->{instance} . '_eventLogSeverity'};
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
                key_values => [ { name => 'eventLogSeverity' }, { name => 'eventLogString' }, { name => 'since' }, { name => 'generation_time' } ],
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
                                  "warning-status:s"    => { name => 'warning_status', default => '%{severity} =~ /warning/i' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{severity} =~ /error/i' },
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

my %map_severity = (0 => 'error', 1 => 'warning', 2 => 'information', 3 => 'other');

my $mapping = {
    eventLogString          => { oid => '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.2' },
    eventLogSeverity        => { oid => '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.3', map => \%map_severity },
    eventLogDate            => { oid => '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.4' }, # Month/Day/YEAR
    eventLogTime            => { oid => '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.5' },
};
my $oid_eventLogEntry = '.1.3.6.1.4.1.2.3.51.3.2.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alarms}->{global} = { alarm => {} };
    my $snmp_result = $options{snmp}->get_table(oid => $oid_eventLogEntry, nothing_quit => 1);
    
    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_imm_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{eventLogSeverity}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        my $date = $result->{eventLogDate} . ' ' . $result->{eventLogTime};
        $date =~ /^(\d+)\/(\d+)\/(\d+)\s+(\d+)[:\/](\d+)[:\/](\d+)/;

        my $dt = DateTime->new(year => $3, month => $1, day => $2, hour => $4, minute => $5, second => $6, %$tz);

        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $dt->epoch);

        my $diff_time = $current_time - $dt->epoch;

        $self->{alarms}->{global}->{alarm}->{$i} = { %$result, since => $diff_time, generation_time => centreon::plugins::misc::change_seconds(value => $diff_time) };
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

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /warning/i')
Can used special variables like: %{severity}, %{text}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /error/i').
Can used special variables like: %{severity}, %{text}, %{since}

=item B<--timezone>

Timezone of time options. Default is 'GMT'.

=item B<--memory>

Only check new alarms.

=back

=cut
