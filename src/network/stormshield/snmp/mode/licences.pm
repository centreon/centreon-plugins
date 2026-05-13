#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::licences;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc;
use DateTime;

our $GLOBAL_WARNING_THRESHOLD;
our $GLOBAL_PROBLEM;

sub custom_licence_output {
    my ($self, %options) = @_;

    my $name = $self->{result_values}->{name};
    my $days_left = $self->{result_values}->{days_left};
    my $exp_date = $self->{result_values}->{exp_date};
    my $seconds_left = $self->{result_values}->{seconds_left};
    my $fw_display = $options{instance_value}->{display}; 

    my $msg = "";
    if (defined $seconds_left) {
        if ($seconds_left < 0) {
            $msg = "Licence: $name (Expired: $exp_date)";
        } elsif ($days_left <= $GLOBAL_WARNING_THRESHOLD) {
            $msg = "Licence: $name (Expires in $days_left days: $exp_date)";
        } else {
            $msg = "Licence: $name (Expiration Date: $exp_date)";
            
            # Only add to long output if there isn't a warning/critical/unknown
            if(!$GLOBAL_PROBLEM) {
                $self->{output}->output_add(
                    long_msg => $msg
                );
            }
        }
    }
    
    return sprintf($msg);
}

sub custom_licence_threshold_check {
    my ($self, %options) = @_;
    
    my $days = $self->{result_values}->{days_left};
    my $seconds_left = $self->{result_values}->{seconds_left};

    if ($seconds_left < 0) {
        return 'CRITICAL';
    } elsif ($days <= $GLOBAL_WARNING_THRESHOLD) {
        return 'WARNING';
    } else {
        return 'OK';
    }
}


