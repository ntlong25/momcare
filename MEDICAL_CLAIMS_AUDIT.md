# Medical Claims Audit

Phase: 1  
Status: Initial audit for later rewrite and sourcing phases

## Nutrition
- Sample nutrition guides state benefits such as preventing neural tube defects, preventing anemia, regulating blood pressure, and supporting milk production.
- Recipes include nutrition benefits that should be kept educational, not personalized treatment advice.
- Later phase recommendation: attach source metadata to each guide and soften direct prevention claims when no source is displayed in the UI.

## Tracking
- Pregnancy week content estimates baby size, weight, length, development, mother changes, and weekly tips.
- Weight gain chart and BMI advice may be interpreted as health guidance.
- Later phase recommendation: add disclaimer that week data and weight ranges are estimates and users should follow their clinician's advice.

## Fertility
- Cycle, ovulation, next period, and fertile window predictions are estimates based on recorded cycle data.
- Fertile window copy should avoid implying certainty or guaranteed conception chances.
- Later phase recommendation: add source metadata and a clear "estimated prediction" label before HealthKit/Google Fit sync and on prediction cards.

## Health Diary
- Blood pressure validation and category labels include clinical terms such as elevated, high, and hypertensive crisis.
- These labels may be interpreted as diagnosis or triage.
- Later phase recommendation: localize labels, add red-flag guidance, and advise users to contact a healthcare professional for abnormal values.

## Removed From V1 Scope
- Gender selection advice has been removed from user-accessible flows and the dedicated screen has been deleted.
