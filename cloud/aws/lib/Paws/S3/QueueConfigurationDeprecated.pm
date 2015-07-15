package Paws::S3::QueueConfigurationDeprecated {
  use Moose;
  has Event => (is => 'ro', isa => 'Str');
  has Events => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'Event', request_name => 'Event', traits => ['Unwrapped','NameInRequest']);
  has Id => (is => 'ro', isa => 'Str');
  has Queue => (is => 'ro', isa => 'Str');
}
1;
