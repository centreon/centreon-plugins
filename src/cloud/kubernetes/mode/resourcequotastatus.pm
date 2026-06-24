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

package cloud::kubernetes::mode::resourcequotastatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:values :counters/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw/is_excluded convert_bytes_ng/;
use List::Util qw/uniq/;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'resource.usage.percent',
        value => $self->{result_values}->{usage_percent},
        unit => '%',
        instances=> [ $self->{result_values}->{name}, $self->{result_values}->{resource} ],
        min => 0,
        max => 100
    );
    $self->{output}->perfdata_add(
        nlabel => 'resource.used',
        value => $self->{result_values}->{used},
        instances => $self->{result_values}->{name},
        instances => [ $self->{result_values}->{name}, $self->{result_values}->{resource} ]
    );
    $self->{output}->perfdata_add(
        nlabel => 'resource.hard',
        value => $self->{result_values}->{hard},
        instances => $self->{result_values}->{name},
        instances => [ $self->{result_values}->{name}, $self->{result_values}->{resource} ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'quotas', type => COUNTER_TYPE_INSTANCE, prefix_output => "Quota '%{namespace}/%{name}' Resource '%{resource}' ",
            message_multiple => 'All ResourceQuota resources are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{quotas} = [
        {
            label => 'usage',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{usage_percent} > 80',
            critical_default => '%{usage_percent} > 90',
            set => {
                key_values => [ { name => 'usage_percent' }, { name => 'used' }, { name => 'hard' },
                                { name => 'display_used' }, { name => 'display_hard' }, { name => 'uid' },
                                { name => 'name' }, { name => 'namespace' }, { name => 'resource' } ],
                output_template => 'Usage: %{display_used}/%{display_hard} (%{usage_percent|%.2f}%%)',
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
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
        'include-name:s'      => { name => 'include_name', default => '' },
        'exclude-name:s'      => { name => 'exclude_name', default => '' },
        'include-namespace:s' => { name => 'include_namespace', default => '' },
        'exclude-namespace:s' => { name => 'exclude_namespace', default => '' },
        'include-resource:s'  => { name => 'include_resource', default => '' },
        'exclude-resource:s'  => { name => 'exclude_resource', default => '' }
    });

    return $self;
}



sub manage_selection {
    my ($self, %options) = @_;

    $self->{quotas} = {};

    my $results = $options{custom}->kubernetes_list_resourcequotas();

    foreach my $rq (@{$results}) {
        my $name = $rq->{metadata}->{name};
        my $namespace = $rq->{metadata}->{namespace};

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
                || is_excluded($namespace, $self->{option_results}->{include_namespace}, $self->{option_results}->{exclude_namespace}, output => $self->{output});

        my $hard = $rq->{status}->{hard} // {};
        my $used = $rq->{status}->{used} // {};

        foreach my $resource (keys %{$hard}) {
            next if is_excluded($resource, $self->{option_results}->{include_resource}, $self->{option_results}->{exclude_resource}, output => $self->{output});

            my $hard_display = $hard->{$resource} // 0;
            my $used_display = $used->{$resource} // 0;

            my $need_format = $resource =~ /(memory|storage)/;
            my $hard_value = $need_format ? convert_bytes_ng(value => $hard_display) : $hard_display;
            my $used_value = $need_format ? convert_bytes_ng(value => $used_display) : $used_display;

            my $usage_percent = $hard_value ? ($used_value / $hard_value) * 100 : 0;

            my $uid = $rq->{metadata}->{uid};
            $self->{quotas}->{ $uid . '-' . $resource } = {
                uid => $uid,
                name => $name,
                namespace => $namespace,
                resource => $resource,
                hard => $hard_value,
                display_hard => $hard_display,
                used => $used_value,
                display_used => $used_display,
                usage_percent => $usage_percent
            };

        }
    }

    $self->{output}->option_exit(short_msg => "No ResourceQuotas found.")
        unless %{$self->{quotas}} || $self->{output}->is_disco_show();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['uid', 'name', 'namespace']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    my %skip;
    foreach my $quotas (sort { $a->{name} cmp $b->{name} } values %{$self->{quotas}}) {
        next if $skip{$quotas->{uid}}++;
        $self->{output}->add_disco_entry(
            uid => $quotas->{uid},
            name => $quotas->{name},
            namespace => $quotas->{namespace}
        );
    }
}

1;

__END__

=head1 MODE

Check C<ResourceQuota> status and resource usage.

=over 8

=item B<--include-name>

Filter C<ResourceQuota> name (can be a regexp).

=item B<--exclude-name>

Exclude C<ResourceQuota> name (can be a regexp).

=item B<--include-namespace>

Filter C<ResourceQuota> namespace (can be a regexp).

=item B<--exclude-namespace>

Exclude C<ResourceQuota> namespace (can be a regexp).

=item B<--include-resource>

Filter C<ResourceQuota> resource type (can be a regexp).

=item B<--exclude-resource>

Exclude C<ResourceQuota> resource type (can be a regexp).

=item B<--warning-usage>

Define the conditions to match for the status to be WARNING (default: '%{usage_percent} > 80').
You can use the following variables: %{name}, %{namespace}, %{resource}, %{used}, %{hard}, %{usage_percent}, %{uid}.

=item B<--critical-usage>

Define the conditions to match for the status to be CRITICAL (default: '%{usage_percent} > 90').
You can use the following variables: %{name}, %{namespace}, %{resource}, %{used}, %{hard}, %{usage_percent}, %{uid}.

=back

=cut
