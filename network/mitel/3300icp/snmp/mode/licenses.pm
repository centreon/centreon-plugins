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

package network::mitel::3300icp::snmp::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_user_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{purchased} = $options{new_datas}->{$self->{instance} . '_mitelIpera3000IPUsrLicPurchased'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_mitelIpera3000IPUsrLicUsed'};
    $self->{result_values}->{prct} = ($self->{result_values}->{purchased} != 0) ? $self->{result_values}->{used} / $self->{result_values}->{purchased} * 100 : 0;
    return 0;
}

sub custom_device_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{purchased} = $options{new_datas}->{$self->{instance} . '_mitelIpera3000IPDevLicPurchased'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_mitelIpera3000IPDevLicUsed'};
    $self->{result_values}->{prct} = ($self->{result_values}->{purchased} != 0) ? $self->{result_values}->{used} / $self->{result_values}->{purchased} * 100 : 0;
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => 'licenses_' . $self->{label},
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{purchased}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{purchased}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{purchased});
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    return sprintf("%s licenses used: %s/%s (%.2f %%)", ucfirst($self->{label}),
                                                        $self->{result_values}->{used},
                                                        $self->{result_values}->{purchased},
                                                        $self->{result_values}->{prct});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'user', set => {
                key_values => [ { name => 'mitelIpera3000IPUsrLicPurchased' }, { name => 'mitelIpera3000IPUsrLicUsed' } ],
                closure_custom_calc => $self->can('custom_user_calc'), 
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct',
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'device', set => {
                key_values => [ { name => 'mitelIpera3000IPDevLicPurchased' }, { name => 'mitelIpera3000IPDevLicUsed' } ],
                closure_custom_calc => $self->can('custom_device_calc'), 
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct',
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_mitelIpera3000IPUsrLicPurchased = '.1.3.6.1.4.1.1027.4.1.1.2.1.2.1.0';
my $oid_mitelIpera3000IPUsrLicUsed = '.1.3.6.1.4.1.1027.4.1.1.2.1.2.2.0';
my $oid_mitelIpera3000IPDevLicPurchased = '.1.3.6.1.4.1.1027.4.1.1.2.1.2.3.0';
my $oid_mitelIpera3000IPDevLicUsed = '.1.3.6.1.4.1.1027.4.1.1.2.1.2.4.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{snmp}->get_leef(oids => [ $oid_mitelIpera3000IPUsrLicPurchased,
                                                    $oid_mitelIpera3000IPUsrLicUsed,
                                                    $oid_mitelIpera3000IPDevLicPurchased,
                                                    $oid_mitelIpera3000IPDevLicUsed ], 
                                          nothing_quit => 1);

    $self->{global} = {
        mitelIpera3000IPUsrLicPurchased => $result->{$oid_mitelIpera3000IPUsrLicPurchased},
        mitelIpera3000IPUsrLicUsed => $result->{$oid_mitelIpera3000IPUsrLicUsed},
        mitelIpera3000IPDevLicPurchased => $result->{$oid_mitelIpera3000IPDevLicPurchased},
        mitelIpera3000IPDevLicUsed => $result->{$oid_mitelIpera3000IPDevLicUsed},
    };
}

1;

__END__

=head1 MODE

Check call server licenses used versus purchased.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'user' (%), 'device' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'user' (%), 'device' (%).

=back

=cut
