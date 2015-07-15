package Paws::S3::VersioningConfiguration {
  use Moose;
  has MFADelete => (is => 'ro', isa => 'Str', xmlname => 'MfaDelete', request_name => 'MfaDelete', traits => ['Unwrapped','NameInRequest']);
  has Status => (is => 'ro', isa => 'Str');
}
1;
