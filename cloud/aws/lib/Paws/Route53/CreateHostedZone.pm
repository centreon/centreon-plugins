
package Paws::Route53::CreateHostedZone {
  use Moose;
  has CallerReference => (is => 'ro', isa => 'Str', required => 1);
  has DelegationSetId => (is => 'ro', isa => 'Str');
  has HostedZoneConfig => (is => 'ro', isa => 'Paws::Route53::HostedZoneConfig');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has VPC => (is => 'ro', isa => 'Paws::Route53::VPC');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateHostedZone');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/hostedzone');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::CreateHostedZoneResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::CreateHostedZoneResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> CallerReference => Str

  

A unique string that identifies the request and that allows failed
C<CreateHostedZone> requests to be retried without the risk of
executing the operation twice. You must use a unique C<CallerReference>
string every time you create a hosted zone. C<CallerReference> can be
any unique string; you might choose to use a string that identifies
your project, such as C<DNSMigration_01>.

Valid characters are any Unicode code points that are legal in an XML
1.0 document. The UTF-8 encoding of the value must be less than 128
bytes.









=head2 DelegationSetId => Str

  

The delegation set id of the reusable delgation set whose NS records
you want to assign to the new hosted zone.









=head2 HostedZoneConfig => Paws::Route53::HostedZoneConfig

  

A complex type that contains an optional comment about your hosted
zone.









=head2 B<REQUIRED> Name => Str

  

The name of the domain. This must be a fully-specified domain, for
example, www.example.com. The trailing dot is optional; Route 53
assumes that the domain name is fully qualified. This means that Route
53 treats www.example.com (without a trailing dot) and www.example.com.
(with a trailing dot) as identical.

This is the name you have registered with your DNS registrar. You
should ask your registrar to change the authoritative name servers for
your domain to the set of C<NameServers> elements returned in
C<DelegationSet>.









=head2 VPC => Paws::Route53::VPC

  

The VPC that you want your hosted zone to be associated with. By
providing this parameter, your newly created hosted cannot be resolved
anywhere other than the given VPC.











=cut

