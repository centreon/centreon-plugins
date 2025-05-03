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

package apps::dirsrv::local::mode::replication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'instance:s'   => { name => 'instance' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    if (!defined($self->{option_results}->{instance}) || $self->{option_results}->{instance} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set instance option');
        $self->{output}->option_exit();
    }
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'replication', type => 0, cb_prefix_output => 'prefix_repl_output' },
        { name => 'agreements', type => 1, cb_prefix_output => 'prefix_agmts_output' }
    ];
    $self->{maps_counters}->{replication} = [
        {
        label => 'replication_status',
        type => 2,
        critical_default => '%{replication_status} !~ /Online/',
        set => {
                    key_values => [ { name => 'replication_status' } ],
                    output_template => 'replication_status: %s',
                    closure_custom_perfdata => sub { return 0; },
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
    },
    ];
    $self->{maps_counters}->{agreements} = [
        {
            label => 'replica_enabled',
            type => 2,
            critical_default => '%{replica_enabled} !~ /on/',
            set => {
                key_values => [ { name => 'replica_enabled' }, { name => 'display' } ],
                output_template => 'replica_enabled: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'agreement_status',
            type => 2,
            warning_default => '%{agreement_status} =~ /Replication still in progress/',
            critical_default => '%{agreement_status} !~ /Replication still in progress/ && %{agreement_status} !~ /In Synchronization/',
            set => {
                key_values => [ { name => 'agreement_status' }, { name => 'display' } ],
                output_template => 'agreement_status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'lag_time',
            nlabel => 'dirsrv.repl.agmts.lag_time.interval',
            set => {
                key_values => [ { name => 'lag_time' }, { name => 'display' } ],
                output_template => 'agreement lag_time: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            },
        },
    ];
}

sub prefix_repl_output {
    my ($self, %options) = @_;
    return 'Dirsrv: ';
}

sub prefix_agmts_output {
    my ($self, %options) = @_;
    return "'" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(
        command => '/bin/sudo',
        command_options => '/sbin/dsconf -j '.$self->{option_results}->{instance}.' replication monitor'
    );

    my $decoded_content;
    eval {
        $decoded_content = decode_json($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result");
        $self->{output}->option_exit();
    }
    $self->{replication} = { replication_status => $decoded_content->{items}[0]->{data}[0]->{replica_status} };

    $self->{agreements} = {};
    foreach my $entry (@{ $decoded_content->{items}[0]->{data}[0]->{agmts_status} }) {
        $self->{agreements}->{ $entry->{'agmt-name'}[0] }->{display} = $entry->{'agmt-name'}[0];
    $self->{agreements}->{ $entry->{'agmt-name'}[0] }->{replica_enabled} = $entry->{'replica-enabled'}[0];
    $self->{agreements}->{ $entry->{'agmt-name'}[0] }->{agreement_status} = $entry->{'replication-status'}[0];
    my @parts = split(/:/,$entry->{'replication-lag-time'}[0]);
    my $lag_time = ($parts[0]*60+$parts[1])*60+$parts[2];
    $self->{agreements}->{ $entry->{'agmt-name'}[0] }->{lag_time} = $lag_time;
    }
}

1;

__END__

=head1 MODE

Check dirsrv replication stats

=over 8

=item B<--critical-replication_status>

critical threshold for replication status string.

Default value is: --critical-replication_status='%{replication_status} !~ /Online/'

=item B<--critical-replica_enabled>

critical threshold for replica_enabled

Default value is: --critical-replica_enabled='%{replica_enabled} !~ /on/'

=item B<--warning/critical-agreement_status>

Warning and critical threshold for agreement_status

Default values are: --warning-agreement_status='%{agreement_status} =~ /Replication still in progress/' --critical-agreement_status='%{agreement_status} !~ /Replication still in progress/ && %{agreement_status} !~ /In Synchronization/'

=item B<--warning/critical-lag_time>

Warning and critical threshold for lag_time

=back
