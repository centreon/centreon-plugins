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

package storage::netapp::ontap::restapi::mode::luns;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [container state: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{container_state}
    );
}

sub prefix_lun_output {
    my ($self, %options) = @_;

    return "Lun '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'luns', type => 1, cb_prefix_output => 'prefix_lun_output', message_multiple => 'All luns are ok' }
    ];
    
    $self->{maps_counters}->{luns} = [
        { label => 'status', type => 2, critical_default => '%{state} !~ /online/i', set => {
                key_values => [ { name => 'state' }, { name => 'container_state' }, { name => 'display' } ],
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
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $luns = $options{custom}->request_api(endpoint => '/api/storage/luns?fields=*');

    $self->{luns} = {};
    foreach (@{$luns->{records}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping lun '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{luns}->{ $_->{name} } = {
            display => $_->{name},
            state => $_->{status}->{state},
            container_state => $_->{status}->{container_state}
        };
    }
    
    if (scalar(keys %{$self->{luns}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No lun found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check LUNs.

=over 8

=item B<--filter-name>

Filter LUN name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{container_state}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{container_state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /online/i').
Can used special variables like: %{state}, %{container_state}, %{display}

=back

=cut
