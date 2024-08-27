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

package cloud::outscale::mode::accountconsumptions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;

sub consumption_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking account consumption '%s' [service: %s] [region: %s]",
        $options{instance_value}->{title},
        $options{instance_value}->{service},
        $options{instance_value}->{region}
    );
}

sub prefix_consumption_output {
    my ($self, %options) = @_;

    return sprintf(
        "account consumption '%s' [service: %s] [region: %s] ",
        $options{instance_value}->{title},
        $options{instance_value}->{service},
        $options{instance_value}->{region}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of account consumptions ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'consumptions', type => 3, cb_prefix_output => 'prefix_consumption_output', cb_long_output => 'consumption_long_output', indent_long_output => '    ', message_multiple => 'All account consumptions are ok',
            group => [
                { name => 'metrics', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'account-consumptions-detected', display_ok => 0, nlabel => 'account.consumptions.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{metrics} = [
        { label => 'account-consumption', nlabel => 'accounts.consumption.count', set => {
                key_values => [ { name => 'value' }, { name => 'title' }, { name => 'service' }, { name => 'region' } ],
                output_template => 'value: %.3f',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => [$self->{result_values}->{title}, $self->{result_values}->{service}, $self->{result_values}->{region}],
                        value => sprintf('%.3f', $self->{result_values}->{value}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
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
        'filter-region:s'   => { name => 'filter_region' },
        'filter-service:s'  => { name => 'filter_service' },
        'filter-category:s' => { name => 'filter_category' },
        'filter-title:s'    => { name => 'filter_title' },
        'timeframe:s'       => { name => 'timeframe' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{timeframe}) || $self->{option_results}->{timeframe} !~ /\d/) {
        $self->{option_results}->{timeframe} = 1;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $dt = DateTime->now(time_zone => 'UTC');
    my $to_date = sprintf('%02d-%02d-%02d', $dt->year(), $dt->month(), $dt->day());
    $dt->subtract(days => $self->{option_results}->{timeframe});
    my $from_date = sprintf('%02d-%02d-%02d', $dt->year(), $dt->month(), $dt->day());

    my $consumptions = $options{custom}->read_consumption_account(from_date => $from_date, to_date => $to_date);

    $self->{global} = { detected => 0 };
    $self->{consumptions} = {};

    my $i = 0;
    foreach (@$consumptions) {
        next if (defined($self->{option_results}->{filter_region}) && $self->{option_results}->{filter_region} ne '' &&
            $_->{SubregionName} !~ /$self->{option_results}->{filter_region}/);
        next if (defined($self->{option_results}->{filter_service}) && $self->{option_results}->{filter_service} ne '' &&
            $_->{Service} !~ /$self->{option_results}->{filter_service}/);
        next if (defined($self->{option_results}->{filter_category}) && $self->{option_results}->{filter_category} ne '' &&
            $_->{Category} !~ /$self->{option_results}->{filter_category}/);
        next if (defined($self->{option_results}->{filter_title}) && $self->{option_results}->{filter_title} ne '' &&
            $_->{Title} !~ /$self->{option_results}->{filter_title}/);

        $self->{consumptions}->{$i} = {
            title => $_->{Title},
            service => $_->{Service},
            region => $_->{SubregionName},
            metrics => {
                title => $_->{Title},
                service => $_->{Service},
                region => $_->{SubregionName},
                value => $_->{Value}
            }
        };
        $i++;

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check account consumptions.

=over 8

=item B<--filter-title>

Filter account consumptions by title.

=item B<--filter-service>

Filter account consumptions by service.

=item B<--filter-category>

Filter account consumptions by category.

=item B<--filter-region>

Filter account consumptions by region.

=item B<--timeframe>

Set timeframe in days (default: 1).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'account-consumptions-detected', 'account-consumption'.

=back

=cut
