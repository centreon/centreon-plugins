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

package apps::protocols::snmp::mode::cache;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'file:s'      => { name => 'file' },
        'snmpwalk:s@' => { name => 'snmpwalk' },
        'snmpget:s@'  => { name => 'snmpget' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{file}) || $self->{option_results}->{file} eq '') {
        $self->{output}->add_option_msg(short_msg => "Missing parameter --file");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $snmp_datas = {};
    if (defined($self->{option_results}->{snmpwalk})) {
        foreach my $oid (@{$self->{option_results}->{snmpwalk}}) {
            my $result = $options{snmp}->get_table(oid => $oid);
            $snmp_datas = { %$snmp_datas, %$result };
        }
    }

    if (defined($self->{option_results}->{snmpget})) {
        my $result = $options{snmp}->get_leef(oids => $self->{option_results}->{snmpget});
        $snmp_datas = { %$snmp_datas, %$result };
    }

    my $json;
    eval {
        $json = JSON::XS->new->encode($snmp_datas);
    };

    my $fh;
    if (!open($fh, '>', $self->{option_results}->{file})) {
        $self->{output}->add_option_msg(short_msg => "Can't open file '$self->{option_results}->{file}': $!");
        $self->{output}->option_exit();
    }
    print $fh $json;
    close($fh);

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'SNMP cache file created'
    );

    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}
    
1;

__END__

=head1 MODE

Cache SNMP datas in a JSON cache file.

=over 8

=item B<--file>

JSON cache file path.

=item B<--snmpget>

Retrieve a management value.

=item B<--snmpwalk>

Retrieve a subtree of management values.

=back

=cut
