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

package storage::netapp::ontap::restapi::mode::quotas;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_quota_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "Quota '%s%s%s%s' ",
        $options{instance_value}->{vserver} ne '' ? 'vserver:' . $options{instance_value}->{vserver} . ',' : '',
        'volume:' . $options{instance_value}->{volume},
        $options{instance_value}->{qtree} ne '' ? ',' . 'qtree:' . $options{instance_value}->{qtree} : '',
        $self->{duplicated}->{$options{instance_value}->{vserver} . $options{instance_value}->{volume} . $options{instance_value}->{qtree} } > 1 ? ',index:' . $options{instance_value}->{index} : ''
    );
}

sub custom_space_usage_perfdata {
    my ($self, %options) = @_;
    
    my $instances = ['volume:' . $self->{result_values}->{volume}];
    unshift @$instances, 'vserver:' . $self->{result_values}->{vserver} if ($self->{result_values}->{vserver} ne '');
    push @$instances, 'qtree:' . $self->{result_values}->{qtree} if ($self->{result_values}->{qtree} ne '');
    push @$instances, 'index:' . $self->{result_values}->{index}
        if ($self->{instance_mode}->{duplicated}->{ $self->{result_values}->{vserver} . $self->{result_values}->{volume} . $self->{result_values}->{qtree} } > 1);

    my $warn_label = 'warning-'. $self->{thlabel};
    if ($self->{result_values}->{soft_limit} > 0) {
        $warn_label = 'warning-' . $self->{thlabel} . '-' . $self->{result_values}->{index};
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => $instances,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => $warn_label),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total} > 0 ? $self->{result_values}->{total} : undef
    );
}

sub custom_space_usage_free_perfdata {
    my ($self, %options) = @_;
    
    my $instances = ['volume:' . $self->{result_values}->{volume}];
    unshift @$instances, 'vserver:' . $self->{result_values}->{vserver} if ($self->{result_values}->{vserver} ne '');
    push @$instances, 'qtree:' . $self->{result_values}->{qtree} if ($self->{result_values}->{qtree} ne '');
    push @$instances, 'index:' . $self->{result_values}->{index}
        if ($self->{instance_mode}->{duplicated}->{ $self->{result_values}->{vserver} . $self->{result_values}->{volume} . $self->{result_values}->{qtree} } > 1);

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => $instances,
        value => $self->{result_values}->{free},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_space_usage_prct_perfdata {
    my ($self, %options) = @_;

    my $instances = ['volume:' . $self->{result_values}->{volume}];
    unshift @$instances, 'vserver:' . $self->{result_values}->{vserver} if ($self->{result_values}->{vserver} ne '');
    push @$instances, 'qtree:' . $self->{result_values}->{qtree} if ($self->{result_values}->{qtree} ne '');
    push @$instances, 'index:' . $self->{result_values}->{index}
        if ($self->{instance_mode}->{duplicated}->{ $self->{result_values}->{vserver} . $self->{result_values}->{volume} . $self->{result_values}->{qtree} } > 1);

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '%',
        instances => $instances,
        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0, max => 100
    );
}

sub custom_space_usage_threshold {
    my ($self, %options) = @_;

    # the soft_limit override the default warning plugin threshold
    my $warn_label = 'warning-'. $self->{thlabel};
    if ($self->{result_values}->{soft_limit} > 0) {
        $warn_label = 'warning-' . $self->{thlabel} . '-' . $self->{result_values}->{index};
        $self->{perfdata}->threshold_validate(label => $warn_label, value => $self->{result_values}->{soft_limit});
    }

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{used}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => $warn_label, exit_litteral => 'warning' }
        ]
    );
}

sub custom_space_usage_free_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{free}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_space_usage_prct_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});

    my $msg;
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf("used: %s (unlimited)", $total_used_value . " " . $total_used_unit);
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
        $msg = sprintf(
            "total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
            $total_size_value . " " . $total_size_unit,
            $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
            $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
        );
    }
    return $msg;
}

