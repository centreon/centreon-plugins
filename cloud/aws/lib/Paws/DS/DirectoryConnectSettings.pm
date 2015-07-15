package Paws::DS::DirectoryConnectSettings {
  use Moose;
  has CustomerDnsIps => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has CustomerUserName => (is => 'ro', isa => 'Str', required => 1);
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has VpcId => (is => 'ro', isa => 'Str', required => 1);
}
1;
