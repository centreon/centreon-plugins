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

package database::informix::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_instances_output', message_multiple => 'All instances are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'sessions', set => {
                key_values => [ { name => 'sessions' }, { name => 'display' } ],
                output_template => '%d client sessions',
                perfdatas => [
                    { label => 'sessions', value => 'sessions', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_instances_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
    });
    
    return $self;
}

my $mapping = {
    onSessionUserName       => { oid => '.1.3.6.1.4.1.893.1.1.1.10.1.2' },
    onSessionUserProcessId  => { oid => '.1.3.6.1.4.1.893.1.1.1.10.1.4' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_applName = '.1.3.6.1.2.1.27.1.1.2';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $oid_applName },
            { oid => $mapping->{onSessionUserName}->{oid} },
            { oid => $mapping->{onSessionUserProcessId}->{oid} },
        ], return_type => 1, nothing_quit => 1
    );

    $self->{global} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{onSessionUserName}->{oid}\.(.*?)\.(.*)/);
        my ($applIndex, $sessionIndex) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $applIndex . '.' . $sessionIndex);
        
        my $name = 'default';
        $name = $snmp_result->{$oid_applName . '.' . $applIndex} 
            if (defined($snmp_result->{$oid_applName . '.' . $applIndex}));
        
        if (!defined($self->{global}->{$name})) {
            $self->{global}->{$name} = { display => $name, sessions => 0 };
        }
        $self->{global}->{$name}->{sessions}++;
    }
}

1;

__END__

=head1 MODE

Check number of open sessions ('informix' user is not counted).

=over 8

=item B<--warning-sessions>

Threshold warning.

=item B<--critical-sessions>

Threshold critical.

=back

=cut
