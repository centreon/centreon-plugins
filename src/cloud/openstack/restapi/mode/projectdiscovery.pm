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

package cloud::openstack::restapi::mode::projectdiscovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/flatten_arrays json_encode/;

# All filter parameters that can be used
my @_options = qw/include_name
                  exclude_name
                  include_domain_id
                  exclude_domain_id/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s@' => { name => $_ } } @_options ),
        'prettify'                     => { name => 'prettify', default => 0 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/exclude_no_ip prettify filter_project_id/;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );

        my $vms = $options{custom}->keystone_list_projects( ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $vms->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $vms->{message})
            if $vms->{http_status} != 200;

        return $vms->{results};
    }
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = $self->manage_selection(custom => $options{custom});

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @{$results};
    $disco_stats->{results} = $results;

    my $encoded_data = json_encode($disco_stats, prettify => $self->{prettify},
                                                 output => $options{output},
                                                 no_exit => 1);

    $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}'
        unless $encoded_data;

    $self->{output}->output_add(short_msg => $encoded_data);

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

OpenStack Projects discovery

=over 8

=item B<--prettify>

Prettify JSON output.

=item B<--include-name>

Filter by project name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by project name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-domain-id>

Filter project by domain id (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-domain-id>

Exclude project by domain id (can be a regexp and can be used multiple times or for comma separated values).

=back

=cut
