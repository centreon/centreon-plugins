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

package cloud::openstack::restapi::mode::listservices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/flatten_arrays is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-type:s@'   => { name => 'include_type' },
        'exclude-type:s@'   => { name => 'exclude_type' },
        'include-name:s@'   => { name => 'include_name' },
        'exclude-name:s@'   => { name => 'exclude_name' },
        'include-region:s@' => { name => 'include_region' },
        'exclude-region:s@' => { name => 'exclude_region' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{$_} = flatten_arrays($self->{option_results}->{$_}) foreach qw/include_name
                                                                           exclude_name
                                                                           include_type
                                                                           exclude_type
                                                                           include_region
                                                                           exclude_region/;
}

sub manage_selection {
    my ($self, %options) = @_;

    # In discover mode we don't use the Keystone cache because we want to refresh the service list
    my $services = $options{custom}->keystone_authent( dont_read_cache => 1 );

    my %services_global;
    my %services_specific;

    my @disco_data;

    foreach my $service (@{$services->{services}}) {
        # For each services, adds a global item including all regions
        $services_global{$service->{type}} = { type => $service->{type},
                                               name => $service->{name},
                                               region => '',
                                               label => $service->{name}.' '.$service->{type}.' (global)' }
                                                    unless exists $services_global{$service->{type}};

        foreach my $endpoint (@{$service->{endpoints}}) {
            # And include specific items for each region
            # Using a key to prevent duplicates
            my $key = $service->{type} . '##' . $service->{name} . '##' . $endpoint->{region};

            next if exists $services_specific{$key};

            $services_specific{$key} = { type => $service->{type},
                                         name => $service->{name},
                                         region => $endpoint->{region},
                                         label => $service->{name}.' '.$service->{type}.' '. $endpoint->{region} }
        }
    }

    @disco_data = sort { $a->{type} cmp $b->{type} ||
                         $a->{name} cmp $b->{name} ||
                         $a->{region} cmp $b->{region}
                       } (values %services_global, values %services_specific);

    $self->{services} = \@disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    $self->manage_selection( %options );

    $self->{output}->output_add(severity => 'OK', short_msg => 'List service:');

    foreach my $service (@{$self->{services}}) {
        next if is_excluded($service->{name}, $self->{include_name}, $self->{exclude_name});
        next if is_excluded($service->{type}, $self->{include_type}, $self->{exclude_type});
        next if is_excluded($service->{region}, $self->{include_region}, $self->{exclude_region});

        $self->{output}->output_add(long_msg => sprintf("[Type = %s][Name = %s][Region = %s][Label = %s]", $service->{type}, $service->{name} || '-', $service->{region} || '-', $service->{label}))
    }

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();

}

my @labels = ('type', 'name', 'region', 'label');

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [@labels]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $service (@{$self->{services}}) {
        next if is_excluded($service->{name}, $self->{include_name}, $self->{exclude_name});
        next if is_excluded($service->{type}, $self->{include_type}, $self->{exclude_type});
        next if is_excluded($service->{region}, $self->{include_region}, $self->{exclude_region});

        $self->{output}->add_disco_entry( %{ $service } );
    }
}

1;


=head1 MODE

List OpenStack Services

=over 8

=item B<--include-type>

Filter by service type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-type>

Exclude by service type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-name>

Filter by service name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by service name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-region>

Filter by service region (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-region>

Exclude by service region (can be a regexp and can be used multiple times or for comma separated values).

=back

=cut
