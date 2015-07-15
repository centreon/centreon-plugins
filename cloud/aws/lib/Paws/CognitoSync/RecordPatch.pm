package Paws::CognitoSync::RecordPatch {
  use Moose;
  has DeviceLastModifiedDate => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str', required => 1);
  has Op => (is => 'ro', isa => 'Str', required => 1);
  has SyncCount => (is => 'ro', isa => 'Int', required => 1);
  has Value => (is => 'ro', isa => 'Str');
}
1;
