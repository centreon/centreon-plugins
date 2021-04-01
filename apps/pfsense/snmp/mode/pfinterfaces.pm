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

package apps::pfsense::snmp::mode::pfinterfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pfint', type => 1, cb_prefix_output => 'prefix_pfint_output', message_multiple => 'All pfInterfaes are ok' }
    ];
    
    $self->{maps_counters}->{pfint} = [
        { label => 'traffic-in-pass', nlabel => 'pfinterface.pass.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'pfInterfacesIf4BytesInPass', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In Pass : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in_pass', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out-pass', nlabel => 'pfinterface.pass.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'pfInterfacesIf4BytesOutPass', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out Pass : %s %s/s',
                perfdatas => [
                    { label => 'traffic_out_pass', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in-block', nlabel => 'pfinterface.block.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'pfInterfacesIf4BytesInBlock', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In Block : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in_block', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out-block', nlabel => 'pfinterface.block.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'pfInterfacesIf4BytesOutBlock', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out Block : %s %s/s',
                perfdatas => [
                    { label => 'traffic_out_block', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_pfint_output {
    my ($self, %options) = @_;
    
    return "pfInterface '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $oid_pfInterfacesIfDescr = '.1.3.6.1.4.1.12325.1.200.1.8.2.1.2';
my $mapping = {
    pfInterfacesIf4BytesInPass      => { oid => '.1.3.6.1.4.1.12325.1.200.1.8.2.1.7' },
    pfInterfacesIf4BytesInBlock     => { oid => '.1.3.6.1.4.1.12325.1.200.1.8.2.1.8' },
    pfInterfacesIf4BytesOutPass     => { oid => '.1.3.6.1.4.1.12325.1.200.1.8.2.1.9' },
    pfInterfacesIf4BytesOutBlock    => { oid => '.1.3.6.1.4.1.12325.1.200.1.8.2.1.10' }
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    my $snmp_result = $options{snmp}->get_table(oid => $oid_pfInterfacesIfDescr, nothing_quit => 1);

    $self->{pfint} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_pfInterfacesIfDescr\.(.*)$/;
        my $instance = $1;
        
        my $name = $snmp_result->{$oid};        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pfInterface '" . $name . "'.", debug => 1);
            next;
        }

        $self->{pfint}->{$instance} = { display => $name };
    }

    $options{snmp}->load(
        oids => [
            $mapping->{pfInterfacesIf4BytesInPass}->{oid}, $mapping->{pfInterfacesIf4BytesOutPass}->{oid},
            $mapping->{pfInterfacesIf4BytesInBlock}->{oid}, $mapping->{pfInterfacesIf4BytesOutBlock}->{oid},
        ], 
        instances => [keys %{$self->{pfint}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach my $instance (keys %{$self->{pfint}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);        

        foreach (keys %$mapping) {
            $self->{pfint}->{$instance}->{$_} = $result->{$_} * 8;
        }
    }

    if (scalar(keys %{$self->{pfint}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No pfInterface found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'pfsense_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check pfInterfaces.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in-pass', 'traffic-out-pass', 'traffic-in-block', 'traffic-out-block'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in-pass', 'traffic-out-pass', 'traffic-in-block', 'traffic-out-block'.

=item B<--filter-name>

Filter by interface name (can be a regexp).

=back

=cut
