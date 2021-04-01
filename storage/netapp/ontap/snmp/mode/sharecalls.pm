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

package storage::netapp::ontap::snmp::mode::sharecalls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cifs', nlabel => 'storage.cifs.calls.persecond', set => {
                key_values => [ { name => 'cifs', per_second => 1 } ],
                output_template => 'CIFS : %s calls/s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'nfs', nlabel => 'storage.nfs.calls.persecond', set => {
                key_values => [ { name => 'nfs', per_second => 1 } ],
                output_template => 'NFS : %s calls/s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $oid_miscHighNfsOps = '.1.3.6.1.4.1.789.1.2.2.5.0';
my $oid_miscLowNfsOps = '.1.3.6.1.4.1.789.1.2.2.6.0';
my $oid_miscHighCifsOps = '.1.3.6.1.4.1.789.1.2.2.7.0';
my $oid_miscLowCifsOps = '.1.3.6.1.4.1.789.1.2.2.8.0';
my $oid_misc64NfsOps = '.1.3.6.1.4.1.789.1.2.2.27.0';
my $oid_misc64CifsOps = '.1.3.6.1.4.1.789.1.2.2.28.0';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $request = [
        $oid_miscHighNfsOps, $oid_miscLowNfsOps,
        $oid_miscHighCifsOps, $oid_miscLowCifsOps
    ];
    if (!$options{snmp}->is_snmpv1()) {
        push @{$request}, ($oid_misc64NfsOps, $oid_misc64CifsOps);
    }
    
    my $snmp_result = $options{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{cifs} = defined($snmp_result->{$oid_misc64CifsOps}) ?
                                $snmp_result->{$oid_misc64CifsOps} : 
                                ($snmp_result->{$oid_miscHighCifsOps} << 32) + $snmp_result->{$oid_miscLowCifsOps};
    $self->{global}->{nfs} = defined($snmp_result->{$oid_misc64NfsOps}) ?
                                $snmp_result->{$oid_misc64NfsOps} : 
                                ($snmp_result->{$oid_miscHighNfsOps} << 32) + $snmp_result->{$oid_miscLowNfsOps};

    $self->{cache_name} = "cache_netapp_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check cifs and nfs calls per seconds.
If you are in cluster mode, the following mode doesn't work. Ask to netapp to add it :)

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'cifs', 'nfs'.

=item B<--critical-*>

Threshold critical.
Can be: 'cifs', 'nfs'.

=back

=cut
    
