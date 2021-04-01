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

package database::informix::snmp::mode::archivelevel0;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'dbspace', type => 1, cb_prefix_output => 'prefix_dbspace_output', message_multiple => 'All dbspace backups are ok' }
    ];
    
    $self->{maps_counters}->{dbspace} = [
        { label => 'time', set => {
                key_values => [ { name => 'seconds' }, { name => 'date'}, { name => 'display' } ],
                output_template => "archive level0 last execution date '%s'",
                output_use => 'date',
                perfdatas => [
                    { label => 'seconds', value => 'seconds', template => '%s', min => 0, unit => 's',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_dbspace_output {
    my ($self, %options) = @_;
    
    return "Dbspace '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"     => { name => 'filter_name' },
        "timezone:s"        => { name => 'timezone' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_applName = '.1.3.6.1.2.1.27.1.1.2';
    my $oid_onDbspaceName = '.1.3.6.1.4.1.893.1.1.1.6.1.2';
    my $oid_onDbspaceLastFullBackupDate = '.1.3.6.1.4.1.893.1.1.1.6.1.15';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $oid_applName },
            { oid => $oid_onDbspaceName },
            { oid => $oid_onDbspaceLastFullBackupDate },
        ], return_type => 1, nothing_quit => 1
    );

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    $self->{dbspace} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_onDbspaceName\.(.*?)\.(.*)/);
        my ($applIndex, $dbSpaceIndex) = ($1, $2);
        
        my $name = 'default';
        $name = $snmp_result->{$oid_applName . '.' . $applIndex} 
            if (defined($snmp_result->{$oid_applName . '.' . $applIndex}));
        $name .= '.' . $snmp_result->{$oid_onDbspaceName . '.' . $applIndex. '.' . $dbSpaceIndex};
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        my ($seconds, $date) = (-1, 'never');
        if (defined($snmp_result->{$oid_onDbspaceLastFullBackupDate . '.' . $applIndex. '.' . $dbSpaceIndex})) {
            my @dates = unpack('n C6 a C2', $snmp_result->{$oid_onDbspaceLastFullBackupDate . '.' . $applIndex. '.' . $dbSpaceIndex});
            if ($dates[0] != 0) {
                my $dt = DateTime->new(year => $dates[0], month => $dates[1], day => $dates[2], hour => $dates[3], minute => $dates[4], second => $dates[5], %$tz);
                $seconds = time() - $dt->epoch;
                $date =  sprintf("%04d-%02d-%02d %02d:%02d:%02d", $dates[0], $dates[1], $dates[2], $dates[3], $dates[4], $dates[5]);
            }            
        }
        $self->{dbspace}->{$name} = { 
            display => $name,
            seconds => $seconds,
            date => $date,
        };
    }
    
    if (scalar(keys %{$self->{dbspace}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No dbspace found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check last full backup.

=over 8

=item B<--filter-name>

Filter dbspace name (can be a regexp).

=item B<--warning-time>

Threshold warning in seconds.

=item B<--critical-time>

Threshold critical in seconds.

=back

=cut
