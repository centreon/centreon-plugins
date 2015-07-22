
package Paws::Route53::ListResourceRecordSets {
  use Moose;
  has HostedZoneId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);
  has MaxItems => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'maxitems' );
  has StartRecordIdentifier => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'identifier' );
  has StartRecordName => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'name' );
  has StartRecordType => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'type' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListResourceRecordSets');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/hostedzone/{Id}/rrset');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::ListResourceRecordSetsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::ListResourceRecordSetsResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> HostedZoneId => Str

  

The ID of the hosted zone that contains the resource record sets that
you want to get.









=head2 MaxItems => Str

  

The maximum number of records you want in the response body.









=head2 StartRecordIdentifier => Str

  

I<Weighted resource record sets only:> If results were truncated for a
given DNS name and type, specify the value of
C<ListResourceRecordSetsResponse$NextRecordIdentifier> from the
previous response to get the next resource record set that has the
current DNS name and type.









=head2 StartRecordName => Str

  

The first name in the lexicographic ordering of domain names that you
want the C<ListResourceRecordSets> request to list.









=head2 StartRecordType => Str

  

The DNS type at which to begin the listing of resource record sets.

Valid values: C<A> | C<AAAA> | C<CNAME> | C<MX> | C<NS> | C<PTR> |
C<SOA> | C<SPF> | C<SRV> | C<TXT>

Values for Weighted Resource Record Sets: C<A> | C<AAAA> | C<CNAME> |
C<TXT>

Values for Regional Resource Record Sets: C<A> | C<AAAA> | C<CNAME> |
C<TXT>

Values for Alias Resource Record Sets: C<A> | C<AAAA>

Constraint: Specifying C<type> without specifying C<name> returns an
InvalidInput error.











=cut

