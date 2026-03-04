# ============================================================
#  Makefile – Inject .env keys into native configs
#
#  Workflow:
#    make inject-keys   → inject real keys + hide changes from git
#    make reset-keys    → restore placeholders + re-track files
#    make show-keys     → show current key in all 3 locations
# ============================================================

ENV_FILE := .env
PLACEHOLDER := YOUR_GOOGLE_MAPS_API_KEY

# Read GOOGLE_MAPS_API_KEY from .env (ignore lines starting with #)
MAPS_KEY := $(shell grep -E '^GOOGLE_MAPS_API_KEY=' $(ENV_FILE) | cut -d '=' -f2- | tr -d ' \r')

ANDROID_MANIFEST := android/app/src/main/AndroidManifest.xml
IOS_APPDELEGATE  := ios/Runner/AppDelegate.swift

NATIVE_FILES := $(ANDROID_MANIFEST) $(IOS_APPDELEGATE)

.PHONY: inject-keys inject-android inject-ios check-env reset-keys show-keys

## Default target
all: inject-keys

## Inject real API key into both platforms, then hide changes from git
inject-keys: check-env inject-android inject-ios
	@git update-index --skip-worktree $(NATIVE_FILES)
	@echo "✅  Keys injected & native files hidden from git status"

## Check .env exists and key is set
check-env:
	@test -f $(ENV_FILE) || (echo "❌  $(ENV_FILE) not found. Copy .env.example first." && exit 1)
	@test -n "$(MAPS_KEY)" || (echo "❌  GOOGLE_MAPS_API_KEY is empty in $(ENV_FILE)" && exit 1)
	@echo "🔑  Using GOOGLE_MAPS_API_KEY=$(MAPS_KEY)"

## Patch AndroidManifest.xml (dùng python3 vì value nằm trên dòng riêng)
inject-android:
	@python3 -c "\
import re, sys; \
f = open('$(ANDROID_MANIFEST)', 'r'); content = f.read(); f.close(); \
content = re.sub( \
    r'(android:name=\"com\.google\.android\.geo\.API_KEY\"\s+android:value=\")[^\"]*\"', \
    r'\g<1>$(MAPS_KEY)\"', content, flags=re.DOTALL); \
f = open('$(ANDROID_MANIFEST)', 'w'); f.write(content); f.close()"
	@echo "📱  Android: $(ANDROID_MANIFEST) updated"

## Patch AppDelegate.swift
inject-ios:
	@sed -i.bak \
		's|GMSServices\.provideAPIKey("[^"]*")|GMSServices.provideAPIKey("$(MAPS_KEY)")|g' \
		$(IOS_APPDELEGATE) && rm -f $(IOS_APPDELEGATE).bak
	@echo "🍎  iOS: $(IOS_APPDELEGATE) updated"

## Restore placeholder values và re-track files trong git
reset-keys:
	@git update-index --no-skip-worktree $(NATIVE_FILES)
	@sed -i.bak 's|GMSServices\.provideAPIKey("[^"]*")|GMSServices.provideAPIKey("$(PLACEHOLDER)")|g' \
		$(IOS_APPDELEGATE) && rm -f $(IOS_APPDELEGATE).bak
	@python3 -c "\
import re, sys; \
f = open('$(ANDROID_MANIFEST)', 'r'); content = f.read(); f.close(); \
content = re.sub( \
    r'(android:name=\"com\.google\.android\.geo\.API_KEY\"\s+android:value=\")[^\"]*\"', \
    r'\g<1>$(PLACEHOLDER)\"', content, flags=re.DOTALL); \
f = open('$(ANDROID_MANIFEST)', 'w'); f.write(content); f.close()"
	@echo "🔄  Keys reset to placeholder '$(PLACEHOLDER)' và files re-tracked"

## Commit placeholder baseline (chạy 1 lần duy nhất sau khi clone/setup repo)
setup:
	@$(MAKE) reset-keys
	@git add $(NATIVE_FILES) Makefile
	@git diff --cached --quiet $(NATIVE_FILES) || git commit -m "chore: use placeholder for native API keys"
	@echo "🏁  Baseline committed. Từ giờ chạy 'make inject-keys' để inject keys thật."

## Show current keys in all 3 locations
show-keys:
	@echo "--- .env ---"
	@grep 'GOOGLE_MAPS_API_KEY' $(ENV_FILE)
	@echo "--- AndroidManifest.xml ---"
	@grep -A1 'geo.API_KEY' $(ANDROID_MANIFEST)
	@echo "--- AppDelegate.swift ---"
	@grep 'provideAPIKey' $(IOS_APPDELEGATE)
	@echo "--- git skip-worktree status ---"
	@git ls-files -v $(NATIVE_FILES) | awk '{print $$1, $$2}' | sed 's/S/⏭  skip-worktree/; s/H/✅  tracked/; s/h/✅  tracked/'
