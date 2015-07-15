package Paws::Glacier::VaultNotificationConfig {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Str]');
  has SNSTopic => (is => 'ro', isa => 'Str');
}
1;
