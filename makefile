SUPABASE_URL=https://gkjgwbwmucotqftbhgyn.supabase.co
SUPABASE_ANON_KEY=sb_publishable_yKElKni4v28LWb3KiW-mrg_efIyVuU0

DEFINES=--dart-define=SUPABASE_URL=$(SUPABASE_URL) --dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY)

dev:
	flutter run $(DEFINES) -t lib/main_development.dart

staging:
	flutter run $(DEFINES) -t lib/main_staging.dart --flavor staging

prod:
	flutter run $(DEFINES) -t lib/main_production.dart --flavor production

build-prod:
	flutter build apk $(DEFINES) -t lib/main_production.dart --flavor production
