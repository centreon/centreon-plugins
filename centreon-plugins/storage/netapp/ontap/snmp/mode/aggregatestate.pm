#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::netapp::ontap::snmp::mode::aggregatestate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_state_threshold {
    my ($self, %options) = @_;
    
    return $self->{instance_mode}->get_severity(section => 'state', value => $self->{result_values}->{aggrState});
}

sub custom_state_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{aggrState} = $options{new_datas}->{$self->{instance} . '_aggrState'};
    return 0;
}

sub custom_status_threshold {
    my ($self, %options) = @_;
    
    return $self->{instance_mode}->get_severity(section => 'status', value => $self->{result_values}->{aggrStatus});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{aggrStatus} = $options{new_datas}->{$self->{instance} . '_aggrStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'agg', type => 1, cb_prefix_output => 'prefix_agg_output', message_multiple => 'All aggregates are ok' },
    ];
    
    $self->{maps_counters}->{agg} = [
        { label => 'state', set => {
                key_values => [ { name => 'aggrState' } ],
                closure_custom_calc => $self->can('custom_state_calc'),
                output_template => "State : '%s'", output_error_template => "State : '%s'",
                output_use => 'aggrState',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_state_threshold'),
            }
        },
        { label => 'status', set => {
                key_values => [ { name => 'aggrStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => "Status : '%s'", output_error_template => "Status : '%s'",
                output_use => 'aggrStatus',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub prefix_agg_output {
    my ($self, %options) = @_;

    return "Aggregate '" . $options{instance_value}->{aggrName} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'         => { name => 'filter_name' },
        'threshold-overload:s@' => { name => 'threshold_overload' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

my $thresholds = {
    state => [
        ['online', 'OK'],
        ['offline', 'CRITICAL'],
    ],
    status => [
        ['normal', 'OK'],
        ['mirrored', 'OK'],
        ['.*', 'CRITICAL'],
    ],
};

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_aggrName = '.1.3.6.1.4.1.789.1.5.11.1.2';
    my $oid_aggrState = '.1.3.6.1.4.1.789.1.5.11.1.5';
    my $oid_aggrStatus = '.1.3.6.1.4.1.789.1.5.11.1.6';
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_aggrName },
            { oid => $oid_aggrState },
            { oid => $oid_aggrStatus },
        ],
        nothing_quit => 1
    );

    $self->{agg} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_aggrState}}) {
        next if ($oid !~ /^$oid_aggrState\.(.*)$/);
        my $instance = $1;
        my $name = $snmp_result->{$oid_aggrName}->{$oid_aggrName . '.' . $instance};
        my $state = $snmp_result->{$oid_aggrState}->{$oid_aggrState . '.' . $instance};
        my $status = $snmp_result->{$oid_aggrStatus}->{$oid_aggrStatus . '.' . $instance};
        
        if (!defined($state) || $state eq '') {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': state value not set.");
            next;
        } 
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.");
            next;
        }
        
        $self->{agg}->{$instance} = { aggrName => $name, aggrState => $state, aggrStatus => $status};
    }
    
    if (scalar(keys %{$self->{agg}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No aggregate found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check state and status from aggregates.

=over 8

=item B<--filter-name>

Filter by aggregate name.

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='state,CRITICAL,^(?!(online)$)'

=back

=cut
