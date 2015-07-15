package Paws::Config::ConfigurationRecorder {
  use Moose;
  has name => (is => 'ro', isa => 'Str');
  has recordingGroup => (is => 'ro', isa => 'Paws::Config::RecordingGroup');
  has roleARN => (is => 'ro', isa => 'Str');
}
1;
