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

package cloud::kubernetes::mode::persistentvolumestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Phase is '%s'",
        $self->{result_values}->{phase}
    );
}

sub prefix_pv_output {
    my ($self, %options) = @_;

    return "Persistent Volume '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pvs', type => 1, cb_prefix_output => 'prefix_pv_output',
            message_multiple => 'All PersistentVolumes status are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{pvs} = [
        { label => 'status', type => 2, critical_default => '%{phase} !~ /Bound|Available|Released/i', set => {
                key_values => [ { name => 'phase' }, { name => 'name' } ],
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
        'filter-name:s'      => { name => 'filter_name' },
        'filter-namespace:s' => { name => 'filter_namespace' }
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{pvs} = {};

    my $results = $options{custom}->kubernetes_list_pvs();
    
    foreach my $pv (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $pv->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $pv->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{pvs}->{$pv->{metadata}->{uid}} = {
            name => $pv->{metadata}->{name},
            phase => $pv->{status}->{phase}
        }            
    }
    
    if (scalar(keys %{$self->{pvs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No PersistentVolumes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check persistent volume status.

=over 8

=item B<--filter-name>

Filter persistent volume name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '')
You can use the following variables: %{name}, %{phase}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{phase} !~ /Bound|Available|Released/i').
You can use the following variables: %{name}, %{phase}.

=back

=cut
