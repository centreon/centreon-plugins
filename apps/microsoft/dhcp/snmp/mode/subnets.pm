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

package apps::microsoft::dhcp::snmp::mode::subnets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'addresses usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used}, $self->{result_values}->{prct_used},
        $self->{result_values}->{free}, $self->{result_values}->{prct_free}
    );
}

sub prefix_subnet_output {
    my ($self, %options) = @_;

    return sprintf(
        "Subnet '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'subnets', type => 1, cb_prefix_output => 'prefix_subnet_output', message_multiple => 'All subnets are ok' }
    ];

    $self->{maps_counters}->{subnets} = [
        { label => 'addresses-usage', nlabel => 'subnet.addresses.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'addresses-usage-free', nlabel => 'subnet.addresses.free.count', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'addresses-usage-prct', nlabel => 'subnet.addresses.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'pending-offers', nlabel => 'subnet.pending.offers.count', set => {
                key_values => [ { name => 'pending_offers' } ],
                output_template => 'pending offers: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-subnet-address:s' => { name => 'filter_subnet_address' }
    });

    return $self;
}

my $mapping = {
    used           => { oid => '.1.3.6.1.4.1.311.1.3.2.1.1.2' }, # noAddInUse    
    free           => { oid => '.1.3.6.1.4.1.311.1.3.2.1.1.3' }, # noAddFree
    pending_offers => { oid => '.1.3.6.1.4.1.311.1.3.2.1.1.4' }  # noPendingOffers
};
my $oid_subnetAdd = '.1.3.6.1.4.1.311.1.3.2.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_subnetAdd,
        nothing_quit => 1
    );

    $self->{subnets} = {};
    foreach (keys %$snmp_result) {
        /^$oid_subnetAdd\.(.*)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_subnet_address}) && $self->{option_results}->{filter_subnet_address} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_subnet_address}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$_} . "': no matching 'org' filter.", debug => 1);
            next;
        }

        $self->{subnets}->{$instance} = { name => $snmp_result->{$_} };
    }

    if (scalar(keys %{$self->{subnets}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No subnets found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [keys %{$self->{subnets}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{subnets}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{subnets}->{$_}->{pending_offers} = $result->{pending_offers};
        $self->{subnets}->{$_}->{free} = $result->{free};
        $self->{subnets}->{$_}->{used} = $result->{used};
        $self->{subnets}->{$_}->{total} = $result->{used} + $result->{free};
        $self->{subnets}->{$_}->{prct_used} = $result->{used} * 100 / ($result->{used} + $result->{free});
        $self->{subnets}->{$_}->{prct_free} = $result->{free} * 100 / ($result->{used} + $result->{free});
    }
}

1;

__END__

=head1 MODE

Check dhcp subnets.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='pending'

=item B<--filter-subnet-address>

Filter subnets by address (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'addresses-usage', 'addresses-usage-free', 'addresses-usage-prct', 'pending-offers'.

=back

=cut
