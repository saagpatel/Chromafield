# fastlane setup — App Store Connect credentials

> Note: `fastlane/README.md` is auto-generated and rewritten on every `fastlane`
> run, so this durable setup note lives here instead.

The `upload` lane authenticates with the App Store Connect API using credentials
read from the environment — **no secrets are stored in source**.

## One-time setup

1. Copy the template and fill in real values:
   ```sh
   cp fastlane/.env.example fastlane/.env
   ```
2. Set in `fastlane/.env` (App Store Connect → Users and Access → Integrations → App Store Connect API):
   - `ASC_API_KEY_ID` — the key's ID (e.g. `XXXXXXXXXX`)
   - `ASC_API_ISSUER_ID` — the issuer UUID
3. Place the private key at `~/.appstoreconnect/private_keys/AuthKey_<ASC_API_KEY_ID>.p8`
   (or set `ASC_API_KEY_FILEPATH` to its absolute path).

`fastlane/.env` and `*.p8` are gitignored — never commit them.

## Run

```sh
bundle exec fastlane ios upload
```

Uploads App Store metadata + screenshots only (`skip_binary_upload: true`,
`submit_for_review: false`). The binary is archived/uploaded separately via
Xcode or Transporter.
