package Paws::EFS::FileSystemSize {
  use Moose;
  has Timestamp => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Int', required => 1);
}
1;
