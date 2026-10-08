# Storage units

Before changing storage conversions, quotas, formatters or size filters, read
[docs/storage-units.md](docs/storage-units.md). One GB equals 1,000,000,000 bytes on
every CercaPosta platform. Binary values must use KiB/MiB/GiB. iOS and Android share
the same Dart conversion helpers. API values remain integer bytes; the server owns
effective quotas and enforcement. Keep this reference aligned with the authoritative
`docs/unita-spazio.md` in the server repository when changing the contract.

Read [CLAUDE.md](CLAUDE.md) for the existing mobile development, public-repository
and release rules. Keep the storage contract's implementation and deployment status
accurate; updated source does not automatically update previously built clients.
