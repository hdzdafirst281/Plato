# Workout Feature Business Rules

## Domain Logic
- **Muscle Recovery Model**: 
  - Recovery percentage calculations must account for Primary Muscle impact (ratio 1.0) and Secondary Muscle impact (ratio 1/3 or 0.33).
  - Main tracked muscle groups: Chest, Back, Legs, Arms, Shoulders, Abs.
- **Active Session Limit**:
  - Maximum unique exercises allowed per routine/session: 50.