sub firewall_long_output {
    my ($self, %options) = @_;
    my $display = $options{instance_value}->{display};
    
    if (defined $display && $display ne '') {
        return "--------------Firewall $display--------------";
    }
    return "------------------------------------------------------------";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { 
            name => 'firewalls', 
            type => COUNTER_TYPE_GROUP,
            cb_long_output => 'firewall_long_output', 
            message_multiple => 'All licences of the cluster are up to date',
            group => [
                { 
                    name => 'licences', 
                    display_long => 1,
                    cb_prefix_output => sub { return ''; }, 
                    message_multiple => 'All licences are up to date', 
                    type => COUNTER_TYPE_INSTANCE, 
                    skipped_code => { -10 => 1 } 
                }
            ]
        }
    ];

    $self->{maps_counters}->{licences} = [
        {
            label => 'expiry',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'days_left' },
                    { name => 'name' },
                    { name => 'exp_date' },
                    { name => 'seconds_left' }
                ],
                closure_custom_output => $self->can('custom_licence_output'),
                closure_custom_threshold_check => $self->can('custom_licence_threshold_check'),
                closure_custom_perfdata => sub { return 0; }
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timezone:s' => { name => 'timezone' },
        'warning-days:s'  => { name => 'warning' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{timezone} = 'CET' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
    $self->{option_results}->{warning} = 60 if (!defined($self->{option_results}->{warning}) || $self->{option_results}->{warning} eq '');

    $GLOBAL_WARNING_THRESHOLD = $self->{option_results}->{warning};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{firewalls} = {};
    
    my $oid_snsNode = '.1.3.6.1.4.1.11256.1.11.7.1.1'; 
    my $oid_snsFwSerial = '.1.3.6.1.4.1.11256.1.11.7.1.2';
    my $oid_snsVersion = '.1.3.6.1.4.1.11256.1.18.2.0';

    my $snmp_result_version = $options{snmp}->get_leef(
        oids => [ $oid_snsVersion ],
        nothing_quit => 0,
    );
    
    if (defined $snmp_result_version && defined $snmp_result_version->{$oid_snsVersion}) {
        my $version_clean = $snmp_result_version->{$oid_snsVersion};
        # Extract major.minor.patch version number
        $version_clean =~ s/([0-9]+(?:\.[0-9]+)*).*/$1/;

        if (!centreon::plugins::misc::minimal_version($version_clean, '5.1.0')) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => 'Firmware version too old. Minimum required: 5.1.0'
            );
            return;
        }
    }

    # Detect if the device is in High Availability (HA) mode or Single Node
    my $ha_instances = [];
    my $ha_error = 0;
    my $ha_result = undef;
    my $serials = {};

    eval {
        $ha_result = $options{snmp}->get_table(
            oid => $oid_snsNode,
            nothing_quit => 0 
        );
    };
    if ($@) {
        $ha_error = 1;
        $self->{output}->output_add(long_msg => "HA Check OID error: $@", debug => 1);
    }

    my $is_ha = 0;
    if ($ha_error || !defined $ha_result || scalar(keys %$ha_result) == 0) {
        # No data returned from HA OID, assume Single Node mode
        $self->{output}->output_add(long_msg => "HA Check returned no data, assuming single node mode.", debug => 1);
        push @$ha_instances, '0';
        $is_ha = 0;
    } else {
        # Data returned, parse instances to determine HA cluster members
        foreach my $oid (sort keys %$ha_result) {
            if ($oid =~ /^$oid_snsNode\.(.*)/) {
                my $instance = $1;
                push @$ha_instances, $instance;
            }
        }
        
        if (scalar(@$ha_instances) == 0) {
            push @$ha_instances, '0'; 
        }
        $is_ha = 1;
    }

    # Fetch serial numbers for each detected instance (useful for display in HA)
    foreach my $inst (@$ha_instances) {
        my $oid_serial = "$oid_snsFwSerial.$inst";
        my $serial_res = $options{snmp}->get_leef(oids => [$oid_serial], nothing_quit => 0);
        if (defined $serial_res && defined $serial_res->{$oid_serial}) {
            $serials->{$inst} = $serial_res->{$oid_serial};
        } else {
            $serials->{$inst} = "Unknown";
        }
    }

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    my $licence_count_total = 0;


    # Define OIDs based on HA or non-HA mode
    # Stormshield uses different MIB for HA clusters vs standalone devices    
    my $oid_table;
    my $oid_index_base;
    my $oid_name_base;
    my $oid_exp_base;
    
    if ($is_ha) {
        $oid_table = '.1.3.6.1.4.1.11256.1.11.14.1';                # oid_snsNodeLicenceOptionEntry
        $oid_index_base = '.1.3.6.1.4.1.11256.1.11.14.1.1';         # oid_snsNodeLicenceOptionIndex
        $oid_name_base = '.1.3.6.1.4.1.11256.1.11.14.1.2';          # oid_snsNodeLicenceOptionName
        $oid_exp_base = '.1.3.6.1.4.1.11256.1.11.14.1.3';           # oid_snsNodeLicenceExpirationDate
    } else {
        $oid_table = '.1.3.6.1.4.1.11256.1.21.1.1';                 # oid_snsLicenceOptionEntry
        $oid_index_base = '.1.3.6.1.4.1.11256.1.21.1.1.1';          # oid_snsLicenceOptionIndex
        $oid_name_base = '.1.3.6.1.4.1.11256.1.21.1.1.2';           # oid_snsLicenceOptionName
        $oid_exp_base = '.1.3.6.1.4.1.11256.1.21.1.1.3';            # oid_snsLicenceExpirationDate
    }

    my $snmp_lic_result = $options{snmp}->get_table(
        oid         => $oid_table,
        nothing_quit => 0 
    );

    if (!defined $snmp_lic_result || scalar(keys %{$snmp_lic_result}) == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'No valid licences found (SNMP table empty)'
        );
        return;
    }

    $GLOBAL_PROBLEM = 0;

    # Iterate over each firewall instance (HA node or single node)
    foreach my $fw_instance (@$ha_instances) {
        my $display_name = '';
        if (scalar(@$ha_instances) > 1) {
            $display_name = $serials->{$fw_instance} // 'Unknown';
        }

        $self->{firewalls}->{$fw_instance} = {
            display => $display_name,
            licences => {}
        };

        foreach my $oid (sort keys %{$snmp_lic_result}) {
            my $index;
            my $instance_id;
            
            if ($is_ha) {
                # In HA mode, OID structure is: base.instance.index
                # We must filter to ensure we only process licenses for the current $fw_instance
                if ($oid =~ /^$oid_index_base\.(\d+)\.(\d+)$/) {
                    $instance_id = $1;
                    $index = $2;
                    next unless $instance_id eq $fw_instance;
                } else {
                    next;
                }
            } else {
                # In Single Node mode, OID structure is: base.index
                if ($oid =~ /^$oid_index_base\.(.*)$/) {
                    $index = $1;
                } else {
                    next;
                }
            }

            my $name_oid = $is_ha ? "$oid_name_base.$fw_instance.$index" : "$oid_name_base.$index";
            my $exp_oid = $is_ha ? "$oid_exp_base.$fw_instance.$index" : "$oid_exp_base.$index";

            my $name     = $snmp_lic_result->{$name_oid};
            my $exp_date = $snmp_lic_result->{$exp_oid};

            if (!defined $name || $name eq '' || !defined $exp_date || $exp_date eq '' || $exp_date eq 'N/A' || $exp_date eq '0000-00-00') {
                next;
            }

            my ($year, $month, $day);
            if ($exp_date =~ /^\s*(\d{4})-(\d{2})-(\d{2})\s*$/) {
                ($year, $month, $day) = ($1, $2, $3);
            } else {
                next;
            }

            my $dt = DateTime->new(
                year   => $year,
                month  => $month,
                day    => $day,
                hour   => 0,
                minute => 0,
                second => 0,
                %$tz
            );
            
            my $seconds_left = $dt->epoch - time();
            my $days_left = int($seconds_left / 86400);

            if ($seconds_left < 0 || $days_left <= $GLOBAL_WARNING_THRESHOLD){
                $GLOBAL_PROBLEM = 1;
            }

            $self->{firewalls}->{$fw_instance}->{licences}->{$index} = {
                name        => $name,
                exp_date    => $exp_date,
                days_left   => $days_left,
                seconds_left => $seconds_left
            };
            $licence_count_total++;
        }
    }

    if ($licence_count_total == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'No valid licences found'
        );
        $self->{firewalls} = {}; 
        return;
    }   
    
}

1;

__END__

=head1 MODE

This mode allows you to retrieve and display the licenses for the Stormshield device, as well as their expiration dates.
It automatically supports high-availability (HA) configurations by detecting the nodes in the cluster.

=over 8

=item B<--warning-days>

Warning threshold for the number of days remaining before expiration (default: 60).

=item B<--timezone>

Timezone options. Default is 'CET'.

=back

=cut