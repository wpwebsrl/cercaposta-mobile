# CercaPosta storage units — iOS and Android

Permanent product contract, adopted on 7 October 2026. This public client reference
summarizes the authoritative `docs/unita-spazio.md` in the server repository. Any change
to this contract must update both references together.

## Decimal units

`1 GB = 1,000,000,000 bytes = 10^9 bytes` on every platform. A 50 GB plan and a 50 GB
administrator override both mean exactly 50,000,000,000 bytes.

| Symbol | Bytes |
|---|---:|
| B | 1 |
| kB | 1,000 |
| MB | 1,000,000 |
| GB | 1,000,000,000 |
| TB | 1,000,000,000,000 |
| KiB | 1,024 |
| MiB | 1,048,576 |
| GiB | 1,073,741,824 |

Use decimal units for product storage, plans, overrides and usage. Binary units are
allowed for explicitly technical values and must use KiB/MiB/GiB. Never divide by
1024^3 and label the result GB. Symbols do not change with the UI language.

## API and presentation

API `*_bytes` fields contain integer bytes. `archive_gb` contains decimal GB.
Convert with `gb = bytes / 1000000000` and `bytes = gb * 1000000000`. Inputs must
represent whole bytes exactly; at most nine fractional GB digits are allowed by this
contract, and an individual form may accept fewer. Do not invent platform-specific
rounding for conversion. Keep original integer bytes for comparisons and unedited values.

The server owns quota enforcement, availability and percentages. A zero quota means
unlimited only where the API defines it; zero usage means no usage. A null organization
override inherits the plan. Nominal plan storage and effective quota may differ: render
`subscription.archive_gb` for plan inclusions and the server's `archive_bytes`/`quota_bytes`
for effective limits. Do not replace one with the other.

For GB presentation show up to three fractional digits, remove trailing zeros and use
the user's number format: `50 GB`, `1,5 GB` or `1.5 GB`. Presentation rounding must never
change stored values or enforcement. Use B/kB/MB when needed for small values.
For positive sizes, presentation ties round half-up: 1,502,500 bytes displays as
`1.503 MB`, not `1.502 MB`.
Automatic decimal formatters advance by 1000; explicit binary formatters advance by
1024 and display binary symbols.

iOS and Android use the same Dart helpers in `lib/shared/storage_units.dart` and
`lib/shared/format.dart`. Native Swift,
Kotlin or platform formatters must obey the same contract if introduced. Keep unit
conversion in shared helpers, including search filters, rather than per-screen formulas.

## Verification and current implementation

Check 1 GB = 1,000,000,000 bytes; 50 GB = 50,000,000,000 bytes; 1.5 GB = 1,500,000,000
bytes; 0.001 GB = 1,000,000 bytes. In contrast, 53,687,091,200 bytes is 53.6870912 GB
or 50 GiB. Verify round-trips, 1000/1024 boundaries, IT/EN formatting, unlimited values,
plan versus override, and identical iOS/Android results.

On 7 October 2026, the shared formatter and search filter unit factors were aligned
to decimal units. Filters use exact decimal arithmetic and round fractional search
thresholds once to integer bytes (half-up); quota inputs must instead represent whole
bytes exactly. Filter forms serialize integer-byte thresholds and preserve original
bytes when prefilled, using B when a larger unit cannot represent the value exactly.
New source changes require a rebuilt app; previously generated binaries are unchanged.

The server accepts decimal kB/MB/GB/TB and explicit binary KiB/MiB/GiB/TiB, ignoring
symbol case. Only deprecated one-letter query aliases k/m/g retain their historical
binary meaning. The server migration normalizes old saved-search inputs to integer
bytes while preserving their original thresholds. Do not rescale server quotas in
the mobile app. Technical buffer limits remain unchanged; Docker/PostgreSQL syntax
is a separate infrastructure convention, not a product GB input.
