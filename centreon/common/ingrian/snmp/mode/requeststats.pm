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

package centreon::common::ingrian::snmp::mode::requeststats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rq', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All request statistics are ok' }
    ];
    
    $self->{maps_counters}->{rq} = [
        { label => 'success', set => {
                key_values => [ { name => 'success', diff => 1 }, { name => 'display' } ],
                output_template => 'Success : %s',
                perfdatas => [
                    { label => 'success', value => 'success', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'fail', set => {
                key_values => [ { name => 'fail', diff => 1 }, { name => 'display' } ],
                output_template => 'Fail : %s',
                perfdatas => [
                    { label => 'fail', value => 'fail', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    return "'" . $options{instance_value}->{display} . "' requests ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "filter-name:s"     => { name => 'filter_name' },
                                });
    
    return $self;
}

my @map = (
    { label => 'Total',     suffix => 1 },
    { label => 'KeyGen',    suffix => 2 },
    { label => 'KeyInfo',   suffix => 3 },
    { label => 'KeyDel',    suffix => 4 },
    { label => 'KeyQuery',  suffix => 5 },
    { label => 'KeyImport', suffix => 6 },
    { label => 'KeyExport', suffix => 7 },
    { label => 'RandomGen', suffix => 8 },
    { label => 'Cryptographic',         suffix => 9 },
    { label => 'Authenticate',          suffix => 10 },
    { label => 'KeyModify',             suffix => 11 },
    { label => 'KeyClone',              suffix => 12 },
    { label => 'CertificateExport',     suffix => 13 },
    { label => 'KeyVersionGenerate',    suffix => 14 },
    { label => 'KeyVersionModify',      suffix => 15 },
    { label => 'KeyCertificateExport',  suffix => 16 },
    { label => 'RecordEvent',           suffix => 17 },
    { label => 'PublicKeyExport',       suffix => 18 },
    { label => 'CAExport',              suffix => 19 },
);
my $oid_naeServerStats = '.1.3.6.1.4.1.5595.3.3';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{rq} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_naeServerStats,
                                                nothing_quit => 1);
    foreach (@map) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{label} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{label} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{rq}->{$_->{suffix}} = { 
            display => $_->{label},
            success => $snmp_result->{$oid_naeServerStats . '.' . $_->{suffix} . '.3.0'},
            fail => $snmp_result->{$oid_naeServerStats . '.' . $_->{suffix} . '.4.0'}
        };
    }
    
    $self->{cache_name} = "ingrian_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check request statistics.

=over 8

=item B<--filter-name>

Filter by name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'success', 'fail'.

=item B<--critical-*>

Threshold critical.
Can be: 'success', 'fail'.

=back

=cut
