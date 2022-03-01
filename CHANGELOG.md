## [0.1.0] - 2021-09-10
- Created
## [0.1.1] - 2021-09-11
- Initial content added
- Created install migration
- Created contents to ApplicationRecordLogger to include in ApplicationRecord classes to register logging on the model
- Created ApplicationRecordLog to store logging records, defining the log and rollback methods
- Testing not yet begun
## [0.1.3] - 2021-10-14
- changed name owner to record on application_record_log
- moved the rollback and log methods out of application_record_log and to distinct services (processes)
- modified the configuration to allow each clas to hold its own configuration
- ensured callbacks not created by default
- current_user is not defined by default on including model but along explicit callback setting
- add tests for log creation, update and destruction as well as callback and configuration
- updated readme
## [0.1.5] - 2022-03-01
- On applicationRecordLog eemoved options "optional: false" on belongs_to. Destroyed records would then not be valid records, thus no destruction log would be produced
- Added validation of presence of record_id and record_type on ApplicationRecordLog
- Added setter of action on ApplicationRecordLog allowing setting action with symbols and strings matching the action rather than being the exact action.
