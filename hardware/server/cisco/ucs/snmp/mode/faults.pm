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

package hardware::server::cisco::ucs::snmp::mode::faults;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use POSIX;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_severity = {
    0 => 'cleared', 1 => 'info', 2 => 'condition',
    3 => 'warning', 4 => 'minor', 5 => 'major',
    6 => 'critical'
};

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'fault [severity: %s] [dn: %s] [description: %s] %s',
        $self->{result_values}->{severity},
        $self->{result_values}->{dn},
        $self->{result_values}->{description},
        scalar(localtime($self->{result_values}->{created}))
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Faults ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'faults', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { nlabel => 'faults.problems.current.count', min => 0 },
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

    foreach (values %$map_severity) {
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
                    { name => 'dn' }, { name => 'severity' },
                    { name => 'description' }, { name => 'created' }
                ],
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
        'filter-message:s'   => { name => 'filter_message' },
        'retention:s'        => { name => 'retention' },
        'memory'             => { name => 'memory' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub get_timestamp {
    my ($self, %options) = @_;

    my $currentTmsp = 0;
    my $value = $options{value};
    if ($value =~ /^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/) {
        $currentTmsp = mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
    } else {
        $value = unpack('H*', $value);
        $value =~ /^([0-9a-z]{4})([0-9a-z]{2})([0-9a-z]{2})([0-9a-z]{2})([0-9a-z]{2})([0-9a-z]{2})/;
	    $currentTmsp = mktime(hex($6), hex($5), hex($4), hex($3), hex($2) - 1, hex($1) - 1900);
    }

    return $currentTmsp;
}

my $mapping = {
    dn          => { oid => '.1.3.6.1.4.1.9.9.719.1.1.1.1.2' },  # cucsFaultDn
    created     => { oid => '.1.3.6.1.4.1.9.9.719.1.1.1.1.10' }, # cucsFaultCreationTime
    description => { oid => '.1.3.6.1.4.1.9.9.719.1.1.1.1.11' }, # cucsFaultDescription
    severity    => { oid => '.1.3.6.1.4.1.9.9.719.1.1.1.1.20', map => $map_severity } # cucsFaultSeverity
};

sub manage_selection {
    my ($self, %options) = @_;

    my $datas = {};
    my ($start, $last_instance);
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_ciscoucs_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
        $start = $self->{statefile_cache}->get(name => 'start');
        $start = $start - 1 if (defined($start));
    }

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ map({ oid => $_->{oid}, start => $_->{oid} . (defined($start) ? '.' . $start : '') }, values(%$mapping)) ],
        return_type => 1
    );

    $self->{global} = {
        total => 0, cleared => 0, info => 0, condition => 0,
        warning => 0, minor => 0, major => 0, critical => 0
    };
    $self->{faults} = { global => { fault => {} } };
    my ($i, $current_time) = (1, time());
    foreach my $oid ($options{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{dn}->{oid}\.(\d+)$/);
        my $instance = $1;
        if (defined($self->{option_results}->{memory})) {
            $last_instance = $instance;
            next if (defined($start) && ($start + 1) >= $instance); # we skip last one from previous check)
        }

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{description} = centreon::plugins::misc::trim($result->{description});
        $result->{created} = $self->get_timestamp(value => $result->{created});
        if (defined($self->{option_results}->{retention})) {
            next if ($current_time - $result->{created} > $self->{option_results}->{retention});
        }

        $self->{global}->{total}++;
        next if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' && $result->{description} !~ /$self->{option_results}->{filter_message}/);

        $self->{faults}->{global}->{fault}->{$i} = $result;
        $self->{global}->{ $result->{severity} }++;
        $i++;
    }

    if (defined($self->{option_results}->{memory})) {
        $datas->{start} = $last_instance;
        $self->{statefile_cache}->write(data => $datas);
    }
}

1;

__END__

=head1 MODE

Check faults.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /minor|warning/')
Can used special variables like: %{severity}, %{description}, %{dn}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /major|critical/').
Can used special variables like: %{severity}, %{description}, %{dn}

=item B<--memory>

Only check new fault.

=item B<--filter-message>

Filter on event message. (Default: none)

=item B<--retention>

Event older (current time - retention time) is not checked (in seconds).

=back

=cut
