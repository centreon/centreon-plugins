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
# distributed under the distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::stormshield::snmp::mode::auto_update;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc;

sub custom_auto_update_output {
    my ($self, %options) = @_;

    my $state = $self->{result_values}->{state};
    my $last_date = $self->{result_values}->{last_date} // 'N/A';
    my $display = $self->{result_values}->{display};

    my $msg = "";
    
    if ($state eq 'Uptodate') {
        $msg = "$display is up to date";
    } elsif ($state eq 'Disabled') {
        $msg = "$display is disabled";
    } elsif ($state eq 'NeverStarted') {
        $msg = "$display never started";
    } else {
        $msg = "$display $state (Last Update: $last_date)";
    }
    
    if (!$self->{output}->{long_msg_added}) {
        $self->{output}->{long_msg_added} = 1;
        $self->{output}->output_add(
            long_msg => "-----------------------------------------------------------------------\n"
        );
    }
    
    return $msg;
    
}

sub custom_auto_update_threshold_check {
    my ($self, %options) = @_;
    
    my $state = $self->{result_values}->{state};

    if ($state eq 'Failed' || $state eq 'Broken') {
        return 'CRITICAL';
    } elsif ($state eq 'Partially Failed') {
        return 'WARNING';
    } elsif ($state eq 'Disabled' || $state eq 'NeverStarted') {
        return 'OK';
    } else {
        return 'OK';
    }
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { 
            name => 'updates', 
            type => COUNTER_TYPE_INSTANCE,
            message_multiple => 'All Updates and Webservices are up to date',
            skipped_code => { -10 => 1 } 
        }
    ];

    $self->{maps_counters}->{updates} = [
        {
            label => 'status',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'display' },
                    { name => 'state' },
                    { name => 'last_date' }
                ],
                closure_custom_output => $self->can('custom_auto_update_output'),
                closure_custom_threshold_check => $self->can('custom_auto_update_threshold_check'),
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{updates} = {};

    my $oid_snsAutoupdateEntry   = '.1.3.6.1.4.1.11256.1.9.1.1';
    my $oid_snsAutoupdateIndex   = '.1.3.6.1.4.1.11256.1.9.1.1.1';
    my $oid_snsAutoupdateSubsys  = '.1.3.6.1.4.1.11256.1.9.1.1.2';
    my $oid_snsAutoupdateState   = '.1.3.6.1.4.1.11256.1.9.1.1.3';
    my $oid_snsAutoupdateLast    = '.1.3.6.1.4.1.11256.1.9.1.1.4';

    my $oid_snsCustomWebServicesEntry  = '.1.3.6.1.4.1.11256.1.9.2.1';
    my $oid_snsCustomWebServicesIndex  = '.1.3.6.1.4.1.11256.1.9.2.1.1';
    my $oid_snsCustomWebServicesName   = '.1.3.6.1.4.1.11256.1.9.2.1.2';
    my $oid_snsCustomWebServicesState  = '.1.3.6.1.4.1.11256.1.9.2.1.3';
    my $oid_snsCustomWebServicesLast   = '.1.3.6.1.4.1.11256.1.9.2.1.4';


    my $oid_snsVersion = '.1.3.6.1.4.1.11256.1.18.2.0';
    my $snmp_result_version = $options{snmp}->get_leef(oids => [ $oid_snsVersion ], nothing_quit => 1);
    my $version_clean = '';
    
    if (defined $snmp_result_version && defined $snmp_result_version->{$oid_snsVersion}) {
        $version_clean = $snmp_result_version->{$oid_snsVersion};
        $version_clean =~ s/([0-9]+(?:\.[0-9]+)*).*/$1/;
    }

    my $snmp_result_update = $options{snmp}->get_table(
        oid         => $oid_snsAutoupdateEntry,
        nothing_quit => 0
    );

    my $snmp_result_webservice = {};
    
    # The MIB WebService is available only starting with version 5.1.0
    if (defined $version_clean && centreon::plugins::misc::minimal_version($version_clean, '5.1.0')) {
        $snmp_result_webservice = $options{snmp}->get_table(
            oid         => $oid_snsCustomWebServicesEntry,
            nothing_quit => 0
        );
    }

    $self->process_table(
        snmp_result => $snmp_result_update,
        index_oid   => $oid_snsAutoupdateIndex,
        name_oid    => $oid_snsAutoupdateSubsys,
        state_oid   => $oid_snsAutoupdateState,
        date_oid    => $oid_snsAutoupdateLast,
        prefix      => 'Update'
    );

    if (scalar(keys %{$snmp_result_webservice}) > 0) {
        $self->process_table(
            snmp_result => $snmp_result_webservice,
            index_oid   => $oid_snsCustomWebServicesIndex,
            name_oid    => $oid_snsCustomWebServicesName,
            state_oid   => $oid_snsCustomWebServicesState,
            date_oid    => $oid_snsCustomWebServicesLast,
            prefix      => 'WebService'
        );
    }

    if (scalar(keys %{$self->{updates}}) == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'No updates or web services found.'
        );
        $self->{updates} = {};
        return;
    }
}

sub process_table {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp_result};
    my $index_oid   = $options{index_oid};
    my $name_oid    = $options{name_oid};
    my $state_oid   = $options{state_oid};
    my $date_oid    = $options{date_oid};
    my $prefix      = $options{prefix};

    foreach my $oid (sort keys %{$snmp_result}) {
        next unless $oid =~ /^$index_oid\./;
    
        my $index = $oid;
        $index =~ s/^$index_oid\.//;

        my $name     = $snmp_result->{"$name_oid.$index"} // 'N/A';
        my $state    = $snmp_result->{"$state_oid.$index"}  // 'N/A';
        my $lastDate = $snmp_result->{"$date_oid.$index"}   // 'N/A';

        my $normalized_state = $state;
        if ($normalized_state eq 'Disabled') {
            $normalized_state = 'Disabled';
        } elsif ($normalized_state !~ /^(Uptodate|Failed|Broken|Partially Failed)/) {
            $normalized_state = 'NeverStarted';
        }

        $self->{updates}->{$prefix . '_' . $index} = {
            display => $prefix . ': ' . $name,
            state   => $normalized_state,
            last_date => $lastDate
        };
    }
}

1;

__END__

=head1 MODE

This mode allows you to monitor the status of auto-updates and web services on a Stormshield device.
It checks for failed, broken, or partially failed updates and reports their status.

=over 8

=back

=cut