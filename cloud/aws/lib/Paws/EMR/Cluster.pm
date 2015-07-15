package Paws::EMR::Cluster {
  use Moose;
  has Applications => (is => 'ro', isa => 'ArrayRef[Paws::EMR::Application]');
  has AutoTerminate => (is => 'ro', isa => 'Bool');
  has Ec2InstanceAttributes => (is => 'ro', isa => 'Paws::EMR::Ec2InstanceAttributes');
  has Id => (is => 'ro', isa => 'Str');
  has LogUri => (is => 'ro', isa => 'Str');
  has MasterPublicDnsName => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has NormalizedInstanceHours => (is => 'ro', isa => 'Int');
  has RequestedAmiVersion => (is => 'ro', isa => 'Str');
  has RunningAmiVersion => (is => 'ro', isa => 'Str');
  has ServiceRole => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Paws::EMR::ClusterStatus');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EMR::Tag]');
  has TerminationProtected => (is => 'ro', isa => 'Bool');
  has VisibleToAllUsers => (is => 'ro', isa => 'Bool');
}
1;
