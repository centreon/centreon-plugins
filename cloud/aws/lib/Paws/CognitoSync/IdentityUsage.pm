package Paws::CognitoSync::IdentityUsage {
  use Moose;
  has DataStorage => (is => 'ro', isa => 'Int');
  has DatasetCount => (is => 'ro', isa => 'Int');
  has IdentityId => (is => 'ro', isa => 'Str');
  has IdentityPoolId => (is => 'ro', isa => 'Str');
  has LastModifiedDate => (is => 'ro', isa => 'Str');
}
1;
