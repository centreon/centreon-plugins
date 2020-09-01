#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package hardware::devices::cisco::ces::restapi::mode::diagnostics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'alarm [level: %s] [type: %s] [description: %s]',
        $self->{result_values}->{level},
        $self->{result_values}->{type}, 
        $self->{result_values}->{description}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alarms', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { label => 'alerts', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'description' }, { name => 'level' }, { name => 'type' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-msg:s'      => { name => 'filter_msg' },
        'legacy-tc'         => { name => 'legacy_tc' },
        'warning-status:s'  => { name => 'warning_status', default => '%{level} =~ /warning|minor/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{level} =~ /critical|major/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

#<Command>
#<DiagnosticsResult status="OK">
#  <Message item="1">
#    <Description item="1">System is in standby mode.</Description>
#    <Level item="1">Skipped</Level>
#    <References item="1"/>
#    <Type item="1">SelectedVideoInputSourceConnected</Type>
#  </Message>
#</DiagnosticsResult>
#</Command>

sub manage_selection {
    my ($self, %options) = @_;

    my $post = '<Command><Diagnostics><Run><ResultSet>Alerts</ResultSet></Run></Diagnostics></Command>';
    my $label = 'DiagnosticsRunResult';
    if (defined($self->{option_results}->{legacy_tc})) {
        $post = '<Command><SystemUnit><Diagnostics><Run><ResultSet>Alerts</ResultSet></Run></Diagnostics></SystemUnit></Command>';
        $label = 'DiagnosticsResult';
    }
    my $result = $options{custom}->request_api(
        method => 'POST',
        url_path => '/putxml',
        query_form_post => $post,
        ForceArray => ['Message']
    );

    $self->{alarms}->{global} = { alarm => {} };
    foreach (@{$result->{$label}->{Message}}) {
        my $description = ref($_->{Description}) eq 'HASH' ? $_->{Description}->{content} : $_->{Description};
        my $level = ref($_->{Level}) eq 'HASH' ? $_->{Level}->{content} : $_->{Level};
        my $type = ref($_->{Type}) eq 'HASH' ? $_->{Type}->{content} : $_->{Type};

        if (defined($self->{option_results}->{filter_msg}) && $self->{option_results}->{filter_msg} ne '' &&
            $description !~ /$self->{option_results}->{filter_msg}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $description . "': no matching filter.", debug => 1);
            next;
        }

        $self->{alarms}->{global}->{alarm}->{ $_->{item} } = {
            description => $description,
            level => $level,
            type => $type
        };
    }
}
        
1;

__END__

=head1 MODE

Check diagnostic messages.
Since TC 6.0: SystemUnit Diagnostics Run (use --legacy-tc option)
Since CE 8.0: Diagnostics Run

=over 8

=item B<--filter-msg>

Filter by message (can be a regexp).

=item B<--legacy-tc>

Use old legacy command.

=item B<--warning-status>

Set warning threshold for status (Default: '%{level} =~ /warning|minor/i')
Can used special variables like: %{description}, %{level}, %{type}

=item B<--critical-status>

Set critical threshold for status (Default: '%{level} =~ /critical|major/i').
Can used special variables like: %{description}, %{level}, %{type}

=back

=cut
