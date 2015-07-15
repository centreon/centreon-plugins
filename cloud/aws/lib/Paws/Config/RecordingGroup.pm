package Paws::Config::RecordingGroup {
  use Moose;
  has allSupported => (is => 'ro', isa => 'Bool');
  has resourceTypes => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
