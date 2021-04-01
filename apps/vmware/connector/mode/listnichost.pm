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

package apps::vmware::connector::mode::listnichost;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'esx-hostname:s' => { name => 'esx_hostname' },
        'filter'         => { name => 'filter' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{esx_hostname}) ||
        $self->{option_results}->{esx_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set option --esx-hostname.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'listnichost');
    foreach (sort keys %{$response->{data}}) {
        $self->{output}->output_add(long_msg => sprintf('%s [status: %s] [vswitch: %s]', 
                                                       $response->{data}->{$_}->{name}, $response->{data}->{$_}->{status}, $response->{data}->{$_}->{vswitch})
        );
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List nic host:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'vswitch']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'listnichost');
    foreach (sort keys %{$response->{data}}) {
        $self->{output}->add_disco_entry(name => $response->{data}->{$_}->{name},
            status => $response->{data}->{$_}->{status}, vswitch => $response->{data}->{$_}->{vswitch}
        );
    }
}

1;

__END__

=head1 MODE

List ESX interfaces.

=over 8

=item B<--esx-hostname>

ESX hostname to check (required).

=back

=cut
