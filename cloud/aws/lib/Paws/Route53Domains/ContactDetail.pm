package Paws::Route53Domains::ContactDetail {
  use Moose;
  has AddressLine1 => (is => 'ro', isa => 'Str');
  has AddressLine2 => (is => 'ro', isa => 'Str');
  has City => (is => 'ro', isa => 'Str');
  has ContactType => (is => 'ro', isa => 'Str');
  has CountryCode => (is => 'ro', isa => 'Str');
  has Email => (is => 'ro', isa => 'Str');
  has ExtraParams => (is => 'ro', isa => 'ArrayRef[Paws::Route53Domains::ExtraParam]');
  has Fax => (is => 'ro', isa => 'Str');
  has FirstName => (is => 'ro', isa => 'Str');
  has LastName => (is => 'ro', isa => 'Str');
  has OrganizationName => (is => 'ro', isa => 'Str');
  has PhoneNumber => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str');
  has ZipCode => (is => 'ro', isa => 'Str');
}
1;
