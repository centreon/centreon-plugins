package Paws::DeviceFarm::Device {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has carrier => (is => 'ro', isa => 'Str');
  has cpu => (is => 'ro', isa => 'Paws::DeviceFarm::CPU');
  has formFactor => (is => 'ro', isa => 'Str');
  has heapSize => (is => 'ro', isa => 'Int');
  has image => (is => 'ro', isa => 'Str');
  has manufacturer => (is => 'ro', isa => 'Str');
  has memory => (is => 'ro', isa => 'Int');
  has model => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has os => (is => 'ro', isa => 'Str');
  has platform => (is => 'ro', isa => 'Str');
  has radio => (is => 'ro', isa => 'Str');
  has resolution => (is => 'ro', isa => 'Paws::DeviceFarm::Resolution');
}
1;
