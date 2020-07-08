#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package blockchain::hyperledger::blockstats::mode::users;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'users', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All user metrics are ok' }
    ];

    $self->{maps_counters}->{users} = [
        { label => 'transactions', nlabel => 'user.transactions.count', set => {
                key_values => [ { name => 'transactions' }, { name => 'display' } ],
                output_template => 'Transactions: %d',
                perfdatas => [
                    { label => 'transactions', value => 'transactions_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        # { label => 'patate', set => {
        #         key_values => [ { name => 'toto' } ],
        #         output_template => 'Patate: %d',
        #         perfdatas => [
        #             { label => 'patate', value => 'toto_absolute', template => '%d',
        #               min => 0 },
        #         ],
        #     }
        # },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "User '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

# [
#     {
#         "mspid": "OrdererMSP",
#         "nbTransactions": 3,
#         "id": "-----BEGIN CERTIFICATE-----\nMIICDDCCAbOgAwIBAgIRAIdowj9Q4vB5Apc0o8yzkeYwCgYIKoZIzj0EAwIwaTEL\nMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNhbiBG\ncmFuY2lzY28xFDASBgNVBAoTC2V4YW1wbGUuY29tMRcwFQYDVQQDEw5jYS5leGFt\ncGxlLmNvbTAeFw0yMDAzMDkxNTM4MDBaFw0zMDAzMDcxNTM4MDBaMFgxCzAJBgNV\nBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1TYW4gRnJhbmNp\nc2NvMRwwGgYDVQQDExNvcmRlcmVyLmV4YW1wbGUuY29tMFkwEwYHKoZIzj0CAQYI\nKoZIzj0DAQcDQgAEDfHVTSMxauOjVtbNbMexaTHDGZigzw+oobZxPtl3kbwpeivi\nsHxI5Se905Ubhe8IgTLlb5z6TEZnox+ettfkEaNNMEswDgYDVR0PAQH/BAQDAgeA\nMAwGA1UdEwEB/wQCMAAwKwYDVR0jBCQwIoAgViEjKSIbTWJMbFHuzXcYDaa3/x3X\n1MBtSzOmA2cPyQYwCgYIKoZIzj0EAwIDRwAwRAIgTrCeKfClxW6NhcRcyIyQVvnq\nnL80ERS1BczZ2iNbk9cCIFtKzdsZIeExrsws8PqJ22cNrqImWEnMQdWiGM74ErLf\n-----END CERTIFICATE-----\n"
#     },
#     {
#         "mspid": "Org2MSP",
#         "nbTransactions": 2,
#         "id": "-----BEGIN CERTIFICATE-----\nMIICKTCCAdCgAwIBAgIQQsBHGdrocdtLPiWxFn2sVDAKBggqhkjOPQQDAjBzMQsw\nCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZy\nYW5jaXNjbzEZMBcGA1UEChMQb3JnMi5leGFtcGxlLmNvbTEcMBoGA1UEAxMTY2Eu\nb3JnMi5leGFtcGxlLmNvbTAeFw0yMDAzMDkxNTM4MDBaFw0zMDAzMDcxNTM4MDBa\nMGwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1T\nYW4gRnJhbmNpc2NvMQ8wDQYDVQQLEwZjbGllbnQxHzAdBgNVBAMMFkFkbWluQG9y\nZzIuZXhhbXBsZS5jb20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAT/zvG/BLu4\ndyNup040hFkLSsxIRwTEo1vJWB2+lSVe54tzAY1E2nQt+TBL3IZpFp5eEqv/vDR2\nfJtuxwZ+xbmAo00wSzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADArBgNV\nHSMEJDAigCDOEne+k0DlxQsaWRfBidONZ/ttMaqja2F06hAgp0JlizAKBggqhkjO\nPQQDAgNHADBEAiAWRNUItUbQNAtPZU3W1P/mwCarQtb0h4x45ZJiZhys7gIgRp7E\n47NFi2lQUrKgJoE3HBgUq6ZQyGki/aWlZA51ybo=\n-----END CERTIFICATE-----\n"
#     }
# ]

sub manage_selection {
    my ($self, %options) = @_;

    $self->{users} = {};

    my $results = $options{custom}->request_api(url_path => '/statistics/users');

    foreach my $user (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $user->{mspid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $user->{mspid} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{users}->{$user->{mspid}}->{display} = $user->{mspid};
        $self->{users}->{$user->{mspid}}->{transactions} = $user->{nbTransactions};
        # $self->{users}->{$user->{mspid}}->{toto} = $user->{nbpatates};

    }
    
    if (scalar(keys %{$self->{users}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No users found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check blockchain statistics

=cut
