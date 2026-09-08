package fixed_date;

# Copyright 2026-Present Centreon
# Always use the same fixed date so licence expiration tests keep a stable output

use DateTime;

BEGIN {
   $now = 1785448800;
   *CORE::GLOBAL::time = sub { $now };
   *DateTime::now = sub { DateTime->from_epoch(epoch => $now) };
}

1
