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

package os::windows::wmi::custom::wmic;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'  => { name => 'hostname' },
            'username:s'  => { name => 'username' },
            'password:s'  => { name => 'password' },
            'namespace:s' => { name => 'namespace' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MODE OPTIONS', once => 1);

    $self->{output} = $options{output};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{namespace} = (defined($self->{option_results}->{namespace})) ? $self->{option_results}->{namespace} : 'root/cimv2';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub build_options_for_wmic {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    $self->{option_results}->{namespace} = $self->{namespace};

}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_wmic();
}

sub request {
    my ($self, %options) = @_;

    $self->settings();
    my $query = "wmic -U '" . $self->{username} . "' --password='" . $self->{password} . "' --namespace='" . $self->{namespace}."' '//" . $self->{hostname} . "' '" . $options{query} . "'";
    my $result = `$query`;

    if ($? != 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $result;
}

sub query {
    my ($self, %options) = @_;

    return $self->request(query => $options{query});
}

sub get_identifier {
    my ($self, %options) = @_;

    my $id = defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me';

    return $id;
}

1;

__END__

=head1 NAME

Grafana Rest API

=head1 CUSTOM MODE OPTIONS

Grafana Rest API

=over 8

=item B<--hostname>

Remote hostname or IP address.

=item B<--namespace>

Specify namespace if needed (Default: 'root/cimv2')

=item B<--username>

Specify username for authentication

=item B<--password>

Specify password for authentication

=back

=head1 DESCRIPTION

B<custom>.

=cut
