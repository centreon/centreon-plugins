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
use centreon::plugins::misc qw/is_excluded is_not_empty/;
use centreon::plugins::constants qw(:counters :values);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'include-name:s'                   => { name => 'include_name' },
            'exclude-name:s'                   => { name => 'exclude_name' },
            'include-uuid:s'                   => { name => 'include_uuid' },
            'exclude-uuid:s'                   => { name => 'exclude_uuid' },
            'include-host-names:s'             => { name => 'include_host_name', default => '' },
            'exclude-host-names:s'             => { name => 'exclude_host_name', default => '' },
            'include-pool:s'                   => { name => 'include_pool' },
            'exclude-pool:s'                   => { name => 'exclude_pool' },
            'include-sr-type:s'                => { name => 'include_sr_type' },
            'exclude-sr-type:s'                => { name => 'exclude_sr_type' },
            'host-storage-config-cache-time:s' => {name => 'host_storage_config_cache_time', default => 10, numeric => 1 }
        }
    );

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name              => 'srs',
            type              => COUNTER_TYPE_INSTANCE,
            message_separator => ', ',
            prefix_output     => "storage repository '%{display}' ",
            message_multiple  => 'All storage repositories are ok',
            skipped_code      => { NO_VALUE => 1 }
        }
    ];
    $self->{maps_counters}->{srs} = [
        { label => 'total-size', nlabel => 'storage.space.total.bytes', set => {
                key_values => [ { name => 'size' }, { name => 'display' } ],
                output_template => 'total size: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage', nlabel => 'storage.space.usage.percentage', set => {
                key_values => [ { name => 'used_prct' }, { name => 'display' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api_get(
        endpoint => "srs",
        get_param => ['fields=name_label,uuid,$pool,SR_type,shared,physical_usage,size,$PBDs']
    );

    $self->{srs} = {};
    STORAGE_REPOSITORY: for my $sr (@$response) {
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
        if ($sr->{size} <= 0) {
            $self->{output}->output_add(long_msg => "skipping '$sr->{name_label}': repository size is 0.", debug => 1);
            next;
        }
        # if we filter on host name, we should try to cache the PBD and host property for a small amount of time.
        if (is_not_empty($self->{option_results}->{include_host_name}) or is_not_empty($self->{option_results}->{exclude_host_name})){
            my $pbds = $options{custom}->get_pbd_to_host(cache_time => $self->{option_results}->{host_storage_config_cache_time});

            for my $pbd (@{$sr->{'$PBDs'}}) {
                if (is_excluded($pbds->{$pbd}, $self->{option_results}->{include_host_name}, $self->{option_results}->{exclude_host_name}, output => $self->{output})) {
                    next STORAGE_REPOSITORY;
                }
            }

        }
        $self->{srs}->{$sr->{uuid}} = {
            display    => $sr->{name_label},
            size       => $sr->{size},
            used_prct  => 100 * $sr->{physical_usage} / $sr->{size}
        };
    }
    if (scalar(keys %{$self->{srs}}) == 0) {
        $self->{output}->option_exit(short_msg => "No storage repository found, check filters");
    }

}

1;

__END__

=head1 MODE

Check Storage repository status on a Xen Orchestra pool
A Storage Repository is a logical storage unit used to store ISO, virtual machine disk or High availability health check.

=over 8

=item B<--include-name>

Filter storage repository by name (can be a regexp). Only matching storage repository are checked.

=item B<--exclude-name>

Exclude storage repository by name (can be a regexp).

=item B<--include-uuid>

Filter storage repository by uuid (can be a regexp). Only matching storage repository are checked.

=item B<--exclude-uuid>

Exclude storage repository by uuid (can be a regexp).

=item B<--include-pool>

Filter storage repository by pool uuid (can be a regexp). Only matching storage repository are checked.

=item B<--exclude-pool>

Exclude storage repository by pool uuid (can be a regexp).

=item B<--include-sr-type>

Filter storage repository by C<SR_type> (can be a regexp). Only matching storage repository are checked.
Non exhaustive list of possible value : C<ext>, C<nfs>, C<udev>, C<iso>, C<linstor>.

=item B<--exclude-sr-type>

Exclude storage repository by C<SR_type> (can be a regexp).

=item B<--include-host-names>

Filter storage repository by C<host names> (can be a regexp). One storage repository can be split across multiples physical hosts.
Only storage repository present on matching hosts are checked.

=item B<--exclude-host-names>

Exclude storage repository by C<host names> (can be a regexp).

=item B<--host-storage-config-cache-time>

for C<--include-host-names> and C<--exclude-host-names>, cache the Storage Repository -> Physical Block Device -> host relation.
Cache time is expressed in minutes.
Default : 10

=item B<--warning-total-size>

Threshold in bytes.

=item B<--critical-total-size>

Threshold in bytes.

=item B<--warning-usage>

Threshold in percentage.

=item B<--critical-usage>

Threshold in percentage.

=back

=cut