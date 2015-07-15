package Paws::Route53 {
  warn "Paws::Route53 is not stable / supported / entirely developed";
  use Moose;
  sub service { 'route53' }
  sub version { '2013-04-01' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V3HTTPSSignature', 'Paws::Net::RestXmlCaller', 'Paws::Net::RestXMLResponse';

  
  sub AssociateVPCWithHostedZone {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::AssociateVPCWithHostedZone', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ChangeResourceRecordSets {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ChangeResourceRecordSets', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ChangeTagsForResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ChangeTagsForResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateHealthCheck {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::CreateHealthCheck', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateHostedZone {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::CreateHostedZone', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateReusableDelegationSet {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::CreateReusableDelegationSet', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteHealthCheck {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::DeleteHealthCheck', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteHostedZone {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::DeleteHostedZone', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteReusableDelegationSet {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::DeleteReusableDelegationSet', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisassociateVPCFromHostedZone {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::DisassociateVPCFromHostedZone', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetChange {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetChange', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetCheckerIpRanges {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetCheckerIpRanges', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetGeoLocation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetGeoLocation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetHealthCheck {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetHealthCheck', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetHealthCheckCount {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetHealthCheckCount', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetHealthCheckLastFailureReason {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetHealthCheckLastFailureReason', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetHealthCheckStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetHealthCheckStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetHostedZone {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetHostedZone', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetHostedZoneCount {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetHostedZoneCount', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetReusableDelegationSet {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::GetReusableDelegationSet', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListGeoLocations {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListGeoLocations', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListHealthChecks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListHealthChecks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListHostedZones {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListHostedZones', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListHostedZonesByName {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListHostedZonesByName', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListResourceRecordSets {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListResourceRecordSets', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListReusableDelegationSets {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListReusableDelegationSets', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTagsForResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListTagsForResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTagsForResources {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::ListTagsForResources', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateHealthCheck {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::UpdateHealthCheck', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateHostedZoneComment {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53::UpdateHostedZoneComment', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53 - Perl Interface to AWS Amazon Route 53

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('Route53')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon Route 53

Amazon Route 53 is a scalable Domain Name System (DNS) web service. It
provides secure and reliable routing to your infrastructure that uses
Amazon Web Services (AWS) products, such as Amazon Elastic Compute
Cloud (Amazon EC2), Elastic Load Balancing, or Amazon Simple Storage
Service (Amazon S3). You can also use Amazon Route 53 to route users to
your infrastructure outside of AWS.

Amazon Route 53 is an authoritative DNS service, meaning it translates
friendly domains names like www.example.com into IP addresses like
192.0.2.1. Amazon Route 53 responds to DNS queries using a global
network of authoritative DNS servers, which reduces latency. For a list
of the locations of Amazon Route 53 DNS servers, see The Amazon Route
53 Global Network on the Amazon Route 53 detail page.










=head1 METHODS

=head2 AssociateVPCWithHostedZone(HostedZoneId => Str, VPC => Paws::Route53::VPC, [Comment => Str])

Each argument is described in detail in: L<Paws::Route53::AssociateVPCWithHostedZone>

Returns: a L<Paws::Route53::AssociateVPCWithHostedZoneResponse> instance

  

This action associates a VPC with an hosted zone.

To associate a VPC with an hosted zone, send a C<POST> request to the
C<2013-04-01/hostedzone/I<hosted zone ID>/associatevpc> resource. The
request body must include an XML document with a
C<AssociateVPCWithHostedZoneRequest> element. The response returns the
C<AssociateVPCWithHostedZoneResponse> element that contains
C<ChangeInfo> for you to track the progress of the
C<AssociateVPCWithHostedZoneRequest> you made. See C<GetChange>
operation for how to track the progress of your change.











=head2 ChangeResourceRecordSets(ChangeBatch => Paws::Route53::ChangeBatch, HostedZoneId => Str)

Each argument is described in detail in: L<Paws::Route53::ChangeResourceRecordSets>

Returns: a L<Paws::Route53::ChangeResourceRecordSetsResponse> instance

  

Use this action to create or change your authoritative DNS information.
To use this action, send a C<POST> request to the
C<2013-04-01/hostedzone/I<hosted Zone ID>/rrset> resource. The request
body must include an XML document with a
C<ChangeResourceRecordSetsRequest> element.

Changes are a list of change items and are considered transactional.
For more information on transactional changes, also known as change
batches, see Creating, Changing, and Deleting Resource Record Sets
Using the Route 53 API in the I<Amazon Route 53 Developer Guide>.

Due to the nature of transactional changes, you cannot delete the same
resource record set more than once in a single change batch. If you
attempt to delete the same change batch more than once, Route 53
returns an C<InvalidChangeBatch> error.

In response to a C<ChangeResourceRecordSets> request, your DNS data is
changed on all Route 53 DNS servers. Initially, the status of a change
is C<PENDING>. This means the change has not yet propagated to all the
authoritative Route 53 DNS servers. When the change is propagated to
all hosts, the change returns a status of C<INSYNC>.

Note the following limitations on a C<ChangeResourceRecordSets>
request:

- A request cannot contain more than 100 Change elements.

- A request cannot contain more than 1000 ResourceRecord elements.

The sum of the number of characters (including spaces) in all C<Value>
elements in a request cannot exceed 32,000 characters.











=head2 ChangeTagsForResource(ResourceId => Str, ResourceType => Str, [AddTags => ArrayRef[Paws::Route53::Tag], RemoveTagKeys => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::Route53::ChangeTagsForResource>

Returns: a L<Paws::Route53::ChangeTagsForResourceResponse> instance

  


=head2 CreateHealthCheck(CallerReference => Str, HealthCheckConfig => Paws::Route53::HealthCheckConfig)

Each argument is described in detail in: L<Paws::Route53::CreateHealthCheck>

Returns: a L<Paws::Route53::CreateHealthCheckResponse> instance

  

This action creates a new health check.

To create a new health check, send a C<POST> request to the
C<2013-04-01/healthcheck> resource. The request body must include an
XML document with a C<CreateHealthCheckRequest> element. The response
returns the C<CreateHealthCheckResponse> element that contains metadata
about the health check.











=head2 CreateHostedZone(CallerReference => Str, Name => Str, [DelegationSetId => Str, HostedZoneConfig => Paws::Route53::HostedZoneConfig, VPC => Paws::Route53::VPC])

Each argument is described in detail in: L<Paws::Route53::CreateHostedZone>

Returns: a L<Paws::Route53::CreateHostedZoneResponse> instance

  

This action creates a new hosted zone.

To create a new hosted zone, send a C<POST> request to the
C<2013-04-01/hostedzone> resource. The request body must include an XML
document with a C<CreateHostedZoneRequest> element. The response
returns the C<CreateHostedZoneResponse> element that contains metadata
about the hosted zone.

Route 53 automatically creates a default SOA record and four NS records
for the zone. The NS records in the hosted zone are the name servers
you give your registrar to delegate your domain to. For more
information about SOA and NS records, see NS and SOA Records that Route
53 Creates for a Hosted Zone in the I<Amazon Route 53 Developer Guide>.

When you create a zone, its initial status is C<PENDING>. This means
that it is not yet available on all DNS servers. The status of the zone
changes to C<INSYNC> when the NS and SOA records are available on all
Route 53 DNS servers.

When trying to create a hosted zone using a reusable delegation set,
you could specify an optional DelegationSetId, and Route53 would assign
those 4 NS records for the zone, instead of alloting a new one.











=head2 CreateReusableDelegationSet(CallerReference => Str, [HostedZoneId => Str])

Each argument is described in detail in: L<Paws::Route53::CreateReusableDelegationSet>

Returns: a L<Paws::Route53::CreateReusableDelegationSetResponse> instance

  

This action creates a reusable delegationSet.

To create a new reusable delegationSet, send a C<POST> request to the
C<2013-04-01/delegationset> resource. The request body must include an
XML document with a C<CreateReusableDelegationSetRequest> element. The
response returns the C<CreateReusableDelegationSetResponse> element
that contains metadata about the delegationSet.

If the optional parameter HostedZoneId is specified, it marks the
delegationSet associated with that particular hosted zone as reusable.











=head2 DeleteHealthCheck(HealthCheckId => Str)

Each argument is described in detail in: L<Paws::Route53::DeleteHealthCheck>

Returns: a L<Paws::Route53::DeleteHealthCheckResponse> instance

  

This action deletes a health check. To delete a health check, send a
C<DELETE> request to the C<2013-04-01/healthcheck/I<health check ID>>
resource.

You can delete a health check only if there are no resource record sets
associated with this health check. If resource record sets are
associated with this health check, you must disassociate them before
you can delete your health check. If you try to delete a health check
that is associated with resource record sets, Route 53 will deny your
request with a C<HealthCheckInUse> error. For information about
disassociating the records from your health check, see
ChangeResourceRecordSets.











=head2 DeleteHostedZone(Id => Str)

Each argument is described in detail in: L<Paws::Route53::DeleteHostedZone>

Returns: a L<Paws::Route53::DeleteHostedZoneResponse> instance

  

This action deletes a hosted zone. To delete a hosted zone, send a
C<DELETE> request to the C<2013-04-01/hostedzone/I<hosted zone ID>>
resource.

For more information about deleting a hosted zone, see Deleting a
Hosted Zone in the I<Amazon Route 53 Developer Guide>.

You can delete a hosted zone only if there are no resource record sets
other than the default SOA record and NS resource record sets. If your
hosted zone contains other resource record sets, you must delete them
before you can delete your hosted zone. If you try to delete a hosted
zone that contains other resource record sets, Route 53 will deny your
request with a C<HostedZoneNotEmpty> error. For information about
deleting records from your hosted zone, see ChangeResourceRecordSets.











=head2 DeleteReusableDelegationSet(Id => Str)

Each argument is described in detail in: L<Paws::Route53::DeleteReusableDelegationSet>

Returns: a L<Paws::Route53::DeleteReusableDelegationSetResponse> instance

  

This action deletes a reusable delegation set. To delete a reusable
delegation set, send a C<DELETE> request to the
C<2013-04-01/delegationset/I<delegation set ID>> resource.

You can delete a reusable delegation set only if there are no
associated hosted zones. If your reusable delegation set contains
associated hosted zones, you must delete them before you can delete
your reusable delegation set. If you try to delete a reusable
delegation set that contains associated hosted zones, Route 53 will
deny your request with a C<DelegationSetInUse> error.











=head2 DisassociateVPCFromHostedZone(HostedZoneId => Str, VPC => Paws::Route53::VPC, [Comment => Str])

Each argument is described in detail in: L<Paws::Route53::DisassociateVPCFromHostedZone>

Returns: a L<Paws::Route53::DisassociateVPCFromHostedZoneResponse> instance

  

This action disassociates a VPC from an hosted zone.

To disassociate a VPC to a hosted zone, send a C<POST> request to the
C<2013-04-01/hostedzone/I<hosted zone ID>/disassociatevpc> resource.
The request body must include an XML document with a
C<DisassociateVPCFromHostedZoneRequest> element. The response returns
the C<DisassociateVPCFromHostedZoneResponse> element that contains
C<ChangeInfo> for you to track the progress of the
C<DisassociateVPCFromHostedZoneRequest> you made. See C<GetChange>
operation for how to track the progress of your change.











=head2 GetChange(Id => Str)

Each argument is described in detail in: L<Paws::Route53::GetChange>

Returns: a L<Paws::Route53::GetChangeResponse> instance

  

This action returns the current status of a change batch request. The
status is one of the following values:

- C<PENDING> indicates that the changes in this request have not
replicated to all Route 53 DNS servers. This is the initial status of
all change batch requests.

- C<INSYNC> indicates that the changes have replicated to all Amazon
Route 53 DNS servers.











=head2 GetCheckerIpRanges( => )

Each argument is described in detail in: L<Paws::Route53::GetCheckerIpRanges>

Returns: a L<Paws::Route53::GetCheckerIpRangesResponse> instance

  

To retrieve a list of the IP ranges used by Amazon Route 53 health
checkers to check the health of your resources, send a C<GET> request
to the C<2013-04-01/checkeripranges> resource. You can use these IP
addresses to configure router and firewall rules to allow health
checkers to check the health of your resources.











=head2 GetGeoLocation([ContinentCode => Str, CountryCode => Str, SubdivisionCode => Str])

Each argument is described in detail in: L<Paws::Route53::GetGeoLocation>

Returns: a L<Paws::Route53::GetGeoLocationResponse> instance

  

To retrieve a single geo location, send a C<GET> request to the
C<2013-04-01/geolocation> resource with one of these options:
continentcode | countrycode | countrycode and subdivisioncode.











=head2 GetHealthCheck(HealthCheckId => Str)

Each argument is described in detail in: L<Paws::Route53::GetHealthCheck>

Returns: a L<Paws::Route53::GetHealthCheckResponse> instance

  

To retrieve the health check, send a C<GET> request to the
C<2013-04-01/healthcheck/I<health check ID>> resource.











=head2 GetHealthCheckCount( => )

Each argument is described in detail in: L<Paws::Route53::GetHealthCheckCount>

Returns: a L<Paws::Route53::GetHealthCheckCountResponse> instance

  

To retrieve a count of all your health checks, send a C<GET> request to
the C<2013-04-01/healthcheckcount> resource.











=head2 GetHealthCheckLastFailureReason(HealthCheckId => Str)

Each argument is described in detail in: L<Paws::Route53::GetHealthCheckLastFailureReason>

Returns: a L<Paws::Route53::GetHealthCheckLastFailureReasonResponse> instance

  

If you want to learn why a health check is currently failing or why it
failed most recently (if at all), you can get the failure reason for
the most recent failure. Send a C<GET> request to the
C<2013-04-01/healthcheck/I<health check ID>/lastfailurereason>
resource.











=head2 GetHealthCheckStatus(HealthCheckId => Str)

Each argument is described in detail in: L<Paws::Route53::GetHealthCheckStatus>

Returns: a L<Paws::Route53::GetHealthCheckStatusResponse> instance

  

To retrieve the health check status, send a C<GET> request to the
C<2013-04-01/healthcheck/I<health check ID>/status> resource. You can
use this call to get a health check's current status.











=head2 GetHostedZone(Id => Str)

Each argument is described in detail in: L<Paws::Route53::GetHostedZone>

Returns: a L<Paws::Route53::GetHostedZoneResponse> instance

  

To retrieve the delegation set for a hosted zone, send a C<GET> request
to the C<2013-04-01/hostedzone/I<hosted zone ID>> resource. The
delegation set is the four Route 53 name servers that were assigned to
the hosted zone when you created it.











=head2 GetHostedZoneCount( => )

Each argument is described in detail in: L<Paws::Route53::GetHostedZoneCount>

Returns: a L<Paws::Route53::GetHostedZoneCountResponse> instance

  

To retrieve a count of all your hosted zones, send a C<GET> request to
the C<2013-04-01/hostedzonecount> resource.











=head2 GetReusableDelegationSet(Id => Str)

Each argument is described in detail in: L<Paws::Route53::GetReusableDelegationSet>

Returns: a L<Paws::Route53::GetReusableDelegationSetResponse> instance

  

To retrieve the reusable delegation set, send a C<GET> request to the
C<2013-04-01/delegationset/I<delegation set ID>> resource.











=head2 ListGeoLocations([MaxItems => Str, StartContinentCode => Str, StartCountryCode => Str, StartSubdivisionCode => Str])

Each argument is described in detail in: L<Paws::Route53::ListGeoLocations>

Returns: a L<Paws::Route53::ListGeoLocationsResponse> instance

  

To retrieve a list of supported geo locations, send a C<GET> request to
the C<2013-04-01/geolocations> resource. The response to this request
includes a C<GeoLocationDetailsList> element with zero, one, or
multiple C<GeoLocationDetails> child elements. The list is sorted by
country code, and then subdivision code, followed by continents at the
end of the list.

By default, the list of geo locations is displayed on a single page.
You can control the length of the page that is displayed by using the
C<MaxItems> parameter. If the list is truncated, C<IsTruncated> will be
set to I<true> and a combination of C<NextContinentCode,
NextCountryCode, NextSubdivisionCode> will be populated. You can pass
these as parameters to C<StartContinentCode, StartCountryCode,
StartSubdivisionCode> to control the geo location that the list begins
with.











=head2 ListHealthChecks([Marker => Str, MaxItems => Str])

Each argument is described in detail in: L<Paws::Route53::ListHealthChecks>

Returns: a L<Paws::Route53::ListHealthChecksResponse> instance

  

To retrieve a list of your health checks, send a C<GET> request to the
C<2013-04-01/healthcheck> resource. The response to this request
includes a C<HealthChecks> element with zero, one, or multiple
C<HealthCheck> child elements. By default, the list of health checks is
displayed on a single page. You can control the length of the page that
is displayed by using the C<MaxItems> parameter. You can use the
C<Marker> parameter to control the health check that the list begins
with.

Amazon Route 53 returns a maximum of 100 items. If you set MaxItems to
a value greater than 100, Amazon Route 53 returns only the first 100.











=head2 ListHostedZones([DelegationSetId => Str, Marker => Str, MaxItems => Str])

Each argument is described in detail in: L<Paws::Route53::ListHostedZones>

Returns: a L<Paws::Route53::ListHostedZonesResponse> instance

  

To retrieve a list of your hosted zones, send a C<GET> request to the
C<2013-04-01/hostedzone> resource. The response to this request
includes a C<HostedZones> element with zero, one, or multiple
C<HostedZone> child elements. By default, the list of hosted zones is
displayed on a single page. You can control the length of the page that
is displayed by using the C<MaxItems> parameter. You can use the
C<Marker> parameter to control the hosted zone that the list begins
with.

Amazon Route 53 returns a maximum of 100 items. If you set MaxItems to
a value greater than 100, Amazon Route 53 returns only the first 100.











=head2 ListHostedZonesByName([DNSName => Str, HostedZoneId => Str, MaxItems => Str])

Each argument is described in detail in: L<Paws::Route53::ListHostedZonesByName>

Returns: a L<Paws::Route53::ListHostedZonesByNameResponse> instance

  

To retrieve a list of your hosted zones in lexicographic order, send a
C<GET> request to the C<2013-04-01/hostedzonesbyname> resource. The
response to this request includes a C<HostedZones> element with zero or
more C<HostedZone> child elements lexicographically ordered by DNS
name. By default, the list of hosted zones is displayed on a single
page. You can control the length of the page that is displayed by using
the C<MaxItems> parameter. You can use the C<DNSName> and
C<HostedZoneId> parameters to control the hosted zone that the list
begins with.

Amazon Route 53 returns a maximum of 100 items. If you set MaxItems to
a value greater than 100, Amazon Route 53 returns only the first 100.











=head2 ListResourceRecordSets(HostedZoneId => Str, [MaxItems => Str, StartRecordIdentifier => Str, StartRecordName => Str, StartRecordType => Str])

Each argument is described in detail in: L<Paws::Route53::ListResourceRecordSets>

Returns: a L<Paws::Route53::ListResourceRecordSetsResponse> instance

  

Imagine all the resource record sets in a zone listed out in front of
you. Imagine them sorted lexicographically first by DNS name (with the
labels reversed, like "com.amazon.www" for example), and secondarily,
lexicographically by record type. This operation retrieves at most
MaxItems resource record sets from this list, in order, starting at a
position specified by the Name and Type arguments:

=over

=item * If both Name and Type are omitted, this means start the results
at the first RRSET in the HostedZone.

=item * If Name is specified but Type is omitted, this means start the
results at the first RRSET in the list whose name is greater than or
equal to Name.

=item * If both Name and Type are specified, this means start the
results at the first RRSET in the list whose name is greater than or
equal to Name and whose type is greater than or equal to Type.

=item * It is an error to specify the Type but not the Name.

=back

Use ListResourceRecordSets to retrieve a single known record set by
specifying the record set's name and type, and setting MaxItems = 1

To retrieve all the records in a HostedZone, first pause any processes
making calls to ChangeResourceRecordSets. Initially call
ListResourceRecordSets without a Name and Type to get the first page of
record sets. For subsequent calls, set Name and Type to the NextName
and NextType values returned by the previous response.

In the presence of concurrent ChangeResourceRecordSets calls, there is
no consistency of results across calls to ListResourceRecordSets. The
only way to get a consistent multi-page snapshot of all RRSETs in a
zone is to stop making changes while pagination is in progress.

However, the results from ListResourceRecordSets are consistent within
a page. If MakeChange calls are taking place concurrently, the result
of each one will either be completely visible in your results or not at
all. You will not see partial changes, or changes that do not
ultimately succeed. (This follows from the fact that MakeChange is
atomic)

The results from ListResourceRecordSets are strongly consistent with
ChangeResourceRecordSets. To be precise, if a single process makes a
call to ChangeResourceRecordSets and receives a successful response,
the effects of that change will be visible in a subsequent call to
ListResourceRecordSets by that process.











=head2 ListReusableDelegationSets([Marker => Str, MaxItems => Str])

Each argument is described in detail in: L<Paws::Route53::ListReusableDelegationSets>

Returns: a L<Paws::Route53::ListReusableDelegationSetsResponse> instance

  

To retrieve a list of your reusable delegation sets, send a C<GET>
request to the C<2013-04-01/delegationset> resource. The response to
this request includes a C<DelegationSets> element with zero, one, or
multiple C<DelegationSet> child elements. By default, the list of
delegation sets is displayed on a single page. You can control the
length of the page that is displayed by using the C<MaxItems>
parameter. You can use the C<Marker> parameter to control the
delegation set that the list begins with.

Amazon Route 53 returns a maximum of 100 items. If you set MaxItems to
a value greater than 100, Amazon Route 53 returns only the first 100.











=head2 ListTagsForResource(ResourceId => Str, ResourceType => Str)

Each argument is described in detail in: L<Paws::Route53::ListTagsForResource>

Returns: a L<Paws::Route53::ListTagsForResourceResponse> instance

  


=head2 ListTagsForResources(ResourceType => Str)

Each argument is described in detail in: L<Paws::Route53::ListTagsForResources>

Returns: a L<Paws::Route53::ListTagsForResourcesResponse> instance

  


=head2 UpdateHealthCheck(HealthCheckId => Str, [FailureThreshold => Int, FullyQualifiedDomainName => Str, HealthCheckVersion => Int, IPAddress => Str, Port => Int, ResourcePath => Str, SearchString => Str])

Each argument is described in detail in: L<Paws::Route53::UpdateHealthCheck>

Returns: a L<Paws::Route53::UpdateHealthCheckResponse> instance

  

This action updates an existing health check.

To update a health check, send a C<POST> request to the
C<2013-04-01/healthcheck/I<health check ID>> resource. The request body
must include an XML document with an C<UpdateHealthCheckRequest>
element. The response returns an C<UpdateHealthCheckResponse> element,
which contains metadata about the health check.











=head2 UpdateHostedZoneComment(Id => Str, [Comment => Str])

Each argument is described in detail in: L<Paws::Route53::UpdateHostedZoneComment>

Returns: a L<Paws::Route53::UpdateHostedZoneCommentResponse> instance

  

To update the hosted zone comment, send a C<POST> request to the
C<2013-04-01/hostedzone/I<hosted zone ID>> resource. The request body
must include an XML document with a C<UpdateHostedZoneCommentRequest>
element. The response to this request includes the modified
C<HostedZone> element.

The comment can have a maximum length of 256 characters.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

