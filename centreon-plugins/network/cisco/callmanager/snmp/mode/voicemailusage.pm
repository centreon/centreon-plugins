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

package network::cisco::callmanager::snmp::mode::voicemailusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_voicemail_output {
    my ($self, %options) = @_;

    return "Voicemail '" . $options{instance_value}->{display} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Total ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'voicemail', type => 1, cb_prefix_output => 'prefix_voicemail_output', message_multiple => 'All voicemails are ok' }
    ];
    
    $self->{maps_counters}->{voicemail} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /^registered/', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    my @map = (
        ['total-registered', 'registered: %s', 'registered'],
        ['total-unregistered', 'unregistered: %s', 'unregistered'],
        ['total-rejected', 'rejected: %s', 'rejected'],
        ['total-unknown', 'unknown: %s', 'unknown'],
        ['total-partiallyregistered', 'partially registered: %s', 'partiallyregistered']
    );
    
    $self->{maps_counters}->{global} = [];
    foreach (@map) {
        push @{$self->{maps_counters}->{global}}, {
            label => $_->[0], nlabel => 'voicemail.devices.total.' . $_->[2] . '.count', set => {
                key_values => [ { name => $_->[2] } ],
                output_template => $_->[1],
                perfdatas => [
                    { value => $_->[2] , template => '%s', min => 0 }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my %mapping_status = (
    1 => 'unknown', 2 => 'registered', 3 => 'unregistered',
    4 => 'rejected', 5 => 'partiallyregistered'
);

my $mapping = {
    display     => { oid => '.1.3.6.1.4.1.9.9.156.1.12.1.1.2' }, # ccmVMailDevName
    description => { oid => '.1.3.6.1.4.1.9.9.156.1.12.1.1.4' }, # ccmVMailDevDescription
    status      => { oid => '.1.3.6.1.4.1.9.9.156.1.12.1.1.5', map => \%mapping_status } # ccmVMailDevStatus
};
my $oid_ccmVoicemailEntry = '.1.3.6.1.4.1.9.9.156.1.12.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ccmVoicemailEntry,
        start => $mapping->{display}->{oid},
        end => $mapping->{status}->{oid},
        nothing_quit => 1
    );

    $self->{phone} = {};
    $self->{global} = { unknown => 0, registered => 0, unregistered => 0, rejected => 0, partiallyregistered => 0 };
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{phone}->{$instance} = $result;
        $self->{global}->{ $result->{status} }++;
    }
}
    
1;

__END__

=head1 MODE

Check voicemail usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /^registered/').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-registered', 'total-unregistered', 'total-rejected', 
'total-unknown', 'total-partiallyregistered'.

=back

=cut
