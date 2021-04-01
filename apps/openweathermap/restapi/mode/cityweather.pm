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

package apps::openweathermap::restapi::mode::cityweather;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Weather: '%s'", $self->{result_values}->{weather});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{weather} = $options{new_datas}->{$self->{instance} . '_weather'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'city', type => 0, cb_prefix_output => 'prefix_city_output' }
    ];

    $self->{maps_counters}->{city} = [
        { label => 'weather', set => {
                key_values => [ { name => 'weather' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'temperature', nlabel => 'temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'Temperature: %d C',
                perfdatas => [
                    { label => 'temperature', value => 'temperature', template => '%d',
                      unit => 'C' }
                ],
            }
        },        
        { label => 'humidity', nlabel => 'humidity.percentage', set => {
                key_values => [ { name => 'humidity' } ],
                output_template => 'Humidity: %.2f%%',
                perfdatas => [
                    { label => 'humidity', value => 'humidity', template => '%.1f',
                      min => 0, max => 100, unit => '%' }
                ],
            }
        },
        { label => 'clouds', nlabel => 'clouds.percentage', set => {
                key_values => [ { name => 'clouds' } ],
                output_template => 'Clouds: %.2f%%',
                perfdatas => [
                    { label => 'clouds', value => 'clouds', template => '%.1f',
                      min => 0, max => 100, unit => '%' }
                ],
            }
        },
        { label => 'wind', nlabel => 'wind.speed.meterspersecond', set => {
                key_values => [ { name => 'wind' } ],
                output_template => 'Wind: %.2f m/s',
                perfdatas => [
                    { label => 'wind', value => 'wind', template => '%.1f',
                      min => 0, unit => 'm/s' }
                ],
            }
        }
    ];
}

sub prefix_city_output {
    my ($self, %options) = @_;

    return $self->{option_results}->{city_name} . " ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "city-name:s"           => { name => 'city_name' },
        "warning-weather:s"     => { name => 'warning_weather', default => '' },
        "critical-weather:s"    => { name => 'critical_weather', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_weather', 'critical_weather']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(
        url_path => "/weather?",
        get_param => ["q=" . $self->{option_results}->{city_name}]
    );

    $self->{city} = {
        wind => $results->{wind}->{speed},
        humidity => $results->{main}->{humidity},
        temperature => $results->{main}->{temp} - 273.15,
        clouds => $results->{clouds}->{all},
        weather => @{$results->{weather}->[0]}{main}
    };
}

1;

__END__

=head1 MODE

Check city weather

=over 8

=item B<--city-name>

City name (e.g London or ISO 3166 code like London,uk) 

=item B<--warning-weather>

Set warning threshold for weather string desc (Default: '').
Can used special variables like: %{weather}

=item B<--critical-weather>

Set critical threshold for weather string desc (Default: '').
Can used special variables like:  %{weather}
Example :
  --critical-weather='%{weather} eq "Clouds'

=item B<--warning-*>

Set warning threshold for each metric gathered 
Can be : 
    - temperature (Celsius)
    - humidity (%)
    - clouds (% coverage)
    - wind (speed m/s)

=item B<--critical-*>

Set critical threshold for each metric gathered 
Can be : 
    - temperature (Celsius)
    - humidity (%)
    - clouds (% coverage)
    - wind (speed m/s)

=back

=cut
