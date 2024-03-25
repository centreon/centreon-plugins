#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package os::windows::snmp::mode::service;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "state is '" . $self->{result_values}->{operating_state};
    $msg .= "' [installed state: '" . $self->{result_values}->{installed_state} . "']";
    return $msg;
}

sub prefix_services_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Number of services ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'services', type => 1, cb_prefix_output => 'prefix_services_output',
          message_multiple => 'All services are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'services.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'active', nlabel => 'services.active.count', display_ok => 0, set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'continue-pending', nlabel => 'services.continue.pending.count', display_ok => 0, set => {
                key_values => [ { name => 'continue-pending' } ],
                output_template => 'continue pending: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'pause-pending', nlabel => 'services.pause.pending.count', display_ok => 0, set => {
                key_values => [ { name => 'pause-pending' } ],
                output_template => 'pause pending: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'paused', nlabel => 'services.paused.count', display_ok => 0, set => {
                key_values => [ { name => 'paused' } ],
                output_template => 'Service paused: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{services} = [
        { label => 'status', type => 2, set => {
                key_values => [ { name => 'operating_state' }, { name => 'installed_state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' },
        'warning:s'  => { name => 'warning' }, # deprecated
        'critical:s' => { name => 'critical' }, # deprecated
        'service:s@' => { name => 'service' }, # deprecated
        'regexp'     => { name => 'use_regexp' }, # deprecated
        'state:s'    => { name => 'state' } # deprecated
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    
    # Compatibility for deprecated options
    if (defined($options{option_results}->{warning}) && $options{option_results}->{warning} ne '') {
        $options{option_results}->{'warning-services-active-count'} = $options{option_results}->{warning};
    }
    if (defined($options{option_results}->{critical}) && $options{option_results}->{critical} ne '') {
        $options{option_results}->{'critical-services-active-count'} = $options{option_results}->{critical};
    }

    my $delimiter = '';
    if (defined($options{option_results}->{service})) {
        my $filter = '';
        for my $filter_service (@{$options{option_results}->{service}}) {
            next if ($filter_service eq '');
            if (defined($options{option_results}->{use_regexp})) {
                $filter.= $delimiter . $filter_service;
            } else {
                $filter .= $delimiter . quotemeta($filter_service);
            }

            $delimiter = '|';
        }

        if ($filter ne '' && !defined($options{option_results}->{use_regexp})) {
            $filter = '^(' . $filter . ')$';
        }

        if (!defined($options{option_results}->{'filter_name'}) || $options{option_results}->{'filter_name'} eq '') {
            $options{option_results}->{'filter_name'} = $filter;
        }
    }

    if (defined($options{option_results}->{state}) && $options{option_results}->{state} ne '') {
        $options{option_results}->{'critical-status'} = "%{operating_state} !~ /$options{option_results}->{state}/";
    }
    
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_installed_state = {
        1 => 'uninstalled', 
        2 => 'install-pending', 
        3 => 'uninstall-pending', 
        4 => 'installed'
    };
    
    my $map_operating_state = {
        1 => 'active',
        2 => 'continue-pending',
        3 => 'pause-pending',
        4 => 'paused'
    };

    my $mapping = {
        installed_state  => { oid => '.1.3.6.1.4.1.77.1.2.3.1.2', map => $map_installed_state }, # svSvcInstalledState
        operating_state  => { oid => '.1.3.6.1.4.1.77.1.2.3.1.3', map => $map_operating_state } # svSvcOperatingState
    };
    my $table_svSvcEntry = '.1.3.6.1.4.1.77.1.2.3.1';

    my $snmp_result = $options{snmp}->get_table(
        oid => $table_svSvcEntry,
        start => $mapping->{installed_state}->{oid},
        end => $mapping->{operating_state}->{oid},
        nothing_quit => 1
    );

    $self->{global} = {
        total => 0,
        active => 0,
        'continue-pending' => 0,
        'pause-pending' => 0,
        paused => 0
    };

    $self->{services} = {};

    foreach my $oid ($options{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{operating_state}->{oid}\.(\d+)\.(.*)$/);
        my $instance = $1 . '.' . $2;

        my $name = $self->{output}->decode(join('', map(chr($_), split(/\./, $2))));
        $self->{option_results}->{filter_name} = $self->{output}->decode($self->{option_results}->{filter_name});
        
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );

        $self->{services}->{$instance} = {
            name => $name,
            operating_state => $result->{operating_state},
            installed_state => $result->{installed_state}
        };

        $self->{global}->{total}++;
        $self->{global}->{ $result->{operating_state} }++;
    }
}

1;

__END__

=head1 MODE

Check Windows services states

=over 8

=item B<--filter-name>

Filter by service name (can be a regexp).

=item B<--warning-status> B<--critical-status>

Set WARNING or CRITICAL threshold for status.
You can use the following variables: %{operating_state}, %{installed_state}.

=item B<--warning-*> B<--critical-*>

Thresholds on services count.
Can be: 'total', 'active', 'continue-pending',
'pause-pending', 'paused'.

=item B<--warning>

DEPRECATED. Use --warning-active instead.

=item B<--critical>

DEPRECATED. Use --critical-active instead.

=item B<--service>

DEPRECATED. Use --filter-name instead.

=item B<--regexp>

DEPRECATED. Use --filter-name instead.

=item B<--state>

DEPRECATED. Use --critical/warning-status instead.

=back

=cut
