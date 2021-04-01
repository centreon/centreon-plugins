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

package apps::mq::vernemq::restapi::mode::plugins;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'plugins.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'current total plugins: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $plugins = $options{custom}->request_api(
        endpoint => '/plugin/show'
    );

    $self->{global} = { total => 0 };
    foreach (@{$plugins->{table}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{Plugin} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping plugin '" . $_->{Plugin} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{output}->output_add(long_msg => "plugin '" . $_->{Plugin} . "'");
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check plugins.

=over 8

=item B<--filter-name>

Filter plugin name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total'.

=back

=cut
