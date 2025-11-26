#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::mode::hypervisor;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng catalog_status_calc);
use centreon::plugins::misc qw/flatten_arrays/;

# All filter parameters that can be used
my @_options = qw/include_hypervisor_hostname
                  exclude_hypervisor_hostname
                  include_status
                  exclude_status
                  include_state
                  exclude_state
                  include_id
                  exclude_id
                  include_hypervisor_type
                  exclude_hypervisor_type/;

my @_hypervisor_keys = qw/id status state hypervisor_hostname hypervisor_type/ ;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s@' => { name => $_ } } @_options ),
    });

    return $self;
}

sub custom_hypervisor_output {
    my ($self, %options) = @_;
    sprintf('Hypervisor %s is %s and %s',
        $self->{result_values}->{hypervisor_hostname},
        $self->{result_values}->{status},
        $self->{result_values}->{state},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'hypervisor', type => 1, message_multiple => 'All hypervisors are ok', skipped_code => { -11 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'count', nlabel => 'hypervisor.count',
            set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Hypervisor count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
              }
        }
    ];

    $self->{maps_counters}->{hypervisor} = [
        {   label => 'status', type => 2,
            critical_default => '%{status} =~ /enabled/ && %{state} !~ /up/',
            warning_default => '%{status} !~ /enabled/',
            set => {
                key_values => [ map { { name => $_ } } @_hypervisor_keys, ],
                output_use => 'hypervisor_hostname',
                output_template => 'Hypervisor host name: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_hypervisor_output'),
            },
        },
        (   map {       # define a counter for each other key
                    {   label => $_ =~ s/_/-/gr, type => 2, display_ok => 1,
                        set => {
                            key_values => [ map { { name => $_ } } @_hypervisor_keys, ],
                            output_use => $_,
                            output_template => ucfirst $_ =~ s/_/-/gr.': %s',
                            closure_custom_threshold_check => \&catalog_status_threshold_ng,
                        },
                    }
                } grep { ! /status|state/ } @_hypervisor_keys
        ),
    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{hypervisor} = {};

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $authent->{services} );

        my $hypervisors = $options{custom}->nova_list_hypervisors( ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $hypervisors->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $hypervisors->{message})
            if $hypervisors->{http_status} != 200;

        foreach my $hypervisor (@{$hypervisors->{results}}) {
            $self->{hypervisor}->{$hypervisor->{id}} = { %$hypervisor };
        }
        last RETRY;
    }

    $self->{global}->{count} = keys %{$self->{hypervisor}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_hypervisor_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{hypervisor_hostname} cmp $b->{hypervisor_hostname} ||
                              $a->{id} cmp $b->{id} }
                       values %{$self->{hypervisor}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_hypervisor_keys );
    }
}

1;

__END__

=head1 MODE

Manage OpenStack Hypervisors

=over 8

Only admin users can use this mode.

=item B<--include-hypervisor-hostname>

Filter by hypervisor hostname (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-hypervisor-hostname>

Exclude by hypervisor hostname (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-status>

Filter by hypervisor status (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: enabled, disabled.

=item B<--exclude-status>

Exclude by hypervisor status (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: enabled, disabled.

=item B<--include-state>

Filter by hypervisor state (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: up, down.

=item B<--exclude-state>

Exclude by hypervisor state (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: up, down.

=item B<--include-id>

Filter by hypervisor ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--excluder-id>

Exclude by hypervisor ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-type>

Filter by hypervisor type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-type>

Exclude by hypervisor type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--warning-count>

Warning threshold for the number of hypervisors returned.

=item B<--critical-count>

Critical threshold for the number of hypervisors returned.

=item B<--warning-id>

Define the conditions to match for the status to be WARNING based on the hypervisor id.
Example: --warning-id='%{id} =~ /abcdef/'

=item B<--critical-id>

Define the conditions to match for the status to be CRITICAL based on the hypervisor id.
Example: --critical-id='%{id} =~ /abcdef/'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING based on the hypervisor status (enabled or disabled).
Example: --warning-status='%{status} =~ /disabled/'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL based on the hypervisor status (enabled or disabled).
Example: --critical-status='%{status} =~ /disabled/'
Default value: --critical-status='%{status} =~ /enabled/ && %{state} !~ /up/'

=item B<--warning-state>

Define the conditions to match for the state to be WARNING based on the hypervisor state (up or down).
Example: --warning-state='%{state} =~ /down/'

=item B<--critical-state>

Define the conditions to match for the state to be CRITICAL based on the hypervisor state (up or down).
Example: --critical-state='%{state} =~ /down/'

=item B<--warning-hypervisor-hostname>

Define the conditions to match for the status to be WARNING based on the hypervisor project id.
Example: --warning-hypervisor-hostname='%{hypervisor-hostname} =~ /sample.com/'

=item B<--critical-hypervisor-hostname>

Define the conditions to match for the status to be CRITICAL based on the hypervisor project id.
Example: --critical-hypervisor-hostname='%{hypervisor-hostname} =~ /sample.com/'

=item B<--warning-hypervisor-type>

Define the conditions to match for the status to be WARNING based on the hypervisor type.
Example: --warning-hypervisor-type='%{hypervisor-type} =~ /QEMU/'

=item B<--critical-hypervisor-type>

Define the conditions to match for the status to be CRITICAL based on the hypervisor type.
Example: --critical-hypervisor-type='%{hypervisor-type} =~ /QEMU/'

=back

=cut
