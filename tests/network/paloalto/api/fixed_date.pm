package fixed_date;

# Copyright 2026-Present Centreon
# Always use the same fixed date to test certificate validity

use DateTime;

BEGIN {
   $now = 1714521600;
   *CORE::GLOBAL::time = sub { $now };
   *DateTime::now = sub { DateTime->from_epoch(epoch => $now) };
}

1
