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

package apps::backup::netbackup::local::mode::listpolicies;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{policies}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
            $_ !~ /$self->{option_results}->{filter_name}/i) {
            $self->{output}->output_add(long_msg => "skipping policy '" . $_ . "': no type or no matching filter type");
            next;
        }

        $self->{output}->output_add(long_msg => "'" . $_ . "' [active = " . $self->{policies}->{$_}->{active}  . "]");
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List policy:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'active']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{policies}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
            $_ !~ /$self->{option_results}->{filter_name}/i);

        $self->{output}->add_disco_entry(
            name => $_,
            active => $self->{policies}->{$_}->{active}
        );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'bppllist'
    );

    $self->{policies} = {};
    my @lines = split /\n/, $stdout;
    foreach my $policy_name (@lines) {
        ($stdout) = $options{custom}->execute_command(
            command => 'bpplinfo',
            command_options => $policy_name . ' -L'
        );

        #Policy Type:            NBU-Catalog (35)
        #Active:                 yes        
        my $active = '';
        $active = $1 if ($stdout =~ /^Active\s*:\s+(\S+)/msi);
        $self->{policies}->{$policy_name} = { active => $active };
    }
}

1;

__END__

=head1 MODE

List policies.

Command used: 'bppllist' and 'bpplinfo %{policy_name} -L'

=over 8

=item B<--filter-name>

Filter policy name (can be a regexp).

=back

=cut
