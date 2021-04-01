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

package network::cisco::firepower::fxos::snmp::mode::faults;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "fault '%s' [severity: %s] [type: %s] [ack: %s] [description: %s] %s",
        $self->{result_values}->{object},
        $self->{result_values}->{severity},
        $self->{result_values}->{type},
        $self->{result_values}->{acknowledged},
        $self->{result_values}->{description},
        $self->{result_values}->{generation_time}
    );
}


sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Faults ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'faults', type => 2, message_multiple => '0 fault(s) detected', display_counter_problem => { nlabel => 'faults.problems.current.count', min => 0 },
          group => [ { name => 'fault', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'faults-total', nlabel => 'faults.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    foreach (('critical', 'major', 'warning', 'minor', 'info')) {
        push @{$self->{maps_counters}->{global}},
            { label => 'faults-' . $_, nlabel => 'faults.' . $_ . '.count', display_ok => 0, set => {
                    key_values => [ { name => $_ }, { name => 'total' } ],
                    output_template => $_ . ': %s',
                    perfdatas => [
                        { template => '%s', min => 0, max => 'total' }
                    ]
                }
            };
    }


    $self->{maps_counters}->{fault} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{severity} =~ /minor|warning/',
            critical_default => '%{severity} =~ /major|critical/',
            set => {
                key_values => [
                    { name => 'severity' }, { name => 'type' },
                    { name => 'acknowledged'}, { name => 'since' },
                    { name => 'object' }, { name => 'description' },
                    { name => 'generation_time' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'memory'              => { name => 'memory' },
        'timezone:s'          => { name => 'timezone' }
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'DateTime',
        error_msg => "Cannot load module 'DateTime'."
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }

    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

my $map_ack = { 1 => 'yes', 2 => 'no' };
my $map_severity = {
    0 => 'cleared', 1 => 'info', 2 => 'condition',
    3 => 'warning', 4 => 'minor',
    5 => 'major', 6 => 'critical'
};
my $map_type = {
    0 => 'generic', 1 => 'configuration', 2 => 'fsm',
    3 => 'network', 4 => 'server', 5 => 'management',
    6 => 'equipment', 7 => 'environmental', 8 => 'operational',
    9 => 'connectivity', 10 => 'security',
    11 => 'sysdebug', 65536 => 'any'
};

my $mapping = {
    object       => { oid => '.1.3.6.1.4.1.9.9.826.1.1.1.1.2' }, # cfprFaultInstDn
    acknowledged => { oid => '.1.3.6.1.4.1.9.9.826.1.1.1.1.6', map => $map_ack }, # cfprFaultInstAck
    created      => { oid => '.1.3.6.1.4.1.9.9.826.1.1.1.1.10' }, # cfprFaultInstCreated
    description  => { oid => '.1.3.6.1.4.1.9.9.826.1.1.1.1.11' }, # cfprFaultInstDescr
    severity     => { oid => '.1.3.6.1.4.1.9.9.826.1.1.1.1.20', map => $map_severity }, # cfprFaultInstSeverity
    type         => { oid => '.1.3.6.1.4.1.9.9.826.1.1.1.1.22', map => $map_type } # cfprFaultInstType
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ map({ oid => $_->{oid} }, values(%$mapping)) ],
        return_type => 1
    );

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cisco_firepower_fxos_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    $self->{global} = { total => 0, critical => 0, major => 0, warning => 0, minor => 0, info => 0 };
    $self->{faults}->{global} = { fault => {} };

    my $current_time = time();
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{severity}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        my @date = unpack 'n C6 a C2', $result->{created};
        my $timezone = $self->{option_results}->{timezone};
        if (defined($date[8])) {
            $timezone = sprintf("%s%02d%02d", $date[7], $date[8], $date[9]);
        }

        my $tz = centreon::plugins::misc::set_timezone(name => $timezone);
        my $dt = DateTime->new(
            year => $date[0], month => $date[1], day => $date[2], hour => $date[3], minute => $date[4], second => $date[5],
            %$tz
        );

        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $dt->epoch);

        my $diff_time = $current_time - $dt->epoch();

        $self->{faults}->{global}->{fault}->{ $result->{object} } = {
            since => $diff_time,
            generation_time => centreon::plugins::misc::change_seconds(value => $diff_time),
            %$result
        };

        $self->{global}->{total}++;
        $self->{global}->{ $result->{severity} }++
            if (defined($self->{global}->{ $result->{severity} }));
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}
        
1;

__END__

=head1 MODE

Check faults.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /minor|warning/).
Can used special variables like: %{description}, %{object}, %{severity}, %{type}, %{acknowledged}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /major|critical/').
Can used special variables like: %{description}, %{object}, %{severity}, %{type}, %{since}

=item B<--timezone>

Timezone options (the date from the equipment overload that option). Default is 'GMT'.

=item B<--memory>

Only check new alarms.

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'faults-total', 'faults-critical', 'faults-major', 'faults-warning', 'faults-minor', 'faults-info'. 

=back

=cut
