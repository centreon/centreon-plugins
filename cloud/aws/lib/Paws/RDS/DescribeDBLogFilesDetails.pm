package Paws::RDS::DescribeDBLogFilesDetails {
  use Moose;
  has LastWritten => (is => 'ro', isa => 'Int');
  has LogFileName => (is => 'ro', isa => 'Str');
  has Size => (is => 'ro', isa => 'Int');
}
1;
