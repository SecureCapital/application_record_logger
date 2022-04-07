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
- On applicationRecordLog removed options "optional: false" on belongs_to. Destroyed records would then not be valid records, thus no destruction log would be produced
- Added validation of presence of record_id and record_type on ApplicationRecordLog
- Added setter of action on ApplicationRecordLog allowing setting action with symbols and strings matching the action rather than being the exact action.
- Improved Service accessors
- Refactored initialization on Service, LogService, and RollBackService
- Added ActionParser mixin
- Added test of Service
- Added test of LogService with create
- Added test of LogService with update
- Added test of LogService with destroy
- Removed reliance of database seeding before testing
- Removed inclusion of module on ApplicationRecord, and associated tests
- Removed set_logging_callbacks! on Invoice (test)
- Removed logging-tests on invoce as these are covered in LogService test
- Changed logging configuration for model User (test)
- Increased test coverage on module and ApplicationRecordLog
## [0.1.6] - 2022-04-07
- Ensured extra log_field_types represented (boolean time) represented in test case
- Syntaxtual improvements on application_record_logger.rb
