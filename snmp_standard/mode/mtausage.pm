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

package snmp_standard::mode::mtausage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_global_output', message_multiple => 'All MTA are ok', skipped_code => { -10 => 1 } },
        { name => 'mtagrp', type => 1, cb_prefix_output => 'prefix_mtagrp_output', message_multiple => 'All MTA groups are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-received-messages', set => {
                key_values => [ { name => 'mtaReceivedMessages', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Received Messages : %s', output_error_template => "Total Received Messages : %s",
                perfdatas => [
                    { label => 'total_received_messages', value => 'mtaReceivedMessages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-received-volume', set => {
                key_values => [ { name => 'mtaReceivedVolume', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Received Volume : %s %s', output_error_template => "Total Received Volume : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_received_volume', value => 'mtaReceivedVolume', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-stored-messages', set => {
                key_values => [ { name => 'mtaStoredMessages' }, { name => 'display' } ],
                output_template => 'Total Stored Messages : %s', output_error_template => "Total Stored Messages : %s",
                perfdatas => [
                    { label => 'total_stored_messages', value => 'mtaStoredMessages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-stored-volume', set => {
                key_values => [ { name => 'mtaStoredVolume' }, { name => 'display' } ],
                output_template => 'Total Stored Volume : %s %s', output_error_template => "Total Stored Volume : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_stored_volume', value => 'mtaStoredVolume', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-transmitted-messages', set => {
                key_values => [ { name => 'mtaTransmittedMessages', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Transmitted Messages : %s', output_error_template => "Total Transmitted Messages : %s",
                perfdatas => [
                    { label => 'total_transmitted_messages', value => 'mtaTransmittedMessages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-transmitted-volume', set => {
                key_values => [ { name => 'mtaTransmittedVolume', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Transmitted Volume : %s %s', output_error_template => "Total Transmitted Volume : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_transmitted_volume', value => 'mtaTransmittedVolume', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{mtagrp} = [
        { label => 'received-messages', set => {
                key_values => [ { name => 'mtaGroupReceivedMessages', diff => 1 }, { name => 'display' } ],
                output_template => 'Received Messages : %s', output_error_template => "Received Messages : %s",
                perfdatas => [
                    { label => 'received_messages', value => 'mtaGroupReceivedMessages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'received-volume', set => {
                key_values => [ { name => 'mtaGroupReceivedVolume', diff => 1 }, { name => 'display' } ],
                output_template => 'Received Volume : %s %s', output_error_template => "Received Volume : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'received_volume', value => 'mtaGroupReceivedVolume', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'stored-messages', set => {
                key_values => [ { name => 'mtaGroupStoredMessages' }, { name => 'display' } ],
                output_template => 'Stored Messages : %s', output_error_template => "Stored Messages : %s",
                perfdatas => [
                    { label => 'stored_messages', value => 'mtaGroupStoredMessages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'stored-volume', set => {
                key_values => [ { name => 'mtaGroupStoredVolume' }, { name => 'display' } ],
                output_template => 'Stored Volume : %s %s', output_error_template => "Stored Volume : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'stored_volume', value => 'mtaGroupStoredVolume', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'transmitted-messages', set => {
                key_values => [ { name => 'mtaGroupTransmittedMessages', diff => 1 }, { name => 'display' } ],
                output_template => 'Transmitted Messages : %s', output_error_template => "Transmitted Messages : %s",
                perfdatas => [
                    { label => 'transmitted_messages', value => 'mtaGroupTransmittedMessages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'transmitted-volume', set => {
                key_values => [ { name => 'mtaGroupTransmittedVolume', diff => 1 }, { name => 'display' } ],
                output_template => 'Transmitted Volume : %s %s', output_error_template => "Transmitted Volume : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'transmitted_volume', value => 'mtaGroupTransmittedVolume', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'rejected-messages', set => {
                key_values => [ { name => 'mtaGroupRejectedMessages', diff => 1 }, { name => 'display' } ],
                output_template => 'Rejected Messages : %s', output_error_template => "Rejected Messages : %s",
                perfdatas => [
                    { label => 'rejected_messages', value => 'mtaGroupRejectedMessages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "MTA '" . $options{instance_value}->{display} . "' ";
}

sub prefix_mtagrp_output {
    my ($self, %options) = @_;
    
    return "MTA group '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"           => { name => 'filter_name' },
                                });
    
    return $self;
}
my $mapping = {
    mtaReceivedMessages     => { oid => '.1.3.6.1.2.1.28.1.1.1' },
    mtaStoredMessages       => { oid => '.1.3.6.1.2.1.28.1.1.2' },
    mtaTransmittedMessages  => { oid => '.1.3.6.1.2.1.28.1.1.3' },
    mtaReceivedVolume       => { oid => '.1.3.6.1.2.1.28.1.1.4' },
    mtaStoredVolume         => { oid => '.1.3.6.1.2.1.28.1.1.5' },
    mtaTransmittedVolume    => { oid => '.1.3.6.1.2.1.28.1.1.6' },
};
my $mapping2 = {
    mtaGroupReceivedMessages    => { oid => '.1.3.6.1.2.1.28.2.1.2' },
    mtaGroupRejectedMessages    => { oid => '.1.3.6.1.2.1.28.2.1.3' },
    mtaGroupStoredMessages      => { oid => '.1.3.6.1.2.1.28.2.1.4' },
    mtaGroupTransmittedMessages => { oid => '.1.3.6.1.2.1.28.2.1.5' },
    mtaGroupReceivedVolume      => { oid => '.1.3.6.1.2.1.28.2.1.6' },
    mtaGroupStoredVolume        => { oid => '.1.3.6.1.2.1.28.2.1.7' },
    mtaGroupTransmittedVolume   => { oid => '.1.3.6.1.2.1.28.2.1.8' },
    mtaGroupName                => { oid => '.1.3.6.1.2.1.28.2.1.25' },
};

my $oid_mtaEntry = '.1.3.6.1.2.1.28.1.1';
my $oid_mtaGroupEntry = '.1.3.6.1.2.1.28.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
       { oid => $oid_mtaEntry },
       { oid => $oid_mtaGroupEntry },
       ], nothing_quit => 1);

    $self->{global} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_mtaEntry}}) {
        next if ($oid !~ /^$mapping->{mtaReceivedMessages}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_mtaEntry}, instance => $instance);

        foreach (('mtaReceivedVolume', 'mtaStoredVolume', 'mtaTransmittedVolume')) {
            $result->{$_} *= 1024 if (defined($result->{$_}));
        }
      
        $self->{global}->{$instance} = { display => $instance,
            %$result
        };
    }

    $self->{mtagrp} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_mtaGroupEntry}}) {
        next if ($oid !~ /^$mapping2->{mtaGroupName}->{oid}\.(.*?)\.(.*?)$/);
        my ($applIndex, $mtaGroupIndex) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_mtaGroupEntry}, instance => $applIndex . '.' . $mtaGroupIndex);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{mtaGroupName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{mtaGroupName} . "': no matching filter.", debug => 1);
            next;
        }
        
        foreach (('mtaGroupReceivedVolume', 'mtaGroupStoredVolume', 'mtaGroupTransmittedVolume')) {
            $result->{$_} *= 1024 if (defined($result->{$_}));
        }
      
        $self->{mtagrp}->{$applIndex . '.' . $result->{mtaGroupName}} = { display => $applIndex . '.' . $result->{mtaGroupName},
            %$result
        };
    }
    
    $self->{cache_name} = $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check MTA usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='received'

=item B<--filter-name>

Filter MTA group name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'total-received-messages', 'total-received-volume', 'total-stored-messages', 'total-stored-volume', 
'total-transmitted-messages', 'total-transmitted-volume',
'received-messages', 'received-volume', 'stored-messages', 'stored-volume', 'transmitted-messages', 
'transmitted-volume', 'rejected-messages'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-received-messages', 'total-received-volume', 'total-stored-messages', 'total-stored-volume', 
'total-transmitted-messages', 'total-transmitted-volume',
'received-messages', 'received-volume', 'stored-messages', 'stored-volume', 'transmitted-messages', 
'transmitted-volume', 'rejected-messages'.

=back

=cut
