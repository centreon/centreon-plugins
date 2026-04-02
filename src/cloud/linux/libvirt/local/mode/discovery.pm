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

package cloud::linux::libvirt::local::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded json_encode convert_bytes);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'          => { name => 'prettify',      default => 0 },
        'include-name:s'    => { name => 'include_name',  default => '' },
        'exclude-name:s'    => { name => 'exclude_name',  default => '' },
        'include-state:s'   => { name => 'include_state', default => '' },
        'exclude-state:s'   => { name => 'exclude_state', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    # virsh list --all
    #  Id   Name            State
    # -----------------------------------
    #  1    myvm            running
    #  -    stopped-vm      shut off
    my $stdout = $options{custom}->execute_command(virsh_args => 'list --all');

    my @results;
    foreach (split(/\n/, $stdout)) {
        next if /^\s*(Id\s+Name)\s*/i;
        next unless /^\s*(\S+)\s+(\S+)\s+(.+?)\s*$/;
        my ($id, $name, $state) = ($1, $2, $3);
        $state = lc($state) =~ s/\s+/_/gr; # Normalize state (e.g., "shut off" -> "shut_off")

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name});
        next if is_excluded($state, $self->{option_results}->{include_state}, $self->{option_results}->{exclude_state});

        my $vm = {
            vm_name => $name,
            vm_id   => $id,
            state   => $state
        };

        # Enrich with dominfo for running VMs
        if ($state eq 'running') {
            my $info = $options{custom}->execute_command(
                virsh_args => "dominfo $name",
                no_quit    => 1
            );
            if ($info) {
                $vm->{vcpus}      = $1 if $info =~ /CPU\(s\):\s+(\d+)/i;
                $vm->{max_mem_bytes} = convert_bytes(value => $1, unit => $2) if $info =~ /Max memory:\s+(\d+)\s+(.*)/i;
                $vm->{uuid}       = $1      if $info =~ /UUID:\s+(\S+)/i;
            }
        }

        push @results, $vm;
    }

    $disco_stats->{end_time}         = time();
    $disco_stats->{duration}         = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@results);
    $disco_stats->{results}          = \@results;

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => json_encode($disco_stats, prettify => $self->{option_results}->{prettify}, output => $self->{output})
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Discover virtual machines (C<virsh list --all>).
Returns a JSON document suitable for Centreon Auto Discovery.

=over 8

=item B<--prettify>

Format JSON output with indentation.

=item B<--include-name>

Filter VMs by name (regexp).

=item B<--exclude-name>

Exclude VMs whose name matches this regexp.

=item B<--include-state>

Filter VMs by state (regexp).

=item B<--exclude-state>

Exclude VMs whose state matches this regexp.

=back

=cut
