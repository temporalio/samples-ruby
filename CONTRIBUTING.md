# Contributing

## Creating a sample

When creating a sample, do the following:

* Create a dir for the entire sample to live in, using underscores as word separators
* Add code to sample dir that:
  * Separates workers from starters
  * Separates main/primary code from testable, modular code (latter should be in module named after the sample dir)
* If needed, add tests in `test/<sample-dir>/<subject>_test.rb`
* Add a `README.md` to sample dir that:
  * Has high-level overview of what the sample shows
  * Links to original `../README.md` for prerequisites
  * Explains any additional setup steps
  * Explains what to run and when/how to see desired result
  * Adds anything else necessary to understand the sample
* Add the sample dir to the root `README.md` bulleted list (keep list in alphabetical order)
* Add any extra dependencies the sample requires to the root `Gemfile` as a group named after the sample (keep groups in
  alphabetical order)
* Add any extra tasks the sample requires to the root `Rakefile` under a namespace named after the sample (keep
  namespaces in alphabetical order)