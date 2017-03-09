#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::citrix::netscaler::snmp::mode::vserverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vservers', type => 1, cb_prefix_output => 'prefix_vservers_output', message_multiple => 'All Virtual Servers are ok' }
    ];
    
    $self->{maps_counters}->{vservers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'health', set => {
                key_values => [ { name => 'health' }, { name => 'display' } ],
                output_template => 'Health: %.2f %%', output_error_template => 'Health: %s',
                perfdatas => [
                    { value => 'health_absolute', label => 'health', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_vservers_output {
    my ($self, %options) = @_;
    
    return "Virtual Server '" . $options{instance_value}->{display} . "' ";
}

my $overload_th = {};

my $thresholds = {
    vs => [
        ['unknown', 'UNKNOWN'],
        ['down|outOfService|transitionToOutOfService|transitionToOutOfServiceDown', 'CRITICAL'],
        ['up', 'OK'],
    ],
};

sub get_severity {
    my (%options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($overload_th->{$options{section}})) {
        foreach (@{$overload_th->{$options{section}}}) {            
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

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return get_severity(section => 'vs', value => $self->{result_values}->{state});
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'State : ' . $self->{result_values}->{state};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "filter-type:s"           => { name => 'filter_type' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('vs', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $overload_th->{$section} = [] if (!defined($overload_th->{$section}));
        push @{$overload_th->{$section}}, {filter => $filter, status => $status};
    }
}

my %map_vs_type = (
    0 => 'unknown', 
    1 => 'loadbalancing', 
    2 => 'loadbalancinggroup', 
    3 => 'sslvpn', 
    4 => 'contentswitching', 
    5 => 'cacheredirection',
);

my %map_vs_status = (
    1 => 'down', 
    2 => 'unknown', 
    3 => 'busy', 
    4 => 'outOfService', 
    5 => 'transitionToOutOfService', 
    7 => 'up',
    8 => 'transitionToOutOfServiceDown',
);

my $mapping = {
    vsvrName        => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.1' },
    vsvrState       => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.5', map => \%map_vs_status },
    vsvrHealth      => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.62' },
    vsvrEntityType  => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.64', map => \%map_vs_type },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{vsvrName}->{oid} },
                                                            { oid => $mapping->{vsvrState}->{oid} },
                                                            { oid => $mapping->{vsvrHealth}->{oid} },
                                                            { oid => $mapping->{vsvrEntityType}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{vservers} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vsvrName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{vsvrEntityType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '" . $result->{vsvrName} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vsvrName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '" . $result->{vsvrName} . "'.", debug => 1);
            next;
        }
        
        $self->{vservers}->{$instance} = {
            display => $result->{vsvrName},
            health  => $result->{vsvrHealth},
            state   => $result->{vsvrState},
        };
    }
    
    if (scalar(keys %{$self->{vservers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual server found.");
        $self->{output}->option_exit();
    }    
}

1;

__END__

=head1 MODE

Check vservers status and health.

=over 8

=item B<--warning-health>

Threshold warning in percent.

=item B<--critical-health>

Threshold critical in percent.

=item B<--filter-name>

Filter by virtual server name (can be a regexp).

=item B<--filter-type>

Filter which type of vserver (can be a regexp).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(green)$)'

=back

=cut
