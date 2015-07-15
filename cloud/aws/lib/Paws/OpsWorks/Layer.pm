package Paws::OpsWorks::Layer {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::OpsWorks::LayerAttributes');
  has AutoAssignElasticIps => (is => 'ro', isa => 'Bool');
  has AutoAssignPublicIps => (is => 'ro', isa => 'Bool');
  has CreatedAt => (is => 'ro', isa => 'Str');
  has CustomInstanceProfileArn => (is => 'ro', isa => 'Str');
  has CustomRecipes => (is => 'ro', isa => 'Paws::OpsWorks::Recipes');
  has CustomSecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has DefaultRecipes => (is => 'ro', isa => 'Paws::OpsWorks::Recipes');
  has DefaultSecurityGroupNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has EnableAutoHealing => (is => 'ro', isa => 'Bool');
  has InstallUpdatesOnBoot => (is => 'ro', isa => 'Bool');
  has LayerId => (is => 'ro', isa => 'Str');
  has LifecycleEventConfiguration => (is => 'ro', isa => 'Paws::OpsWorks::LifecycleEventConfiguration');
  has Name => (is => 'ro', isa => 'Str');
  has Packages => (is => 'ro', isa => 'ArrayRef[Str]');
  has Shortname => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
  has UseEbsOptimizedInstances => (is => 'ro', isa => 'Bool');
  has VolumeConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::VolumeConfiguration]');
}
1;
