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

package hardware::devices::aeg::acm::snmp::mode::acstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("AC plant fail status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_acFail'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  },
    ];
        
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'acFail' } ],
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
        "warning-status:s"        => { name => 'warning_status', default => '' },
        "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /true/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    0 => 'false',
    1 => 'true',
);

my $mapping_acm1000 = {
    acFail      => { oid => '.1.3.6.1.4.1.15416.37.4.1', map => \%map_status },
};
my $mapping_acmi1000 = {
    acFail      => { oid => '.1.3.6.1.4.1.15416.38.4.1', map => \%map_status },
};
my $oid_acm1000AcPlant = '.1.3.6.1.4.1.15416.37.4';
my $oid_acmi1000AcPlant = '.1.3.6.1.4.1.15416.38.4';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    $self->{results} = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $oid_acm1000AcPlant },
            { oid => $oid_acmi1000AcPlant },
        ],
        nothing_quit => 1
    );

    my $result_acm1000 = $options{snmp}->map_instance(mapping => $mapping_acm1000, results => $self->{results}->{$oid_acm1000AcPlant}, instance => '0');
    my $result_acmi1000 = $options{snmp}->map_instance(mapping => $mapping_acmi1000, results => $self->{results}->{$oid_acmi1000AcPlant}, instance => '0');

    foreach my $name (keys %{$mapping_acm1000}) {
        if (defined($result_acm1000->{$name})) {
            $self->{global}->{$name} = $result_acm1000->{$name};
        }
    }
    foreach my $name (keys %{$mapping_acmi1000}) {
        if (defined($result_acmi1000->{$name})) {
            $self->{global}->{$name} = $result_acmi1000->{$name};
        }
    }
}

1;

__END__

=head1 MODE

Check AC plant status.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /true/i').
Can used special variables like: %{status}

=back

=cut
