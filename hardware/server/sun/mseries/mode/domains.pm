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

package hardware::server::sun::mseries::mode::domains;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %error_status = (
    1 => ["The domain '%s' status is normal", 'OK'],
    2 => ["The domain '%s' status is degraded", 'WARNING'], 
    3 => ["The domain '%s' status is faulted", 'CRITICAL'],
    254 => ["The domain '%s' status has changed", 'WARNING'],
    255 => ["The domain '%s' status is unknown", 'UNKNOWN'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "skip"  => { name => 'skip' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_scfDomainErrorStatus = '.1.3.6.1.4.1.211.1.15.3.1.1.5.2.1.15';
    my $oids_domain_status = $self->{snmp}->get_table(oid => $oid_scfDomainErrorStatus, nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All domains are ok.");
    foreach ($self->{snmp}->oid_lex_sort(keys %$oids_domain_status)) {
        /^${oid_scfDomainErrorStatus}\.(.*)/;
        my $domain_id = $1;
        $self->{output}->output_add(long_msg => sprintf(${$error_status{$oids_domain_status->{$_}}}[0], $domain_id));
        if ($oids_domain_status->{$_} == 255 && defined($self->{option_results}->{skip})) {
            next;
        }
        if ($oids_domain_status->{$_} != 1) {
            $self->{output}->output_add(severity => ${$error_status{$oids_domain_status->{$_}}}[1],
                                        short_msg => sprintf(${$error_status{$oids_domain_status->{$_}}}[0], $domain_id));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Mseries domains status.

=over 8

=item B<--skip>

Skip 'unknown' domains.

=back

=cut
    