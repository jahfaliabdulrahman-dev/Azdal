/// Set once in main() BEFORE the anonymous sign-in call:
/// true when no Supabase session existed at process start,
/// i.e. the true first launch on this install (DEC-017 session
/// persistence makes this equivalent to "onboarding never seen").
bool azdalFirstLaunch = false;
