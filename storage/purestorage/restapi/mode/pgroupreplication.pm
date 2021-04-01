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

package storage::purestorage::restapi::mode::pgroupreplication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pgroup', type => 1, cb_prefix_output => 'prefix_pgroup_output', message_multiple => 'All protection groups replication are ok' },
    ];
    
    $self->{maps_counters}->{pgroup} = [
        { label => 'progress', set => {
                key_values => [ { name => 'progress' }, { name => 'display' } ],
                output_template => 'Progress : %s %%',
                perfdatas => [
                    { label => 'progress', value => 'progress', template => '%s', unit => '%',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'creation', set => {
                key_values => [ { name => 'creation_human' }, { name => 'creation_seconds' }, { name => 'display' } ],
                threshold_use => 'creation_seconds',
                output_template => 'Creation Time : %s',
                perfdatas => [
                    { label => 'creation', value => 'creation_seconds', template => '%d', 
                      unit => 's', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'duration', set => {
                key_values => [ { name => 'duration_human' }, { name => 'duration_seconds' }, { name => 'display' } ],
                threshold_use => 'duration_seconds',
                output_template => 'Duration : %s',
                perfdatas => [
                    { label => 'duration', value => 'duration_seconds', template => '%d', 
                      unit => 's', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'physical-bytes-written', set => {
                key_values => [ { name => 'physical_bytes_written' }, { name => 'display' } ],
                output_template => 'Physical Bytes Written : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'physical_bytes_written', value => 'physical_bytes_written', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'data-transferred', set => {
                key_values => [ { name => 'data_transferred' }, { name => 'display' } ],
                output_template => 'Data Transferred : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'data_transferred', value => 'data_transferred', template => '%s', 
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'timezone:s'    => { name => 'timezone', default => 'GMT' },
    });
    
    return $self;
}

sub prefix_pgroup_output {
    my ($self, %options) = @_;
    
    return "Protection group '" . $options{instance_value}->{display} . "' replication ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{pgroup} = {};
    my $result = $options{custom}->get_object(path => '/pgroup?snap=true&transfer=true');
    
    #[
    #    {"name": "prod:PROD-SQL-SERVER.6620", "created": "2018-10-15T13:05:06Z", "started": "2018-10-15T13:05:06Z", "completed": "2018-10-15T13:05:53Z", "physical_bytes_written": 4183179644, "source": "prod:PROD-SQL-SERVER", "progress": 1.0, "data_transferred": 4609709762}
    #    ...
    #]
    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    foreach my $entry (@{$result}) {
        next if ($entry->{name} !~ /(.*)\.[0-9]+$/);
        my $pgroup_name = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $pgroup_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $pgroup_name . "': no matching filter.", debug => 1);
            next;
        }

        $entry->{created} =~ /^(\d+)-(\d+)-(\d+)T(\d+)[:\/](\d+)[:\/](\d+)Z$/;
        my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, %$tz);
        my $created_time = $dt->epoch;
        my $creation_seconds = time() - $created_time;

        next if (defined($self->{pgroup}->{$pgroup_name}->{creation_seconds}) && $creation_seconds > $self->{pgroup}->{$pgroup_name}->{creation_seconds});

        $entry->{completed} =~ /^(\d+)-(\d+)-(\d+)T(\d+)[:\/](\d+)[:\/](\d+)Z$/;
        $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, %$tz);
        my $completed_time = $dt->epoch;
        
        $self->{pgroup}->{$pgroup_name} = {
            display => $pgroup_name,
            progress => defined($entry->{progress}) ? $entry->{progress} * 100 : 0.0,
            physical_bytes_written => $entry->{physical_bytes_written},
            data_transferred => $entry->{data_transferred},
            creation_seconds => $creation_seconds,
            creation_human => centreon::plugins::misc::change_seconds(value => $creation_seconds),
            duration_seconds => $completed_time - $created_time,
            duration_human => centreon::plugins::misc::change_seconds(value => $completed_time - $created_time),
        };
    }

    if (scalar(keys %{$self->{pgroup}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No replication group found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check protection group replication state and usage.

=over 8

=item B<--filter-counters>

Only display some counters (Can be a regexp).
Example: --filter-counters='^progress$'

=item B<--filter-name>

Filter protection group name (Can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'progress' (%), 'creation' (s), 'duration' (s),
'physical-bytes-written' (B), 'data-transferred' (B).

=item B<--critical-*>

Threshold critical.
Can be: 'progress' (%), 'creation' (s), 'duration' (s),
'physical-bytes-written' (B), 'data-transferred' (B).

=item B<--timezone>

Timezone of API results (Default: 'GMT').

=back

=cut
