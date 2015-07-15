package Paws::WorkSpaces::DefaultWorkspaceCreationProperties {
  use Moose;
  has CustomSecurityGroupId => (is => 'ro', isa => 'Str');
  has DefaultOu => (is => 'ro', isa => 'Str');
  has EnableInternetAccess => (is => 'ro', isa => 'Bool');
  has EnableWorkDocs => (is => 'ro', isa => 'Bool');
  has UserEnabledAsLocalAdministrator => (is => 'ro', isa => 'Bool');
}
1;
