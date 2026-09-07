#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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
package apps::virtualization::vates::xenorchestra::mode::storagerepository;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::constants qw(:counters :values);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'include-name:s' => { name => 'include_name' },
            'exclude-name:s' => { name => 'exclude_name' },
            'include-uuid:s' => { name => 'include_uuid' },
            'exclude-uuid:s' => { name => 'exclude_uuid' },
            'include-pool:s' => { name => 'include_pool' },
            'exclude-pool:s' => { name => 'exclude_pool' },
            'include-sr-type:s' => { name => 'include_sr_type' },
            'exclude-sr-type:s' => { name => 'exclude_sr_type' },
        }
    );

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;


    $self->{maps_counters_type} = [
        {
            name             => 'srs',
            type             => COUNTER_TYPE_INSTANCE,
            skipped_code => { NO_VALUE => 1 }
        }
    ];
    $self->{maps_counters}->{srs} = [

       { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'size' }, { name => 'used_prct' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
    ];

}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api_get(endpoint => "srs", get_param => ["fields=*"]); # name_label,uuid,$pool,SR_type,shared,

    for my $sr (@$response){
        if (is_excluded($sr->{name_label}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})) {
            next
        }
        if (is_excluded($sr->{uuid}, $self->{option_results}->{include_uuid}, $self->{option_results}->{exclude_uuid}, output => $self->{output})) {
            next
        }
        if (is_excluded($sr->{'$pool'}, $self->{option_results}->{include_pool}, $self->{option_results}->{exclude_pool}, output => $self->{output})) {
            next
        }
        if (is_excluded($sr->{SR_type}, $self->{option_results}->{include_sr_type}, $self->{option_results}->{exclude_sr_type}, output => $self->{output})) {
            next
        }
        if ($sr->{size} == 0) {
            # exclude any storage with 0 capacity
            next;
        }
        $self->{srs}->{total}++;

        $self->{usage}->{$sr->{name_label}} = {
            display => $sr->{name_label},
            used => $sr->{usage},
            size => $sr->{physical_usage},
            used_prct   => 100 * $sr->{usage} / $sr->{physical_usage}
        };
    }

}

1;

__END__

=head1 MODE

Check Storage repository status on a Xen Orchestra pool
A Storage Repository is a logical storage unit used to store ISO, virtual machine disk or High availability health check.

=over 8

=item B<--include-vm-name>

Filter virtual machines by name (can be a regexp). Only matching VMs are checked.

=item B<--exclude-vm-name>

Exclude virtual machines by name (can be a regexp).

=item B<--include-vm-uuid>

Filter virtual machines by uuid (can be a regexp). Only matching VMs are checked.

=item B<--exclude-vm-uuid>

Exclude virtual machines by uuid (can be a regexp).

=item B<--warning-running>

Threshold warning for the number of running VMs.

=item B<--critical-running>

Threshold critical for the number of running VMs.

=item B<--warning-halted>

Threshold warning for the number of halted VMs.

=item B<--critical-halted>

Threshold critical for the number of halted VMs.

=item B<--warning-paused>

Threshold warning for the number of paused VMs.

=item B<--critical-paused>

Threshold critical for the number of paused VMs.

=item B<--warning-suspended>

Threshold warning for the number of suspended VMs.

=item B<--critical-suspended>

Threshold critical for the number of suspended VMs.

=item B<--warning-total>

Threshold warning for the total number of VMs.

=item B<--critical-total>

Threshold critical for the total number of VMs.

=back

=cut