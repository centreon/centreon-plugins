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

package network::paloalto::api::mode::edlcapacity;
use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::constants qw(:counters);
use Digest::SHA qw(sha256_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'edl',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_edl_output',
            message_multiple => 'All External Dynamic Lists are ok'
        }
    ];

    $self->{maps_counters}->{edl} = [
        {
            label         => 'usage',
            set           => {
                key_values => [
                    { name => 'display' },
                    { name => 'prct_used' }
                ],
                output_template => 'capacity usage: (%.2f%%)',
                output_use      => 'prct_used',
                threshold_use   => 'prct_used',
                perfdatas       => [
                    {
                        nlabel              => 'edl.entries.usage.percentage',
                        label               => 'usage-percentage',
                        value               => 'prct_used',
                        template            => '%.2f',
                        unit                => '%',
                        min                 => 0,
                        max                 => 100,
                        label_extra_instance => 1,
                        instance_use        => 'display'
                    }
                ]
            }
        }
    ];
}

sub prefix_edl_output {
    my ($self, %options) = @_;
    return "EDL '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-type:s'   => { name => 'include_type', default => '' },
        'exclude-type:s'   => { name => 'exclude_type', default => '' },
        'warning-usage:s'  => { name => 'warning_usage',  default => '~:80' },
        'critical-usage:s' => { name => 'critical_usage', default => '~:90' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{perfdata}->threshold_validate(label => 'warning-usage',  value => $self->{option_results}->{warning_usage});
    $self->{perfdata}->threshold_validate(label => 'critical-usage', value => $self->{option_results}->{critical_usage});
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type => 'op',
        cmd  => '<request><system><external-list><list-capacities/></external-list></system></request>'
    );

    $self->{edl} = {};

    foreach my $type (keys %$result) {
        next if is_excluded($type, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type});

        my $used  = $result->{$type}->{'running-cap'};
        my $total = $result->{$type}->{'total-cap'};

        next unless defined($used)  && $used  =~ /^\d+$/;
        next unless defined($total) && $total =~ /^\d+$/ && $total > 0;

        $self->{edl}->{$type} = {
            display   => $type,
            used      => int($used),
            total     => int($total),
            prct_used => ($used / $total) * 100
        };
    }

    if (!%{$self->{edl}}) {
        $self->{output}->add_option_msg(short_msg => 'No External Dynamic List capacity found.');
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'paloalto_api_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' .
        sha256_hex(
            (defined($self->{option_results}->{include_type}) ? $self->{option_results}->{include_type} : 'all') . '_' .
            (defined($self->{option_results}->{exclude_type}) ? $self->{option_results}->{exclude_type} : 'none')
        );

}

1;

__END__

=head1 MODE

Check Palo Alto External Dynamic Lists (EDL) capacity.

=over 8

=item B<--include-type>

Include EDL types matching this regexp.

=item B<--exclude-type>

Exclude EDL types matching this regexp.

=item B<--warning-usage>

Warning threshold as a percentage of total capacity (default: '~:80').

=item B<--critical-usage>

Critical threshold as a percentage of total capacity (default: '~:90').

=back

=cut