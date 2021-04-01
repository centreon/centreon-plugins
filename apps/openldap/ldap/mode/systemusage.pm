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

package apps::openldap::ldap::mode::systemusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::common::protocols::ldap::lib::ldap;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
        { name => 'operation', type => 0, cb_prefix_output => 'prefix_operation_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{operation} = [];
    foreach ('search', 'add', 'bind', 'unbind', 'delete') {
        push @{$self->{maps_counters}->{operation}}, 
            { label => 'op-' . $_, nlabel => 'system.operations.' . $_ . '.completed.count', set => {
                    key_values => [ { name => 'operations_completed_' . $_, diff => 1 } ],
                    output_template => $_ . ' %s',
                    perfdatas => [
                        { label => 'operations_' . $_, template => '%.2f', min => 0 }
                    ]
                }
            };
    }
    
    
    $self->{maps_counters}->{global} = [
        { label => 'con-current', nlabel => 'system.connections.current.count', set => {
                key_values => [ { name => 'connections_current' } ],
                output_template => 'Current connections %s',
                perfdatas => [
                    { label => 'connections_current', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'con-total', nlabel => 'system.connections.total.count', set => {
                key_values => [ { name => 'connections_total', diff => 1 } ],
                output_template => 'Total connections %s',
                perfdatas => [
                    { label => 'connections_total', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'threads-active', nlabel => 'system.threads.active.percentage', set => {
                key_values => [ { name => 'threads_active_prct' } ],
                output_template => 'Current active threads %.2f %%',
                perfdatas => [
                    { label => 'threads_active', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'traffic',  nlabel => 'system.traffic.bytespersecond', set => {
                key_values => [ { name => 'traffic', per_second => 1 } ],
                output_template => 'traffic %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'traffic', template => '%s', min => 0, unit => 'B/s', cast_int => 1 },
                ]
            }
        }
    ];
}

sub prefix_operation_output {
    my ($self, %options) = @_;

    return 'Operation completed ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'               => { name => 'hostname' },
        'search-base:s'            => { name => 'search_base', default => 'cn=monitor' },
        'ldap-connect-options:s@'  => { name => 'ldap_connect_options' },
        'ldap-starttls-options:s@' => { name => 'ldap_starttls_options' },
        'ldap-bind-options:s@'     => { name => 'ldap_bind_options' },
        'tls'                      => { name => 'use_tls' },
        'username:s'               => { name => 'username' },
        'password:s'               => { name => 'password' },
        'timeout:s'                => { name => 'timeout', default => '30' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the hostname option');
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
}

sub ldap_error {
    my ($self, %options) = @_;
    
    if ($options{code} == 1) {
        $self->{output}->output_add(
            severity => 'unknown',
            short_msg => $options{err_msg}
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
}

sub search_monitor {
    my ($self, %options) = @_;

    my ($ldap_handle, $code, $err_msg) = centreon::common::protocols::ldap::lib::ldap::connect(
        hostname => $self->{option_results}->{hostname},
        username => $self->{option_results}->{username},
        password => $self->{option_results}->{password},
        timeout => $self->{option_results}->{timeout},
        ldap_connect_options => $self->{option_results}->{ldap_connect_options},
        use_tls => $self->{option_results}->{use_tls},
        ldap_starttls_options => $self->{option_results}->{ldap_starttls_options},
        ldap_bind_options => $self->{option_results}->{ldap_bind_options},
    );
    $self->ldap_error(code => $code, err_msg => $err_msg);
    (my $search_result, $code, $err_msg) = centreon::common::protocols::ldap::lib::ldap::search(
        ldap_handle => $ldap_handle,
        search_base => $self->{option_results}->{search_base},
        search_filter => '(objectclass=*)',
        ldap_search_options => ['attrs=monitoredInfo', 'attrs=monitorCounter', 'attrs=MonitorOpCompleted'],
    );
    $self->ldap_error(code => $code, err_msg => $err_msg);
    centreon::common::protocols::ldap::lib::ldap::quit(ldap_handle => $ldap_handle);

    return $search_result;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{operation} = {};
    $self->{global} = {};
    my $search_result = $self->search_monitor();
    foreach my $entry ($search_result->entries()) {
        my $dn = $entry->dn();
        if ($dn =~ /cn=(Current|Total),cn=Connections/i) {
            $self->{global}->{'connections_' . lc($1)} = $entry->get_value('monitorCounter');
        } elsif ($dn =~ /cn=(.*?),cn=Operations/i) {
            $self->{operation}->{'operations_completed_' . lc($1)} = $entry->get_value('MonitorOpCompleted');
        } elsif ($dn =~ /cn=(Max|Active),cn=Threads/i) {
            $self->{global}->{'threads_' . lc($1)} = $entry->get_value('monitoredInfo');
        } elsif ($dn =~ /cn=Bytes,cn=Statistics/i) {
            $self->{global}->{traffic} = $entry->get_value('monitorCounter');
        } 
    }

    $self->{global}->{threads_active_prct} = $self->{global}->{threads_active} * 100 / $self->{global}->{threads_max};

    $self->{cache_name} = "openldap_" . $self->{mode} . '_' . $self->{option_results}->{hostname} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system usage (connections, threads, requests).

=over 8

=item B<--hostname>

IP Addr/FQDN of the openldap host (required).

=item B<--search-base>

Set the DN that is the base object entry relative to the backend monitor (Default: cn=monitor).

=item B<--ldap-connect-options>

Add custom ldap connect options:

=over 16

=item B<Set SSL connection>

--ldap-connect-options='scheme=ldaps'

=item B<Set LDAP version 2>

--ldap-connect-options='version=2'

=back

=item B<--ldap-starttls-options>

Add custom start tls options (need --tls option):

=over 16

=item B<An example>

--ldap-starttls-options='verify=none'

=back

=item B<--ldap-bind-options>

Add custom bind options (can force noauth) (not really useful now).

=item B<--username>

Specify username for authentification (can be a DN)

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'con-current', 'con-total', 'threads-active', 'traffic',
'op-add', 'op-search', 'op-bind', 'op-unbind', 'op-delete'.

=back

=cut
