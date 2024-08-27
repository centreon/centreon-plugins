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

package apps::vmware::connector::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{name},
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_expires_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{expires_seconds} == 0) {
        $msg = 'expired';
    } else {
        $msg = 'expires in ' . $self->{result_values}->{expires_human};
    }
    return $msg;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf('used: %s (unlimited)', $self->{result_values}->{used});
    } else {
        $msg = sprintf(
            "total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
            $self->{result_values}->{total}, 
            $self->{result_values}->{used}, $self->{result_values}->{prct_used},
            $self->{result_values}->{free}, $self->{result_values}->{prct_free}
        );
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{edition} = $options{new_datas}->{$self->{instance} . '_edition'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};

    if ($self->{result_values}->{total} == 0) {
        return -10 if ($options{extra_options}->{label} ne 'usage');
        return 0;
    }

    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};

    return 0;
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "License '%s' [edition: %s] ",
        $options{instance},
        $options{instance_value}->{edition}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'licenses', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All licenses are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-licenses', nlabel => 'licenses.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of licenses: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{licenses} = [
        { label => 'usage', nlabel => 'license.usage.count', set => {
                key_values => [
                    { name => 'edition' }, { name => 'name' }, { name => 'used' }, { name => 'total' }
                ],
                closure_custom_calc_extra_options => { label => 'usage' },
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(
                        value => $self->{result_values}->{used}, threshold => [
                            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
                        ]
                    );
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                     $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => $self->{result_values}->{name},
                        value => $self->{result_values}->{used},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{total} > 0 ? $self->{result_values}->{total} : undef
                    );
                }
            }
        },
        { label => 'usage-free', nlabel => 'license.free.count', display_ok => 0, set => {
                key_values => [
                    { name => 'edition' }, { name => 'name' }, { name => 'used' }, { name => 'total' }
                ],
                closure_custom_calc_extra_options => { label => 'free' },
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(
                        value => $self->{result_values}->{free}, threshold => [
                            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
                        ]
                    );
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => $self->{result_values}->{name},
                        value => $self->{result_values}->{free},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{total}
                    );
                }
            }
        },
        { label => 'usage-prct', nlabel => 'license.usage.percentage', display_ok => 0, set => {
                key_values => [
                    { name => 'edition' }, { name => 'name' }, { name => 'used' }, { name => 'total' }
                ],
                closure_custom_calc_extra_options => { label => 'prct' },
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(
                        value => $self->{result_values}->{prct_used}, threshold => [
                            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
                        ]
                    );
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => $self->{result_values}->{name},
                        value => $self->{result_values}->{prct_used},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0, max => 100
                    );
                }
            }
        },
        { label => 'expires', nlabel => 'license.expires', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_expires_output'),
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'exclude-name:s'    => { name => 'exclude_name' },
        'filter-edition:s'  => { name => 'filter_edition' },
        'exclude-edition:s' => { name => 'exclude_edition' },
        'unit:s'            => { name => 'unit', default => 'd' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 'd';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'licenses'
    );

    $self->{global} = { total => 0 };
    $self->{licenses} = {};
    foreach my $name (keys %{$response->{data}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne '' &&
            $name =~ /$self->{option_results}->{exclude_name}/);
        next if (defined($self->{option_results}->{filter_edition}) && $self->{option_results}->{filter_edition} ne '' &&
            $response->{data}->{$name}->{edition} !~ /$self->{option_results}->{filter_edition}/);
        next if (defined($self->{option_results}->{exclude_edition}) && $self->{option_results}->{exclude_edition} ne '' &&
            $response->{data}->{$name}->{edition} =~ /$self->{option_results}->{exclude_edition}/);
        next if (!defined($response->{data}->{$name}->{used}) && !defined($response->{data}->{$name}->{expiration_minutes}));

        $self->{licenses}->{$name} = {
            name => $name,
            edition => $response->{data}->{$name}->{edition},
            total => $response->{data}->{$name}->{total},
            used => $response->{data}->{$name}->{used}
        };
        if (defined($response->{data}->{$name}->{expiration_minutes})) {
            $self->{licenses}->{$name}->{expires_seconds} = $response->{data}->{$name}->{expiration_minutes} * 60;
            $self->{licenses}->{$name}->{expires_human} = centreon::plugins::misc::change_seconds(
                value => $self->{licenses}->{$name}->{expires_seconds}
            );
        }
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check licenses.

=over 8

=item B<--filter-name>

Filter licenses by name (can be a regexp).

=item B<--exclude-name>

Exclude licenses by name (can be a regexp).

=item B<--filter-edition>

Filter licenses by edition name (can be a regexp).

=item B<--exclude-edition>

Exclude licenses by edition name (can be a regexp).

=item B<--unit>

Select the time unit for thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is days.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-licenses', 'usage', 'usage-free', 'usage-prct', 'expires'.

=back

=cut
