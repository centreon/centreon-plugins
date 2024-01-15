#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::barracuda::bma::snmp::mode::mails;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_inbound_output {
    my ($self, %options) = @_;

    return 'Number of inbound mails ';
}

sub prefix_outbound_output {
    my ($self, %options) = @_;

    return 'Number of outbound mails ';
}

sub prefix_internal_output {
    my ($self, %options) = @_;

    return 'Number of internal mails ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'inbound', type => 0, cb_prefix_output => 'prefix_inbound_output', skipped_code => { -10 => 1 } },
        { name => 'outbound', type => 0, cb_prefix_output => 'prefix_outbound_output', skipped_code => { -10 => 1 } },
        { name => 'internal', type => 0, cb_prefix_output => 'prefix_internal_output', skipped_code => { -10 => 1 } }
    ];

    foreach ('inbound', 'outbound', 'internal') {
        $self->{maps_counters}->{$_} = [
            { label => $_ . '-hourly', nlabel => 'mails.' . $_ . '.hourly.count', set => {
                    key_values => [ { name => $_ . 'EmailsHour' } ],
                    output_template => 'hourly: %s',
                    perfdatas => [
                        { template => '%s', min => 0 }
                    ]
                }
            },
            { label => $_ . '-daily', nlabel => 'mails.' . $_ . '.daily.count', set => {
                    key_values => [ { name => $_ . 'EmailsDay' } ],
                    output_template => 'daily: %s',
                    perfdatas => [
                        { template => '%s', min => 0 }
                    ]
                }
            },
            { label => $_ . '-total', nlabel => 'mails.' . $_ . '.total.count', set => {
                    key_values => [ { name => $_ . 'EmailsTotal', diff => 1 } ],
                    output_template => 'total: %s',
                    perfdatas => [
                        { template => '%s', min => 0 }
                    ]
                }
            }
        ];
    }
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

my $mapping = {
    inboundEmailsHour   => { oid => '.1.3.6.1.4.1.20632.6.5.1' }, 
    inboundEmailsDay    => { oid => '.1.3.6.1.4.1.20632.6.5.2' },
    inboundEmailsTotal  => { oid => '.1.3.6.1.4.1.20632.6.5.3' },
    internalEmailsHour  => { oid => '.1.3.6.1.4.1.20632.6.5.4' },
    internalEmailsDay   => { oid => '.1.3.6.1.4.1.20632.6.5.5' },
    internalEmailsTotal => { oid => '.1.3.6.1.4.1.20632.6.5.6' },
    outboundEmailsHour  => { oid => '.1.3.6.1.4.1.20632.6.5.7' },
    outboundEmailsDay   => { oid => '.1.3.6.1.4.1.20632.6.5.8' },
    outboundEmailsTotal => { oid => '.1.3.6.1.4.1.20632.6.5.9' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result);
    $self->{inbound} = $result;
    $self->{outbound} = $result;
    $self->{internal} = $result;

    $self->{cache_name} = 'barracuda_bma_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check e-mails.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'internal-hourly', 'internal-daily', 'internal-total',
'outbound-hourly', 'outbound-daily', 'outbound-total',
'inbound-hourly', 'inbound-daily', 'inbound-total'.

=back

=cut
