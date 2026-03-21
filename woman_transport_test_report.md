# Woman Transport Test Report - Feb 7, 2026

## Test Setup
- Task system test: land claim Test with 20 wood + 20 grain, 4 ovens, 2 women in clan
- Duration: ~50 seconds
- Log: logs/woman_transport_test_20260207_114549.log

## Findings

### Working
- Women CASI and BOOT pull oven jobs (10 tasks each)
- Women enter work_at_building state (priority 9.0)
- OccupyTask added to production jobs
- Clan assignment: women in Test clan, receive jobs from Test ovens

### Possible Issues
- FLEE behavior: women steering FLEE from (200,0) - may interrupt jobs
- Repeated job pulls every ~3s - jobs may be failing and retrying
- Logger SUMMARY shows "0 women" despite CASI and BOOT existing

### Documentation (woman_production.md)
- Women use Task/Job system: yes
- Buildings generate jobs: yes
- Production job flow: yes
- Bread delivery: needs verification