sub custom_space_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{qtree} = $options{new_datas}->{$self->{instance} . '_qtree'};
    $self->{result_values}->{volume} = $options{new_datas}->{$self->{instance} . '_volume'};
    $self->{result_values}->{vserver} = $options{new_datas}->{$self->{instance} . '_vserver'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{soft_limit} = $options{new_datas}->{$self->{instance} . '_soft_limit'};
    $self->{result_values}->{index} = $options{new_datas}->{$self->{instance} . '_index'};

    if ($self->{result_values}->{total} == 0) {
        return -10 if ($options{extra_options}->{label} ne 'usage');
        return 0;
    }

    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};

    # quotas can be over 100%
    if ($self->{result_values}->{free} < 0) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_free} = 0;
    }
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'quotas', type => 1, cb_prefix_output => 'prefix_quota_output', message_multiple => 'All quotas are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{quotas} = [
         { label => 'space-usage', nlabel => 'quota.space.usage.bytes', set => {
                key_values => [
                    { name => 'qtree' }, { name => 'volume' }, { name => 'vserver' },
                    { name => 'used' }, { name => 'total' }, { name => 'soft_limit' }, { name => 'index' }
                ],
                closure_custom_calc_extra_options => { label => 'usage' },
                closure_custom_calc => $self->can('custom_space_usage_calc'),
                closure_custom_output => $self->can('custom_space_usage_output'),
                closure_custom_threshold_check => $self->can('custom_space_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_perfdata')
            }
        },
        { label => 'space-usage-free', nlabel => 'quota.space.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'qtree' }, { name => 'volume' }, { name => 'vserver' },
                    { name => 'used' }, { name => 'total' }, { name => 'soft_limit' }, { name => 'index' }
                ],
                closure_custom_calc_extra_options => { label => 'free' },
                closure_custom_calc => $self->can('custom_space_usage_calc'),
                closure_custom_output => $self->can('custom_space_usage_output'),
                closure_custom_threshold_check => $self->can('custom_space_usage_free_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_free_perfdata')
            }
        },
        { label => 'space-usage-prct', nlabel => 'quota.space.usage.percentage', display_ok => 0, set => {
                key_values => [ 
                    { name => 'qtree' }, { name => 'volume' }, { name => 'vserver' },
                    { name => 'used' }, { name => 'total' }, { name => 'soft_limit' }, { name => 'index' }
                ],
                closure_custom_calc_extra_options => { label => 'prct' },
                closure_custom_calc => $self->can('custom_space_usage_calc'),
                closure_custom_output => $self->can('custom_space_usage_output'),
                closure_custom_threshold_check => $self->can('custom_space_usage_prct_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_prct_perfdata')
            }
        }
    ];
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-index:s'   => { name => 'filter_index' },
        'filter-vserver:s' => { name => 'filter_vserver' },
        'filter-volume:s'  => { name => 'filter_volume' },
        'filter-qtree:s'   => { name => 'filter_qtree' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $quotas = $options{custom}->request_api(endpoint => '/api/storage/quota/reports?fields=index,qtree,volume,svm,space');

    $self->{duplicated} = {};

    # theres are differents types: user, group and qtree
    $self->{quotas} = {};
    foreach my $quota (@{$quotas->{records}}) {
        my $index = $quota->{index};
        my $qtree = defined($quota->{qtree}) && defined($quota->{qtree}->{name}) ? $quota->{qtree}->{name} : '';
        my $volume = defined($quota->{volume}) && defined($quota->{volume}->{name}) ? $quota->{volume}->{name} : '';
        my $vserver = defined($quota->{svm}) && defined($quota->{svm}->{name}) ? $quota->{svm}->{name} : '';

        next if (defined($self->{option_results}->{filter_index}) && $self->{option_results}->{filter_index} ne '' &&
            $index !~ /$self->{option_results}->{filter_index}/);
        next if (defined($self->{option_results}->{filter_qtree}) && $self->{option_results}->{filter_qtree} ne '' &&
            $qtree !~ /$self->{option_results}->{filter_qtree}/);
        next if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '' &&
            $volume !~ /$self->{option_results}->{filter_volume}/);
        next if (defined($self->{option_results}->{filter_vserver}) && $self->{option_results}->{filter_vserver} ne '' &&
            $vserver !~ /$self->{option_results}->{filter_vserver}/);

        my $path = $vserver . $volume . $qtree;
        $self->{duplicated}->{$path} = 0 if (!defined($self->{duplicated}->{$path}));
        $self->{duplicated}->{$path}++;

        $self->{quotas}->{$path . $index} = {
            index => $index,
            qtree => $qtree,
            volume => $volume,
            vserver => $vserver,
            used => $quota->{space}->{used}->{total},
            total => $quota->{space}->{hard_limit},
            soft_limit => defined($quota->{space}->{soft_limit}) ? $quota->{space}->{soft_limit} : 0
        };
    }

    if (scalar(keys %{$self->{quotas}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No quota found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check quotas.

=over 8

=item B<--filter-index>

Filter by index (identified entry in the /etc/quotas) (can be a regexp).

=item B<--filter-vserver>

Filter by Vserver name (can be a regexp).

=item B<--filter-volume>

Filter by volume name (can be a regexp).

=item B<--filter-qtree>

Filter by Qtree name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct'.

=back

=cut
