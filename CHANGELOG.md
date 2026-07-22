## 0.0.3

* Refactored package architecture to standardize on pure Supabase (Managed Cloud and Custom/Self-Hosted Supabase VPS).
* Added `defaultSupabaseUrl` and `defaultSupabaseAnonKey` parameters to `DynamicBackendBridge.initialize`.
* Streamlined onboarding UI to support zero-config managed cloud setup and self-hosted Supabase servers.
* Removed legacy Firebase dependencies for lightweight footprint and 100% database engine consistency.

## 0.0.2

* Minor maintenance update.

## 0.0.1

* Initial release of `dynamic_backend_bridge` package.
* Added runtime backend selection and configuration cache service.
* Implemented generic Map-based Database repository with filter queries support.
* Included a standard, interactive onboarding/setup UI wizard.
