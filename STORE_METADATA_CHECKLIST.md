# MomCare+ Store Metadata Checklist

Use this checklist to keep Google Play and App Store metadata aligned with the actual V1 app.

## V1 Feature Claims Allowed
- [ ] Offline-first pregnancy tracking.
- [ ] Bundled offline pregnancy content covering weeks 0-42.
- [ ] Bundled offline nutrition guidance by pregnancy stage/week range.
- [ ] Local health diary for weight, blood pressure, mood, symptoms, and notes.
- [ ] Local menstrual cycle tracking and fertility estimates.
- [ ] Nutrition guidance and recipes for pregnancy/postpartum stages.
- [ ] Appointment storage and local reminders.
- [ ] Opt-in health habit checklist and local reminders.
- [ ] Emergency warning signs and medical disclaimer.
- [ ] In-app Privacy Policy, Medical Disclaimer, and References.
- [ ] Delete all local data inside the app.

## Claims to Avoid in V1
- [ ] Do not claim account login.
- [ ] Do not claim Supabase/cloud sync or backup.
- [ ] Do not claim analytics personalization.
- [ ] Do not claim ads or ad personalization.
- [ ] Do not claim AI advice, chatbot, expert chat, or doctor consultation.
- [ ] Do not claim diagnosis, treatment, medication recommendation, or emergency response.
- [ ] Do not claim wearable integration.
- [ ] Do not claim medication reminders unless actually added and tested.

## Google Play Data Safety
- [ ] Health and fitness data: disclosed if collected/stored by the app.
- [ ] Data sharing: mark no sharing with third parties for V1.
- [ ] Data transfer to server: mark no server transfer/cloud sync for V1.
- [ ] Data encryption in transit: not applicable for V1 local-only health data unless external links/network calls are described separately.
- [ ] User deletion: disclose in-app delete-all-data flow.
- [ ] Purpose: app functionality only.
- [ ] Ads: no.
- [ ] Analytics: no.

## Google Play Health Apps Declaration
- [ ] App category: health/pregnancy support.
- [ ] Clearly state app is informational and tracking-only.
- [ ] State app does not diagnose, treat, monitor emergencies, or replace medical professionals.
- [ ] State Health Connect use is limited to reading menstrual cycle data after user permission.
- [ ] Provide public Privacy Policy URL before submission.
- [ ] Provide contact/support email before submission.

## App Store Privacy Nutrition Label
- [ ] Health and Fitness data: disclose if entered by the user or read via HealthKit.
- [ ] Data linked to user: no account identity in V1 unless store account metadata requires otherwise.
- [ ] Data used to track user: no.
- [ ] Third-party advertising: no.
- [ ] Analytics: no.
- [ ] Data not collected from device to server in V1: reflect local-only storage accurately.
- [ ] User deletion: mention in-app delete-all-data in review notes/support copy.

## Store Listing Copy
- [ ] Language: Vietnamese only for V1 listing.
- [ ] Target region: Vietnam.
- [ ] Include medical disclaimer in long description.
- [ ] Mention offline-first/local storage clearly.
- [ ] Mention no cloud backup in V1 so users understand device-change risk.
- [ ] Mention reminders are optional and controlled by the user.
- [ ] Avoid unsupported screenshots showing login, cloud sync, AI, wearable sync, or expert chat.
- [ ] Screenshots include Privacy/Disclaimer/References or emergency guidance if store review needs health context.

## Before Submit
- [ ] Replace placeholder Privacy Policy URL in app constants with public URL.
- [ ] Replace placeholder Medical Disclaimer URL in app constants with public URL if published separately.
- [ ] Verify public URLs match store metadata URLs.
- [ ] Verify support email and developer name are final.
- [ ] Run `flutter test`.
- [ ] Run Android release or debug build.
- [ ] Run iOS archive/build on macOS before App Store submission.
