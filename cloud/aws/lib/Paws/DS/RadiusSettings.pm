package Paws::DS::RadiusSettings {
  use Moose;
  has AuthenticationProtocol => (is => 'ro', isa => 'Str');
  has DisplayLabel => (is => 'ro', isa => 'Str');
  has RadiusPort => (is => 'ro', isa => 'Int');
  has RadiusRetries => (is => 'ro', isa => 'Int');
  has RadiusServers => (is => 'ro', isa => 'ArrayRef[Str]');
  has RadiusTimeout => (is => 'ro', isa => 'Int');
  has SharedSecret => (is => 'ro', isa => 'Str');
  has UseSameUsername => (is => 'ro', isa => 'Bool');
}
1;
