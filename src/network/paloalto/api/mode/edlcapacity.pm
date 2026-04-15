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

sub custom_usage_output {
    my ($self, %options) = @_;
    return sprintf(
        'capacity usage: %d/%d entries (%.2f%%)',
        $self->{result_values}->{used},
        $self->{result_values}->{total},
        $self->{result_values}->{prct_used}
    );
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel    => 'edl.entries.usage.count',
        instances => $self->{result_values}->{display},
        value     => $self->{result_values}->{used},
        min       => 0,
        max       => $self->{result_values}->{total}
    );
    $self->{output}->perfdata_add(
        nlabel    => 'edl.entries.usage.percentage',
        unit      => '%',
        instances => $self->{result_values}->{display},
        value     => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0,
        max       => 100
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{prct_used},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'edl',
            type             => 1,
            cb_prefix_output => 'prefix_edl_output',
            message_multiple => 'All External Dynamic Lists are within capacity limits'
        }
    ];

    $self->{maps_counters}->{edl} = [
        {
            label => 'usage',
            set   => {
                key_values => [
                    { name => 'used' },
                    { name => 'total' },
                    { name => 'prct_used' },
                    { name => 'display' }
                ],
                closure_custom_output    => $self->can('custom_usage_output'),
                closure_custom_perfdata  => $self->can('custom_usage_perfdata'),
                closure_custom_threshold => $self->can('custom_usage_threshold')
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
        'filter-type:s'    => { name => 'filter_type' },
        'warning-usage:s'  => { name => 'warning_usage',  default => '80:' },
        'critical-usage:s' => { name => 'critical_usage', default => '90:' }
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

        my $used  = $result->{$type}->{'running-cap'};
        my $total = $result->{$type}->{'total-cap'};

        next unless defined($used)  && $used  =~ /^\d+$/;
        next unless defined($total) && $total =~ /^\d+$/ && $total > 0;

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '') {
            next if $type !~ /$self->{option_results}->{filter_type}/;
        }

        $self->{edl}->{$type} = {
            display   => $type,
            used      => int($used),
            total     => int($total),
            prct_used => ($used / $total) * 100
        };
    }

    if (!%{$self->{edl}}) {
        $self->{output}->add_option_msg(
            short_msg => 'No External Dynamic List capacity found.'
        );
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "paloalto_api_" . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' .
        ($self->{option_results}->{filter_type} // 'all');
}

1;

__END__

=head1 MODE

Check Palo Alto External Dynamic Lists (EDL) capacity.

=over 8

=item B<--filter-type>

Filter EDL entries by type (regexp). Only matching EDL types are checked.

=item B<--warning-usage>

Warning threshold as a percentage of total capacity (default: '80:').

=item B<--critical-usage>

Critical threshold as a percentage of total capacity (default: '90:').

=back

=cut