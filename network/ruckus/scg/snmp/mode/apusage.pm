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

package network::ruckus::scg::snmp::mode::apusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All APs are ok' },
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'users-count', set => {
                key_values => [ { name => 'ruckusSCGAPNumSta' }, { name => 'display' } ],
                output_template => 'Users count: %s',
                perfdatas => [
                    { label => 'users_count', template => '%s',
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'ruckusSCGAPRXBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'ruckusSCGAPTXBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "AP '" . $options{instance_value}->{display} . "' ";
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_ruckusSCGAPName = '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.5',
my $mapping = {
    ruckusSCGAPNumSta       => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.15' },
    ruckusSCGAPRXBytes      => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.30' },
    ruckusSCGAPTXBytes      => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.31' },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    $self->{ap} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_ruckusSCGAPName, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_ruckusSCGAPName\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{ap}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [ $mapping->{ruckusSCGAPNumSta}->{oid},
                                   $mapping->{ruckusSCGAPRXBytes}->{oid},
                                   $mapping->{ruckusSCGAPTXBytes}->{oid} ],
                         instances => [ keys %{$self->{ap}} ],
                         instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
                
        foreach my $name (keys %{$mapping}) {
            $self->{ap}->{$_}->{$name} = $result->{$name};
        }
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "ruckus_scg_" . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check AP connected users and traffic.

=over 8

=item B<--filter-name>

Filter by AP name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'users-count', 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'users-count', 'traffic-in', 'traffic-out'.

=back

=cut
    
