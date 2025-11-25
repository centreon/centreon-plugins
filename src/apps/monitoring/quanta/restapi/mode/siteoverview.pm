#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::quanta::restapi::mode::siteoverview;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sites', type => 1, message_multiple => 'All sites are OK', cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{sites} = [
        { label => 'performance-score', nlabel => 'performance.score', set => {
                key_values => [ { name => 'performance_score' }, { name => 'display' } ],
                output_template => 'performance score: %d',
                perfdatas => [
                    { value => 'performance_score', template => '%d',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'digital-sobriety-score', nlabel => 'digitalsobriety.score', set => {
                key_values => [ { name => 'digital_sobriety_score' }, { name => 'display' } ],
                output_template => 'digital sobriety score: %d',
                perfdatas => [
                    { value => 'digital_sobriety_score', template => '%d',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'eco-design-score', nlabel => 'ecodesign.score', set => {
                key_values => [ { name => 'eco_design_score' }, { name => 'display' } ],
                output_template => 'eco design score: %d',
                perfdatas => [
                    { value => 'eco_design_score', template => '%d',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'carbon-footprint', nlabel => 'perclick.carbon.footprint.gramm', set => {
                key_values => [ { name => 'carbon_footprint_per_click' }, { name => 'display' } ],
                output_template => 'carbon footprint per click: %.2fg',
                perfdatas => [
                    { value => 'carbon_footprint_per_click', template => '%.2f',
                      min => 0, unit => 'g', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Site '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "site-id:s"   => { name => 'site_id',   default => '' },
        "timeframe:s" => { name => 'timeframe', default => '3600' }
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{$_} = $self->{option_results}->{$_} foreach qw/site_id timeframe/;

    if ($self->{site_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --site-id option.");
        $self->{output}->option_exit();
    }   
}

sub manage_selection {
    my ($self, %options) = @_;

    my $site_metrics = [
        'performance_score',
        'digital_sobriety_score',
        'eco_design_score',
        'carbon_footprint_per_click'
    ];
    my ($site_payload, $resources_payload);
    $site_payload->{type} = 'site';
    $site_payload->{id} = $self->{site_id};
    foreach (@$site_metrics) {
        push @{$site_payload->{metrics}}, { name => $_};
    }
    push @{$resources_payload->{resources}}, $site_payload;
    $resources_payload->{range} = $self->{timeframe};

    my $results = $options{custom}->get_data_export_api(data => $resources_payload);
    foreach my $site (@{$results->{resources}}) {
        $self->{sites}->{$site->{id}}->{display} = $site->{name};
        foreach my $metric (@{$site->{metrics}}) {
            $self->{sites}->{$site->{id}}->{$metric->{name}} = $metric->{values}[0]->{average};
        }
    }

    $self->{output}->option_exit(short_msg => "Couldn't get overview performance metrics for site id: ".$self->{site_id})
        if (scalar(keys %{$self->{sites}}) <= 0);
}

1;

__END__

=head1 MODE

Check Quanta by Centreon overview performance metrics for a given site.

=over 8

=item B<--site-id>

Set ID of the site (mandatory option).

=item B<--timeframe>

Set timeframe in seconds (default: 3600).

=item B<--warning-performance-score>

Warning threshold for performance score.

=item B<--critical-performance-score>

Critical threshold for performance score.

=item B<--warning-digital-sobriety-score>

Warning threshold for digital sobriety score.

=item B<--critical-digital-sobriety-score>

Critical threshold for digital sobriety score.

=item B<--warning-eco-design-score>

Warning threshold for C<eco design> score.

=item B<--critical-eco-design-score>

Critical threshold for C<eco design> score.

=item B<--warning-carbon-footprint>

Warning threshold for carbon footprint.

=item B<--critical-carbon-footprint>

Critical threshold for carbon footprint.

=back

=cut
