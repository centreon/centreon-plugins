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

package cloud::outscale::mode::quotas;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_quota_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub prefix_quota_output {
    my ($self, %options) = @_;

    return sprintf(
        "quota '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'quotas', type => 1, cb_prefix_output => 'prefix_quota_output', message_multiple => 'All quotas are ok' }
    ];

    $self->{maps_counters}->{quotas} = [
        { label => 'quota-usage', nlabel => 'quota.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' }, { name => 'type' } ],
                closure_custom_output => $self->can('custom_quota_output'),
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => [$self->{result_values}->{type}, $self->{result_values}->{name}],
                        value => $self->{result_values}->{used},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{total}
                    );
                }
            }
        },
        { label => 'quota-usage-free', display_ok => 0, nlabel => 'quota.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' }, { name => 'type' } ],
                closure_custom_output => $self->can('custom_quota_output'),
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => [$self->{result_values}->{type}, $self->{result_values}->{name}],
                        value => $self->{result_values}->{free},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{total}
                    );
                }
            }
        },
        { label => 'quota-usage-prct', display_ok => 0, nlabel => 'quota.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' }, { name => 'type' } ],
                closure_custom_output => $self->can('custom_quota_output'),
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{type}, $self->{result_values}->{name}],
                        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'  => { name => 'filter_name' },
        'filter-type:s'  => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $quotas = $options{custom}->read_quotas();

    my $i = 0;
    $self->{quotas} = {};
    foreach my $quota (@$quotas) {
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $quota->{QuotaType} !~ /$self->{option_results}->{filter_type}/);
        foreach (@{$quota->{Quotas}}) {
            next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $_->{Name} !~ /$self->{option_results}->{filter_name}/);
            next if ($_->{MaxValue} <= 0);

            $self->{quotas}->{$i} = {
                name => $_->{Name},
                type => $quota->{QuotaType},
                total => $_->{MaxValue},
                used => $_->{UsedValue},
                free => $_->{MaxValue} - $_->{UsedValue},
                prct_used => $_->{UsedValue} * 100 / $_->{MaxValue},
                prct_free => 100 - ($_->{UsedValue} * 100 / $_->{MaxValue})
            };
            $i++;
        }
    }
}

1;

__END__

=head1 MODE

Check quotas.

=over 8

=item B<--filter-name>

Filter nets by name.

=item B<--net-tag-name>

Nets tag to be used for the name (default: 'name').

=item B<--unknown-net-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{netName}

=item B<--warning-net-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{netName}

=item B<--critical-net-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{netName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'nets-detected', 'nets-available', 'nets-pending',
'nets-deleted'.

=back

=cut
