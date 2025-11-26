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

package cloud::openstack::restapi::mode::volume;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/flatten_arrays/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng catalog_status_calc);

# All filter parameters that can be used
my @_options = qw/include_name
                  exclude_name
                  include_status
                  exclude_status
                  include_description
                  exclude_description
                  include_bootable
                  exclude_bootable
                  include_encrypted
                  exclude_encrypted
                  include_zone
                  exclude_zone
                  include_id
                  exclude_id
                  include_type
                  exclude_type/;

my @_volume_keys = qw/id status name type description size project_id bootable encrypted zone attachments/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s@' => { name => $_ } } @_options ),

        'filter-project-id:s'          => { name => 'filter_project_id', default => '' }
    });

    return $self;
}

sub custom_volume_output {
    my ($self, %options) = @_;
    sprintf('Volume %s is in %s state',
        $self->{result_values}->{name}, $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'volume', type => 1, message_multiple => 'All volumes are ok', skipped_code => { -11 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        {   label => 'count', nlabel => 'volume.count',
            set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Volume count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
              }
        }
    ];

    $self->{maps_counters}->{volume} = [
        {   label => 'status', type => 2,
            critical_default => '%{status} =~ /error/',
            warning_default => '%{status} =~ /(restoring-backup|backing-up|deleting)/',
            set => {
                key_values => [ map { { name => $_ } } @_volume_keys, ],
                output_use => 'name',
                output_template => 'Volume name: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_volume_output'),
            },
        },
        (   map {       # define a counter for each other key
                    {   label => $_, type => 2, display_ok => 1,
                        set => {
                            key_values => [ map { { name => $_ } } @_volume_keys, ],
                            output_use => $_,
                            output_template => ucfirst $_.': %s',
                            closure_custom_threshold_check => \&catalog_status_threshold_ng,
                        },
                    }
                } grep { ! /name|status|attachments/ } @_volume_keys
        ),
        {  label => 'attachments',
            set => {
                key_values => [ { 'name' => 'attachments', } ],

                output_template => 'Attachments count: %s',
                aperfdatas => [
                    { template => '%d', min => 0 }
                ]

            },
        },
    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;

    $self->{filter_project_id} = $self->{option_results}->{filter_project_id};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{volume} = {};

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $authent->{services} );

        my $volumes = $options{custom}->cinder_list_volumes( project_id => $self->{filter_project_id},
                                                         ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $volumes->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $volumes->{message})
            if $volumes->{http_status} != 200;

        foreach my $volume (@{$volumes->{results}}) {
            $self->{volume}->{$volume->{id}} = { %$volume };
        }
        last RETRY;
    }

    $self->{global}->{count} = keys %{$self->{volume}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_volume_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{project_id} cmp $b->{project_id} ||
                              $a->{name} cmp $b->{name} ||
                              $a->{id} cmp $b->{id} }
                       values %{$self->{volume}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_volume_keys );
    }
}

1;

__END__

=head1 MODE

List OpenStack Volumes

=over 8

=item B<--filter-project-id>

Filter by OpenStack project id (tenant id).
This filter is applied before any other filters and requires admin rights.
When unset volumes are filtered based on the project used during authentication.

=item B<--include-name>

Filter by volume name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by volume name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-status>

Filter by volume status (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/api-ref/block-storage/v3/#volumes-status for more information about status.

=item B<--exclude-status>

Exclude by volume status (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/api-ref/block-storage/v3/#volumes-status for more information about status.

=item B<--include-description>

Filter by volume description (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-description>

Exclude by volume description (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-bootable>

Filter by volume bootable flag (can be 0 or 1).

=item B<--exclude-bootable>

Exclude by volume bootable flag (can be 0 or 1).

=item B<--include-encrypted>

Filter by volume encrypted flag (can be 0 or 1).

=item B<--exclude-encrypted>

Exclude by volume encrypted flag (can be 0 or 1).

=item B<--include-zone>

Filter by volume availability zone (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-zone>

Exclude by volume availability zone (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-id>

Filter by volume ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-id>

Exclude by volume ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-type>

Filter by volume type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-type>

Exclude by volume type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--warning-count>

Warning threshold for the number of volumes returned.

=item B<--critical-count>

Critical threshold for the number of volumes returned.

=item B<--warning-attachments>

Warning threshold for the number of servers attached to the volume.

=item B<--critical-attachments>

Critical threshold for the number of servers attached to the volume.

=item B<--warning-bootable>

Define the conditions to match for the status to be WARNING based on the volume bootable flag (can be 0 or 1).
Example: --warning-bootable='%{bootable} eq "1"'

=item B<--critical-bootable>

Define the conditions to match for the status to be CRITICAL based on the volume bootable flag (can be 0 or 1).
Example: --critical-bootable='%{bootable} eq "1"'

=item B<--warning-description>

Define the conditions to match for the status to be WARNING based on the volume description.
Example: --warning-description='%{description} =~ /test volume/'

=item B<--critical-description>

Define the conditions to match for the status to be CRITICAL based on the volume description.
Example: --critical-description='%{description} =~ /test volume/'

=item B<--warning-encrypted>

Define the conditions to match for the status to be WARNING based on the encrypted flag (can be 0 or 1).
Example: --warning-encrypted='%{encrypted} eq "1"'

=item B<--critical-encrypted>

Define the conditions to match for the status to be CRITICAL based on the encrypted flag (can be 0 or 1).
Example: --critical-encrypted='%{encrypted} eq "1"'

=item B<--warning-id>

Define the conditions to match for the status to be WARNING based on the volume id.
Example: --warning-id='%{id} =~ /abcdef/'

=item B<--critical-id>

Define the conditions to match for the status to be CRITICAL based on the volume id.
Example: --critical-id='%{id} =~ /abcdef/'

=item B<--warning-project_id>

Define the conditions to match for the status to be WARNING based on the volume project id.
Example: --warning-project-id='%{project-id} =~ /abcdef/'

=item B<--critical-project_id>

Define the conditions to match for the status to be CRITICAL based on the volume project id.
Example: --critical-project-id='%{project-id} =~ /abcdef/'

=item B<--warning-size>

Define the conditions to match for the status to be WARNING based on the volume size.
Example: --warning-size='%{size} =~ /1 GB/'

=item B<--critical-size>

Define the conditions to match for the status to be CRITICAL based on the volume size.
Example: --critical-size='%{size} =~ /1 GB/'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING based on the volume status.
Example: --warning-statu='%{status} =~ /downloading/'
Please refer to https://docs.openstack.org/api-ref/block-storage/v3/#volumes-status for more information about status.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL based on the volume status.
Example: --critical-status='%{status} =~ /downloading/'
Please refer to https://docs.openstack.org/api-ref/block-storage/v3/#volumes-status for more information about status.

=item B<--warning-type>

Define the conditions to match for the status to be WARNING based on the volume type.
Example: --warning-type='%{type} =~ /sdd/'

=item B<--critical-type>

Define the conditions to match for the status to be CRITICAL based on the volume type.
Example: --critical-type='%{type} =~ /sdd/'

=item B<--warning-zone>

Define the conditions to match for the status to be WARNING based on the volume availability zone.
Example: --warning-type='%{zone} =~ /nova/'

=item B<--critical-zone>

Define the conditions to match for the status to be CRITICAL based on the volume availability zone.
Example: --critical-type='%{zone} =~ /nova/'

=back

=cut
