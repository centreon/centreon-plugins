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

package os::linux::local::mode::listinterfaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' },
        'filter-state:s' => { name => 'filter_state' },
        'no-loopback'    => { name => 'no_loopback' },
        'skip-novalues'  => { name => 'skip_novalues' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command_path => '/sbin',
        command => 'ip',
        command_options => '-s addr 2>&1'
    );

    my $mapping = {
        ifconfig => {
            get_interface => '^(\S+)(.*?)(\n\n|\n$)',
            test => 'RX bytes:\S+.*?TX bytes:\S+'
        },
        iproute => {
            get_interface => '^\d+:\s+(\S+)(.*?)(?=\n\d|\Z$)',
            test => 'RX:\s+bytes.*?\d+'
        }
    };
    
    my $type = 'ifconfig';
    if ($stdout =~ /^\d+:\s+\S+:\s+</ms) {
        $type = 'iproute';
    }

    my $results = {};
    while ($stdout =~ /$mapping->{$type}->{get_interface}/msg) {
        my ($interface_name, $values) = ($1, $2);
        $interface_name =~ s/:$//;
        my $states = '';
        $states .= 'R' if ($values =~ /RUNNING|LOWER_UP/ms);
        $states .= 'U' if ($values =~ /UP/ms);
        
        if (defined($self->{option_results}->{no_loopback}) && $values =~ /LOOPBACK/ms) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': option --no-loopback");
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $interface_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': no matching filter name");
            next;
        }
        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $states !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': no matching filter state");
            next;
        }
        
        if (defined($self->{option_results}->{skip_novalues}) && $values =~ /$mapping->{$type}->{test}/msi) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': no values");
            next;
        }

        $results->{$interface_name} = { state => $states };
    }    

    return $results;
}

sub run {
    my ($self, %options) = @_;
	
    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [state = '" . $results->{$name}->{state} . "']");
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List interfaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {     
        $self->{output}->add_disco_entry(
            name => $name,
            state => $results->{$name}->{state}
        );
    }
}

1;

__END__

=head1 MODE

List storages.

Command used: /sbin/ip -s addr 2>&1

=over 8

=item B<--filter-name>

Filter interface name (regexp can be used).

=item B<--filter-state>

Filter state (regexp can be used).
Can be: 'R' (running), 'U' (up).

=item B<--no-loopback>

Don't display loopback interfaces.

=item B<--skip-novalues>

Filter interface without in/out byte values.

=back

=cut
