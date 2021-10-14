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
