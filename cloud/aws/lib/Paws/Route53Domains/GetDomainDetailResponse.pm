
package Paws::Route53Domains::GetDomainDetailResponse {
  use Moose;
  has AbuseContactEmail => (is => 'ro', isa => 'Str');
  has AbuseContactPhone => (is => 'ro', isa => 'Str');
  has AdminContact => (is => 'ro', isa => 'Paws::Route53Domains::ContactDetail', required => 1);
  has AdminPrivacy => (is => 'ro', isa => 'Bool');
  has AutoRenew => (is => 'ro', isa => 'Bool');
  has CreationDate => (is => 'ro', isa => 'Str');
  has DnsSec => (is => 'ro', isa => 'Str');
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has ExpirationDate => (is => 'ro', isa => 'Str');
  has Nameservers => (is => 'ro', isa => 'ArrayRef[Paws::Route53Domains::Nameserver]', required => 1);
  has RegistrantContact => (is => 'ro', isa => 'Paws::Route53Domains::ContactDetail', required => 1);
  has RegistrantPrivacy => (is => 'ro', isa => 'Bool');
  has RegistrarName => (is => 'ro', isa => 'Str');
  has RegistrarUrl => (is => 'ro', isa => 'Str');
  has RegistryDomainId => (is => 'ro', isa => 'Str');
  has Reseller => (is => 'ro', isa => 'Str');
  has StatusList => (is => 'ro', isa => 'ArrayRef[Str]');
  has TechContact => (is => 'ro', isa => 'Paws::Route53Domains::ContactDetail', required => 1);
  has TechPrivacy => (is => 'ro', isa => 'Bool');
  has UpdatedDate => (is => 'ro', isa => 'Str');
  has WhoIsServer => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains::GetDomainDetailResponse

=head1 ATTRIBUTES

=head2 AbuseContactEmail => Str

  

Email address to contact to report incorrect contact information for a
domain, to report that the domain is being used to send spam, to report
that someone is cybersquatting on a domain name, or report some other
type of abuse.

Type: String









=head2 AbuseContactPhone => Str

  

Phone number for reporting abuse.

Type: String









=head2 B<REQUIRED> AdminContact => Paws::Route53Domains::ContactDetail

  

Provides details about the domain administrative contact.

Type: Complex

Children: C<FirstName>, C<MiddleName>, C<LastName>, C<ContactType>,
C<OrganizationName>, C<AddressLine1>, C<AddressLine2>, C<City>,
C<State>, C<CountryCode>, C<ZipCode>, C<PhoneNumber>, C<Email>, C<Fax>,
C<ExtraParams>









=head2 AdminPrivacy => Bool

  

Specifies whether contact information for the admin contact is
concealed from WHOIS queries. If the value is C<true>, WHOIS ("who is")
queries will return contact information for our registrar partner,
Gandi, instead of the contact information that you enter.

Type: Boolean









=head2 AutoRenew => Bool

  

Specifies whether the domain registration is set to renew
automatically.

Type: Boolean









=head2 CreationDate => Str

  

The date when the domain was created as found in the response to a
WHOIS query. The date format is Unix time.









=head2 DnsSec => Str

  

Reserved for future use.









=head2 B<REQUIRED> DomainName => Str

  

The name of a domain.

Type: String









=head2 ExpirationDate => Str

  

The date when the registration for the domain is set to expire. The
date format is Unix time.









=head2 B<REQUIRED> Nameservers => ArrayRef[Paws::Route53Domains::Nameserver]

  

The name of the domain.

Type: String









=head2 B<REQUIRED> RegistrantContact => Paws::Route53Domains::ContactDetail

  

Provides details about the domain registrant.

Type: Complex

Children: C<FirstName>, C<MiddleName>, C<LastName>, C<ContactType>,
C<OrganizationName>, C<AddressLine1>, C<AddressLine2>, C<City>,
C<State>, C<CountryCode>, C<ZipCode>, C<PhoneNumber>, C<Email>, C<Fax>,
C<ExtraParams>









=head2 RegistrantPrivacy => Bool

  

Specifies whether contact information for the registrant contact is
concealed from WHOIS queries. If the value is C<true>, WHOIS ("who is")
queries will return contact information for our registrar partner,
Gandi, instead of the contact information that you enter.

Type: Boolean









=head2 RegistrarName => Str

  

Name of the registrar of the domain as identified in the registry.
Amazon Route 53 domains are registered by registrar Gandi. The value is
C<"GANDI SAS">.

Type: String









=head2 RegistrarUrl => Str

  

Web address of the registrar.

Type: String









=head2 RegistryDomainId => Str

  

Reserved for future use.









=head2 Reseller => Str

  

Reseller of the domain. Domains registered or transferred using Amazon
Route 53 domains will have C<"Amazon"> as the reseller.

Type: String









=head2 StatusList => ArrayRef[Str]

  

An array of domain name status codes, also known as Extensible
Provisioning Protocol (EPP) status codes.

ICANN, the organization that maintains a central database of domain
names, has developed a set of domain name status codes that tell you
the status of a variety of operations on a domain name, for example,
registering a domain name, transferring a domain name to another
registrar, renewing the registration for a domain name, and so on. All
registrars use this same set of status codes.

For a current list of domain name status codes and an explanation of
what each code means, go to the ICANN website and search for C<epp
status codes>. (Search on the ICANN website; web searches sometimes
return an old version of the document.)

Type: Array of String









=head2 B<REQUIRED> TechContact => Paws::Route53Domains::ContactDetail

  

Provides details about the domain technical contact.

Type: Complex

Children: C<FirstName>, C<MiddleName>, C<LastName>, C<ContactType>,
C<OrganizationName>, C<AddressLine1>, C<AddressLine2>, C<City>,
C<State>, C<CountryCode>, C<ZipCode>, C<PhoneNumber>, C<Email>, C<Fax>,
C<ExtraParams>









=head2 TechPrivacy => Bool

  

Specifies whether contact information for the tech contact is concealed
from WHOIS queries. If the value is C<true>, WHOIS ("who is") queries
will return contact information for our registrar partner, Gandi,
instead of the contact information that you enter.

Type: Boolean









=head2 UpdatedDate => Str

  

The last updated date of the domain as found in the response to a WHOIS
query. The date format is Unix time.









=head2 WhoIsServer => Str

  

The fully qualified name of the WHOIS server that can answer the WHOIS
query for the domain.

Type: String











=cut

1;