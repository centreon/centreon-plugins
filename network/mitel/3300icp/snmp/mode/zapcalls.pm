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

package network::mitel::3300icp::snmp::mode::zapcalls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'zap', type => 1, cb_prefix_output => 'prefix_zap_output', message_multiple => 'All zone access points are ok' },
    ];
    
    $self->{maps_counters}->{zap} = [
        { label => 'admitted', set => {
                key_values => [ { name => 'mitelBWMCumCACAdmissions', diff => 1 }, { name => 'display' } ],
                output_template => 'Admitted calls: %s',
                perfdatas => [
                    { label => 'admitted', value => 'mitelBWMCumCACAdmissions', template => '%s',
                      min => 0, unit => 'calls', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'rejected', set => {
                key_values => [ { name => 'mitelBWMCumCACRejections', diff => 1 }, { name => 'display' } ],
                output_template => 'Rejected calls: %s',
                perfdatas => [
                    { label => 'rejected', value => 'mitelBWMCumCACRejections', template => '%s',
                      min => 0, unit => 'calls', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'rejection-ratio', set => {
                key_values => [ { name => 'mitelBWMCumCACRejectionRatio' }, { name => 'display' } ],
                output_template => 'Rejection ratio: %s%%',
                perfdatas => [
                    { label => 'rejection_ratio', value => 'mitelBWMCumCACRejectionRatio', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_zap_output {
    my ($self, %options) = @_;

    return "Zone access point '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"    => { name => 'filter_name' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_mitelBWMCumZAPLabel = '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.2.1.4',
my $mapping = {
    mitelBWMCumCACAdmissions            => { oid => '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.2.1.5' },
    mitelBWMCumCACRejections            => { oid => '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.2.1.6' },
    mitelBWMCumCACRejectionRatio        => { oid => '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.2.1.7' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{zap} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_mitelBWMCumZAPLabel, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_mitelBWMCumZAPLabel\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{zap}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [ $mapping->{mitelBWMCumCACAdmissions}->{oid},
                                   $mapping->{mitelBWMCumCACRejections}->{oid},
                                   $mapping->{mitelBWMCumCACRejectionRatio}->{oid} ],
                         instances => [ keys %{$self->{zap}} ],
                         instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{zap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
                
        foreach my $name (keys %{$mapping}) {
            $self->{zap}->{$_}->{$name} = $result->{$name};
        }
    }

    if (scalar(keys %{$self->{zap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No zone access points found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "mitel_3300icp_" . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check zone access points calls.

=over 8

=item B<--filter-name>

Filter by zone access points name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'admitted', 'rejected', 'rejection-ratio' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'admitted', 'rejected', 'rejection-ratio' (%).

=back

=cut
    
