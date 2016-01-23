#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::mode::clusterstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_fgHaSystemMode = '.1.3.6.1.4.1.12356.101.13.1.1'; # '.0' to have the mode
my $oid_fgHaStatsSerial = '.1.3.6.1.4.1.12356.101.13.2.1.1.2';
my $oid_fgHaStatsMasterSerial = '.1.3.6.1.4.1.12356.101.13.2.1.1.16';
my $oid_fgHaStatsSyncStatus = '.1.3.6.1.4.1.12356.101.13.2.1.1.12';

my %maps_ha_mode = (
    1 => 'standalone',
    2 => 'activeActive',
    3 => 'activePassive',
);

my %maps_sync_status = (
    0 => 'not synchronized',
    1 => 'synchronized',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "one-node-status:s" => { name => 'one_node_status', default => 'critical' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{one_node_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong one-node-status status option '" . $self->{option_results}->{one_node_status} . "'.");
        $self->{output}->option_exit();
    }
}
    
sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->{result} = $self->{snmp}->get_multiple_table(oids => [
                                                                  { oid => $oid_fgHaSystemMode },
                                                                  { oid => $oid_fgHaStatsMasterSerial },
                                                                  { oid => $oid_fgHaStatsSerial },
                                                                  { oid => $oid_fgHaStatsSyncStatus },
                                                                ], 
                                                        nothing_quit => 1);
    
    # Check if mode cluster
    my $ha_mode = $self->{result}->{$oid_fgHaSystemMode}->{$oid_fgHaSystemMode . '.0'};
    my $ha_output = defined($maps_ha_mode{$ha_mode}) ? $maps_ha_mode{$ha_mode} : 'unknown';
    $self->{output}->output_add(long_msg => 'High availabily mode is ' . $ha_output . '.');
    if ($ha_mode == 1) {
        $self->{output}->output_add(severity => 'ok',
                                    short_msg => sprintf("No cluster configuration (standalone mode)."));
    } else {
        $self->{output}->output_add(severity => 'ok',
                                    short_msg => sprintf("Cluster status is ok."));
        
        foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{result}->{$oid_fgHaStatsSerial}})) {
            next if ($key !~ /^$oid_fgHaStatsSerial\.([0-9]+)$/);

            if ($ha_mode == 3) {
                my $state = $self->{result}->{$oid_fgHaStatsMasterSerial}->{$oid_fgHaStatsMasterSerial . '.' . $1} eq '' ? 
                            'master' : 'slave';
                $self->{output}->output_add(long_msg => sprintf("Node '%s' is %s.", 
                                                    $self->{result}->{$oid_fgHaStatsSerial}->{$key}, $state));
            }
            
            my $sync_status = $self->{result}->{$oid_fgHaStatsSyncStatus}->{$oid_fgHaStatsSyncStatus . '.' . $1};
            next if (!defined($sync_status));
            
            $self->{output}->output_add(long_msg => sprintf("Node '%s' sync-status is %s.", 
                                                    $self->{result}->{$oid_fgHaStatsSerial}->{$key}, $maps_sync_status{$sync_status}));
            if ($sync_status == 0) {
                $self->{output}->output_add(severity => 'critical',
                                    short_msg => sprintf("Node '%s' sync-status is %s.", 
                                                    $self->{result}->{$oid_fgHaStatsSerial}->{$key}, $maps_sync_status{$sync_status}));
            }
        }
        
        if (scalar(keys %{$self->{result}->{$oid_fgHaStatsSerial}}) == 1 &&
            !$self->{output}->is_status(value => $self->{option_results}->{one_node_status}, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $self->{option_results}->{one_node_status},
                                        short_msg => sprintf("Cluster with one node only"));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cluster status (FORTINET-FORTIGATE-MIB).

=over 8

=item B<--one-node-status>

Status if only one node (default: 'critical').

=back

=cut