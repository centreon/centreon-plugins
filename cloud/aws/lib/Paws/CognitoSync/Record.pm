package Paws::CognitoSync::Record {
  use Moose;
  has DeviceLastModifiedDate => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has LastModifiedBy => (is => 'ro', isa => 'Str');
  has LastModifiedDate => (is => 'ro', isa => 'Str');
  has SyncCount => (is => 'ro', isa => 'Int');
  has Value => (is => 'ro', isa => 'Str');
}
1;
