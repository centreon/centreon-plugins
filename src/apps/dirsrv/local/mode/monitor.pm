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

package apps::dirsrv::local::mode::monitor;

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
        { name => 'counters', type => 0 },
    ];
    $self->{maps_counters}->{counters} = [
        {
            label => 'version',
            type => 2,
            critical_default => '%{version} !~ /Directory/',
            set => {
                key_values => [ { name => 'version' } ],
                output_template => 'version: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'currentconnections',
            nlabel => 'dirsrv.server.currconns',
            set => {
                key_values => [ { name => 'currentconnections' } ],
                output_template => 'currentconnections: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            },
        },
        {
            label => 'currentconnectionsatmaxthreads',
            nlabel => 'dirsrv.server.currconnsatmaxthds',
            type => 2,
            critical_default => '%{currentconnectionsatmaxthreads} > 0',
            set => {
                key_values => [ { name => 'currentconnectionsatmaxthreads' } ],
                output_template => 'currentconnectionsatmaxthreads: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            },
        },
        {
            label => 'readwaiters',
            nlabel => 'dirsrv.server.readwaiters',
            type => 2,
            critical_default => '%{readwaiters} > 0',
            set => {
                key_values => [ { name => 'readwaiters' } ],
                output_template => 'readwaiters: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            },
        },
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(
        command => '/bin/sudo',
        command_options => '/sbin/dsconf -j '.$self->{option_results}->{instance}.' monitor server'
    );

    my $decoded_content;
    eval {
        $decoded_content = decode_json($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result");
        $self->{output}->option_exit();
    }
    $self->{counters} = {
        version => $decoded_content->{attrs}->{version}[0],
        currentconnections => $decoded_content->{attrs}->{currentconnections}[0],
        currentconnectionsatmaxthreads => $decoded_content->{attrs}->{currentconnectionsatmaxthreads}[0],
        readwaiters => $decoded_content->{attrs}->{readwaiters}[0],
    };
}

1;

__END__

=head1 MODE

Check dirsrv server stats

=over 8

=item B<--critical-currentconnectsatmaxthreads>

critical threshold for currentconnectionsatmaxthreads number.

Default value is: --critical-currentconnectionsatmaxthreads='%{currentconnectionsatmaxthreads} > 0'

=item B<--critical-readwaiters>

critical threshold for readwaiters

Default value is: --critical-readwaiters='%{readwaiters} > 0'

=back
