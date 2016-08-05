#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::mode::hypervisor;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    status => [
        ['up', 'OK'],
        ['down', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "tenant-id:s"             => { name => 'tenant_id' },
            "hypervisor-id:s"         => { name => 'hypervisor_id' },
            "threshold-overload:s@"   => { name => 'threshold_overload' },
        });

    $self->{hypervisor_infos} = ();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

	$self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

	if (!defined($self->{option_results}->{tenant_id}) || $self->{option_results}->{tenant_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --tenant-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hypervisor_id}) || $self->{option_results}->{hypervisor_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --hypervisor-id option.");
        $self->{output}->option_exit();
    }
}

sub hypervisor_request {
    my ($self, %options) = @_;

    my $urlpath = "/v2/".$self->{option_results}->{tenant_id}."/os-hypervisors/".$self->{option_results}->{hypervisor_id};
    my $port = '8774';

    my $hypervisorapi = $options{custom};
    my $webcontent = $hypervisorapi->api_request(urlpath => $urlpath,
                                                    port => $port,);

    $self->{hypervisor_infos}->{name} = $webcontent->{hypervisor}->{hypervisor_hostname};
    $self->{hypervisor_infos}->{state} = $webcontent->{hypervisor}->{state};
    $self->{hypervisor_infos}->{status} = $webcontent->{hypervisor}->{status};
}


sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default

    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }

    return $status;
}

sub run {
    my ($self, %options) = @_;

    $self->hypervisor_request(%options);

	my $exit = $self->get_severity(section => 'status', value => $self->{hypervisor_infos}->{state});
	$self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Hypervisor %s is %s (status: %s)",
                                                    $self->{hypervisor_infos}->{name},
                                                    $self->{hypervisor_infos}->{state},
                                                    $self->{hypervisor_infos}->{status}));

    $self->{output}->display();
    $self->{output}->exit();

    exit 0;
}

1;

__END__

=head1 MODE

List OpenStack instances through Compute API V2

=over 8

=item B<--tenant-id>

Set Tenant's ID

=item B<--hypervisor-id>

Set Hypervisor's ID

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='status,WARNING,^down$)'

=back

=cut
