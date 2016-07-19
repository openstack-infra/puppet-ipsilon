# == Class: ipsilon::config
#
# This class is used to manage arbitrary ipsilon configurations.
#
# === Parameters
#
# [*ipsilon_config*]
#   (optional) Allow configuration of arbitrary ipsilon configurations.
#   The value is an hash of ipsilon_config resources. Example:
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#   In yaml format, Example:
#   ipsilon_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
#   NOTE: The configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
class ipsilon::config (
  $ipsilon_config = {},
) {

  validate_hash($ipsilon_config)

  create_resources('ipsilon_config', $ipsilon_config)
}