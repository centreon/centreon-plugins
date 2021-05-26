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

package apps::bind9::web::mode::serverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

# From Bind 9.11.5 counter list
# opcode = completed
# rcode = not started
# qtype = completed
# nsstat = completed
# zonestat = completed
# resstat = not started

# Counter name, message, nlabel
my @map = (
    ['opcode-query', 'opcode query : %s', 'opcode.query.count'],
    ['opcode-iquery', 'opcode iquery : %s', 'opcode.iquery.count'],
    ['opcode-status', 'opcode status : %s', 'opcode.status.count'],
    ['opcode-notify', 'opcode notify : %s', 'opcode.notify.count'],
    ['opcode-update', 'opcode update : %s', 'opcode.update.count'],
    ['qtype-a', 'qtype A : %s', 'qtype.a.count'],
    ['qtype-ns', 'qtype NS : %s', 'qtype.ns.count'],
    ['qtype-cname', 'qtype CNAME : %s', 'qtype.cname.count'],
    ['qtype-soa', 'qtype SOA : %s', 'qtype.soa.count'],
    ['qtype-null', 'qtype NULL : %s', 'qtype.null.count'],
    ['qtype-wks', 'qtype WKS : %s', 'qtype.wks.count'],
    ['qtype-ptr', 'qtype PTR : %s', 'qtype.ptr.count'],
    ['qtype-hinfo', 'qtype HINFO : %s', 'qtype.hinfo.count'],
    ['qtype-mx', 'qtype MX : %s', 'qtype.mx.count'],
    ['qtype-txt', 'qtype TXT : %s', 'qtype.txt.count'],
    ['qtype-aaaa', 'qtype AAAA : %s', 'qtype.aaaa.count'],
    ['qtype-srv', 'qtype SRV : %s', 'qtype.srv.count'],
    ['qtype-naptr', 'qtype NAPTR : %s', 'qtype.naptr.count'],
    ['qtype-a6', 'qtype A6 : %s', 'qtype.a6.count'],
    ['qtype-ds', 'qtype DS : %s', 'qtype.ds.count'],
    ['qtype-rrsig', 'qtype RRSIG : %s', 'qtype.rrsig.count'],
    ['qtype-nsec', 'qtype NSEC : %s', 'qtype.nsec.count'],
    ['qtype-dnskey', 'qtype DNSKEY : %s', 'qtype.dnskey.count'],
    ['qtype-tlsa', 'qtype TLSA : %s', 'qtype.tlsa.count'],
    ['qtype-cds', 'qtype CDS : %s', 'qtype.cds.count'],
    ['qtype-type65', 'qtype TYPE65 : %s', 'qtype.type65.count'],
    ['qtype-spf', 'qtype SPF : %s', 'qtype.spf.count'],
    ['qtype-axfr', 'qtype AXFR : %s', 'qtype.axfr.count'],
    ['qtype-any', 'qtype ANY : %s', 'qtype.any.count'],
    ['qtype-others', 'qtype Others : %s', 'qtype.others.count'],
    ['nsstat-requestv4', 'nsstat Request v4 : %s', 'nsstat.requestv4.count'],
    ['nsstat-requestv6', 'nsstat Request v6 : %s', 'nsstat.requestv6.count'],
    ['nsstat-reqedns0', 'nsstat ReqEdns0 : %s', 'nsstat.reqedns0.count'],
    ['nsstat-reqbadednsver', 'nsstat ReqBadEDNSVer : %s', 'nsstat.reqbadednsver.count'],
    ['nsstat-reqtsig', 'nsstat ReqTSIG : %s', 'nsstat.reqtsig.count'],
    ['nsstat-reqsig0', 'nsstat ReqSIG0 : %s', 'nsstat.reqsig0.count'],
    ['nsstat-reqbadsig', 'nsstat ReqBadSIG : %s', 'nsstat.reqbadsig.count'],
    ['nsstat-reqtcp', 'nsstat ReqTCP : %s', 'nsstat.reqtcp.count'],
    ['nsstat-authqryrej', 'nsstat AuthQryRej : %s', 'nsstat.authqryrej.count'],
    ['nsstat-recqryrej', 'nsstat RecQryRej : %s', 'nsstat.recqryrej.count'],
    ['nsstat-xfrrej', 'nsstat XfrRej : %s', 'nsstat.xfrrej.count'],
    ['nsstat-updaterej', 'nsstat UpdateRej : %s', 'nsstat.updaterej.count'],
    ['nsstat-response', 'nsstat Response : %s', 'nsstat.response.count'],
    ['nsstat-truncatedresp', 'nsstat TruncatedResp : %s', 'nsstat.truncatedresp.count'],
    ['nsstat-respedns0', 'nsstat RespEDNS0 : %s', 'nsstat.respedns0.count'],
    ['nsstat-resptsig', 'nsstat RespTSIG : %s', 'nsstat.resptsig.count'],
    ['nsstat-respsig0', 'nsstat RespSIG0 : %s', 'nsstat.respsig0.count'],
    ['nsstat-qrysuccess', 'nsstat QrySuccess : %s', 'nsstat.qrysuccess.count'],
    ['nsstat-qryauthans', 'nsstat QryAuthAns : %s', 'nsstat.qryauthans.count'],
    ['nsstat-qrynoauthans', 'nsstat QryNoauthAns : %s', 'nsstat.qrynoauthans.count'],
    ['nsstat-qryreferral', 'nsstat QryReferral : %s', 'nsstat.qryreferral.count'],
    ['nsstat-qrynxrrset', 'nsstat QryNxrrset : %s', 'nsstat.qrynxrrset.count'],
    ['nsstat-qryservfail', 'nsstat QrySERVFAIL : %s', 'nsstat.qryservfail.count'],
    ['nsstat-qryformerr', 'nsstat QryFORMERR : %s', 'nsstat.qryformerr.count'],
    ['nsstat-qrynxdomain', 'nsstat QryNXDOMAIN : %s', 'nsstat.qrynxdomain.count'],
    ['nsstat-qryrecursion', 'nsstat QryRecursion : %s', 'nsstat.qryrecursion.count'],
    ['nsstat-qryduplicate', 'nsstat QryDuplicate : %s', 'nsstat.qryduplicate.count'],
    ['nsstat-qrydropped', 'nsstat QryDropped : %s', 'nsstat.qrydropped.count'],
    ['nsstat-qryfailure', 'nsstat QryFailure : %s', 'nsstat.qryfailure.count'],
    ['nsstat-xfrreqdone', 'nsstat XfrReqDone : %s', 'nsstat.xfrreqdone.count'],
    ['nsstat-updatereqfwd', 'nsstat UpdateReqFwd : %s', 'nsstat.updatereqfwd.count'],
    ['nsstat-updaterespfwd', 'nsstat UpdateRespFwd : %s', 'nsstat.updaterespfwd.count'],
    ['nsstat-updatefwdfail', 'nsstat UpdateFwdFail : %s', 'nsstat.updatefwdfail.count'],
    ['nsstat-updatedone', 'nsstat UpdateDone : %s', 'nsstat.updatedone.count'],
    ['nsstat-updatefail', 'nsstat UpdateFail : %s', 'nsstat.updatefail.count'],
    ['nsstat-updatebadprereq', 'nsstat UpdateBadPrereq : %s', 'nsstat.updatebadprereq.count'],
    ['nsstat-recursclients', 'nsstat RecursClients : %s', 'nsstat.recursclients.count'],
    ['nsstat-dns64', 'nsstat RateDropped : %s', 'nsstat.ratedropped.count'],
    ['nsstat-ratedropped', 'nsstat RateDropped : %s', 'nsstat.ratedropped.count'],
    ['nsstat-rateslipped', 'nsstat RateSlipped : %s', 'nsstat.rateslipped.count'],
    ['nsstat-rpzrewrites', 'nsstat RPZRewrites : %s', 'nsstat.rpzrewrites.count'],
    ['nsstat-qryudp', 'nsstat QryUDP : %s', 'nsstat.qryudp.count'],
    ['nsstat-qrytcp', 'nsstat QryTCP : %s', 'nsstat.qrytcp.count'],
    ['nsstat-nsidopt', 'nsstat NSIDOpt : %s', 'nsstat.nsidopt.count'],
    ['nsstat-expireopt', 'nsstat ExpireOpt : %s', 'nsstat.expireopt.count'],
    ['nsstat-otheropt', 'nsstat OtherOpt : %s', 'nsstat.otheropt.count'],
    ['nsstat-cookiein', 'nsstat CookieIn : %s', 'nsstat.cookiein.count'],
    ['nsstat-cookienew ', 'nsstat CookieNew  : %s', 'nsstat.cookienew .count'],
    ['nsstat-cookiebadsize', 'nsstat CookieBadSize : %s', 'nsstat.cookiebadsize.count'],
    ['nsstat-cookiebadtime', 'nsstat CookieBadTime : %s', 'nsstat.cookiebadtime.count'],
    ['nsstat-cookienomatch', 'nsstat CookieNoMatch : %s', 'nsstat.cookienomatch.count'],
    ['nsstat-cookiematch', 'nsstat CookieMatch : %s', 'nsstat.cookiematch.count'],
    ['nsstat-ecsopt', 'nsstat ECSOpt : %s', 'nsstat.ecsopt.count'],
    ['nsstat-qrynxredir', 'nsstat QryNXRedir : %s', 'nsstat.qrynxredir.count'],
    ['nsstat-qrynxredirrlookup', 'nsstat QryNXRedirRLookup : %s', 'nsstat.qrynxredirrlookup.count'],
    ['nsstat-qrybadcookie', 'nsstat QryBADCOOKIE : %s', 'nsstat.qrybadcookie.count'],
    ['nsstat-keytagopt', 'nsstat KeyTagOpt : %s', 'nsstat.keytagopt.count'],
    ['zonestat-keytagopt', 'zonestat NotifyOutv4 : %s', 'zonestat.notifyoutv4.count'],
    ['zonestat-notifyoutv6', 'zonestat NotifyOutv6 : %s', 'zonestat.notifyoutv6.count'],
    ['zonestat-notifyinv4', 'zonestat NotifyInv4 : %s', 'zonestat.notifyinv4.count'],
    ['zonestat-notifyinv6', 'zonestat NotifyInv6 : %s', 'zonestat.notifyinv6.count'],
    ['zonestat-notifyrej', 'zonestat NotifyRej : %s', 'zonestat.notifyrej.count'],
    ['zonestat-soaoutv4', 'zonestat SOAOutv4 : %s', 'zonestat.soaoutv4.count'],
    ['zonestat-soaoutv6', 'zonestat SOAOutv6 : %s', 'zonestat.soaoutv6.count'],
    ['zonestat-axfrreqv4', 'zonestat AXFRReqv4 : %s', 'zonestat.axfrreqv4.count'],
    ['zonestat-axfrreqv6', 'zonestat AXFRReqv6 : %s', 'zonestat.axfrreqv6.count'],
    ['zonestat-ixfrreqv4', 'zonestat IXFRReqv4 : %s', 'zonestat.ixfrreqv4.count'],
    ['zonestat-ixfrreqv6', 'zonestat IXFRReqv6 : %s', 'zonestat.ixfrreqv6.count'],
    ['zonestat-xfrsuccess', 'zonestat XfrSuccess : %s', 'zonestat.xfrsuccess.count'],
    ['zonestat-xfrfail', 'zonestat XfrFail : %s', 'zonestat.xfrfail.count']
);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'server', type => 0, skipped_code => { -1 => 1, -10 => 1, 11 => -1 } }
    ];

    $self->{maps_counters}->{server} = [];
    for (my $i = 0; $i < scalar(@map); $i++) {
        push @{$self->{maps_counters}->{server}}, {
            label => $map[$i]->[0], nlabel => => $map[$i]->[2], display_ok => 0,
            set => {
                key_values => [ { name => $map[$i]->[0], diff => 1 } ],
                output_template => $map[$i]->[1],
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{filter_counters})) {
        $self->{option_results}->{filter_counters} = 'opcode-query|opcode-iquery|opcode-status|opcode-notify|opcode-update|' .
            'qtype-a|qtype-aaaa|qtype-cname|qtype-mx|qtype-txt|qtype-soa|qtype-ptr|' .
            'nsstat-requestv4|nsstat-requestv6';
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my $result = $options{custom}->get_server();
    $self->{server} = { };

    # Init for all vars, some are not present in response if no request on the server
    for (my $i = 0; $i < scalar(@map); $i++) {
      $self->{server}->{ $map[$i]->[0] } = 0;
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'All Bind 9 counters are ok'
    );

    foreach my $type (keys %{$result->{counters}}) {
        foreach my $counter (keys %{$result->{counters}->{$type}}) {
            $self->{server}->{lc($type) . '-' . lc($counter)} = $result->{counters}->{$type}->{$counter};
        }
    }

    $self->{cache_name} = 'bind9_' . $self->{mode} . '_' . $options{custom}->get_uniq_id()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Bind global server usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='nsstat-requestv6'

Show the full list with --list-counters.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be any of the selected counters.

=back

=cut
