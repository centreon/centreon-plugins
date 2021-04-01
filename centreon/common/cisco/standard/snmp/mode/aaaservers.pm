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

package centreon::common::cisco::standard::snmp::mode::aaaservers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_aaa_output {
    my ($self, %options) = @_;

    return sprintf(
        "Server '%s' [protocol: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{protocol}
    );
}

sub aaa_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking server '%s' [protocol: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{protocol}
    );
}

sub prefix_auth_output {
    my ($self, %options) = @_;

    return 'authentication ';
}

sub prefix_acc_output {
    my ($self, %options) = @_;

    return 'accounting ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'aaa', type => 3, cb_prefix_output => 'prefix_aaa_output', cb_long_output => 'aaa_long_output', indent_long_output => '    ', message_multiple => 'All AAA servers are ok',
            group => [
                { name => 'global_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_auth', type => 0, cb_prefix_output => 'prefix_auth_output', skipped_code => { -10 => 1 } },
                { name => 'global_acc', type => 0, cb_prefix_output => 'prefix_acc_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'aaa_servers.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total servers: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_status} = [
        {
            label => 'status', type => 2, critical_default => '%{status} =~ /dead/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global_auth} = [
        { label => 'auth-requests', nlabel => 'aaa_server.authentication.requests.persecond', set => {
                key_values => [ { name => 'auth_requests', per_second => 1 } ],
                output_template => 'requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'auth-requests-timeout', nlabel => 'aaa_server.authentication.requests.timeout.count', set => {
                key_values => [ { name => 'auth_timeouts', diff => 1 } ],
                output_template => 'requests timeout: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'auth-transactions-suceeded', nlabel => 'aaa_server.authentication.transactions.succeeded.persecond', set => {
                key_values => [ { name => 'auth_trans_success', per_second => 1 } ],
                output_template => 'transactions succeeded: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'auth-roundtrip-time', nlabel => 'aaa_server.authentication.roundtrip.time.milliseconds', set => {
                key_values => [ { name => 'auth_reponse_time' } ],
                output_template => 'round trip time: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_acc} = [
        { label => 'acc-requests', nlabel => 'aaa_server.accounting.requests.persecond', set => {
                key_values => [ { name => 'acc_requests', per_second => 1 } ],
                output_template => 'requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'acc-requests-timeout', nlabel => 'aaa_server.accounting.requests.timeout.count', set => {
                key_values => [ { name => 'acc_timeouts', diff => 1 } ],
                output_template => 'requests timeout: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'acc-transactions-suceeded', nlabel => 'aaa_server.accounting.transactions.succeeded.persecond', set => {
                key_values => [ { name => 'acc_trans_success', per_second => 1 } ],
                output_template => 'transactions succeeded: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'acc-roundtrip-time', nlabel => 'aaa_server.accounting.roundtrip.time.milliseconds', set => {
                key_values => [ { name => 'acc_reponse_time' } ],
                output_template => 'round trip time: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $map_protocol = {
    1 => 'tacacsplus', 2 => 'radius', 3 => 'ldap',
    4 => 'kerberos', 5 => 'ntlm', 6 => 'sdi',
    7 => 'other'
};
my $map_status = { 1 => 'up', 2 => 'dead' };

my $mapping = {
    auth_requests      => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.1' }, # casAuthenRequests
    auth_timeouts      => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.2' }, # casAuthenRequestTimeouts
    auth_reponse_time  => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.6' }, # casAuthenResponseTime (unit 0.01 of sec)
    auth_trans_success => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.7' }, # casAuthenTransactionSuccesses
    acc_requests       => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.17' }, # casAcctRequests
    acc_timeouts       => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.18' }, # casAcctRequestTimeouts
    acc_reponse_time   => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.22' }, # casAcctResponseTime (unit 0.01 of sec)
    acc_trans_success  => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.23' }, # casAcctTransactionSuccesses
    status             => { oid => '.1.3.6.1.4.1.9.10.56.1.2.1.1.25', map => $map_status } # casState
};
my $mapping_name = {
    address     => { oid => '.1.3.6.1.4.1.9.10.56.1.1.2.1.3' }, # casAddress
    authen_port => { oid => '.1.3.6.1.4.1.9.10.56.1.1.2.1.4' }, # casAuthenPort
    acc_port    => { oid => '.1.3.6.1.4.1.9.10.56.1.1.2.1.5' }  # casAcctPort
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'cisco_standard_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

    my $oid_casConfigEntry = '.1.3.6.1.4.1.9.10.56.1.1.2.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_casConfigEntry,
        start => $mapping_name->{address}->{oid},
        end => $mapping_name->{acc_port}->{oid},
        nothing_quit => 1
    );

    $self->{aaa} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_name->{address}->{oid}\.((\d+).*)$/);
        my ($instance, $protocol) = ($1, $map_protocol->{$2});
        my $result = $options{snmp}->map_instance(mapping => $mapping_name, results => $snmp_result, instance => $instance);

        my $name = $result->{address} . ':' . $result->{authen_port} . ':' . $result->{acc_port};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{aaa}->{$name} = {
            %$result,
            name => $name,
            protocol => $protocol,
            instance => $instance
        };
    }

    $self->{global} = { total => scalar(keys %{$self->{aaa}}) };

    return if (scalar(keys %{$self->{aaa}}) <= 0);

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [map($_->{instance}, values(%{$self->{aaa}}))],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{aaa}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{aaa}->{$_}->{instance});

        $self->{aaa}->{$_}->{global_status} = {
            name => $self->{aaa}->{$_}->{name},
            status => $result->{status}
        };
        $self->{aaa}->{$_}->{global_auth} = {
            auth_requests => $result->{auth_requests},
            auth_timeouts => $result->{auth_timeouts},
            auth_trans_success => $result->{auth_trans_success},
            auth_reponse_time => $result->{auth_reponse_time} * 10
        };
        $self->{aaa}->{$_}->{global_acc} = {
            acc_requests => $result->{acc_requests},
            acc_timeouts => $result->{acc_timeouts},
            acc_trans_success => $result->{acc_trans_success},
            acc_reponse_time => $result->{acc_reponse_time} * 10
        };
    }
}

1;

__END__

=head1 MODE

Check AAA servers.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='auth'

=item B<--filter-name>

Filter AAA server by name (E.g.: 10.199.126.100:1812:1813. Format: [address]:[authPort]:[accPort]).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /dead/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total',
'auth-requests', 'auth-requests-timeout', 'auth-transactions-suceeded', 'auth-roundtrip-time',
'acc-requests', 'acc-requests-timeout', 'acc-transactions-suceeded', 'acc-roundtrip-time'.

=back

=cut
