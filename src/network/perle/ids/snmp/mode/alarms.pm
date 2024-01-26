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

package network::perle::ids::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("alarm [severity: %s] [source: %s] [text: %s] %s", $self->{result_values}->{severity},
        $self->{result_values}->{source}, $self->{result_values}->{text}, $self->{result_values}->{generation_time});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{source} = $options{new_datas}->{$self->{instance} . '_perleEntityAlarmSourceName'};
    $self->{result_values}->{text} = $options{new_datas}->{$self->{instance} . '_perleEntityAlarmDescr'};
    $self->{result_values}->{severity} = $options{new_datas}->{$self->{instance} . '_perleEntityAlarmSeverity'};
    $self->{result_values}->{since} = $options{new_datas}->{$self->{instance} . '_since'};
    $self->{result_values}->{generation_time} = $options{new_datas}->{$self->{instance} . '_perleEntityAlarmTimeStamp'};
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
                key_values => [ { name => 'perleEntityAlarmDescr' }, { name => 'perleEntityAlarmSeverity' }, { name => 'perleEntityAlarmTimeStamp' },
                    { name => 'since' }, { name => 'perleEntityAlarmSourceName' }, { name => 'perleEntityAlarmType' } ],
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
    
    $options{options}->add_options(arguments => {
        'filter-msg:s'        => { name => 'filter_msg' },
        'warning-status:s'    => { name => 'warning_status', default => '%{severity} =~ /minor/i' },
        'critical-status:s'   => { name => 'critical_status', default => '%{severity} =~ /critical|major/i' },
        'memory'              => { name => 'memory' },
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

my %map_severity = (
    1 => 'critical',
    2 => 'major',
    3 => 'minor',
    4 => 'info',
);

my $mapping = {
    perleEntityAlarmSourceName  => { oid => '.1.3.6.1.4.1.1966.22.11.1.1.1.3' },
    perleEntityAlarmSeverity    => { oid => '.1.3.6.1.4.1.1966.22.11.1.1.1.4', map => \%map_severity },
    perleEntityAlarmDescr       => { oid => '.1.3.6.1.4.1.1966.22.11.1.1.1.5' },
    perleEntityAlarmTimeStamp   => { oid => '.1.3.6.1.4.1.1966.22.11.1.1.1.6' },
};
my $oid_perleEntityAlarmEntry = '.1.3.6.1.4.1.1966.22.11.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alarms}->{global} = { alarm => {} };
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_perleEntityAlarmEntry,
        start => $mapping->{perleEntityAlarmSourceName}->{oid},
        end => $mapping->{perleEntityAlarmDescr}->{oid}
    );

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_perle_ids_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{perleEntityAlarmSeverity}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        my $create_time = $result->{perleEntityAlarmTimeStamp};
        $result->{perleEntityAlarmTimeStamp} = strftime("%d/%m/%Y %H:%M:%S", localtime($result->{perleEntityAlarmTimeStamp}));
        if (!defined($create_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "Can't get date '" . $create_time . "'"
            );
            next;
        }
        
        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);
        if (defined($self->{option_results}->{filter_msg}) && $self->{option_results}->{filter_msg} ne '' &&
            $result->{perleEntityAlarmDescr} !~ /$self->{option_results}->{filter_msg}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{perleEntityAlarmDescr} . "': no matching filter.", debug => 1);
            next;
        }
        
        my $diff_time = $current_time - $create_time;
        $self->{alarms}->{global}->{alarm}->{$i} = { %$result, since => $diff_time };
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

=item B<--filter-msg>

Filter by message (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{severity} =~ /minor/i')
You can use the following variables: %{severity}, %{text}, %{source}, %{since}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{severity} =~ /critical|major/i').
You can use the following variables: %{severity}, %{text}, %{source}, %{since}

=item B<--memory>

Only check new alarms.

=back

=cut
