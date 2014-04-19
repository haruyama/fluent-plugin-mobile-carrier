require 'helper'

# MobileCarrierOutput test
class Fluent::MobileCarrierOutputTest < Test::Unit::TestCase
  # through & merge
  CONFIG1 = %(
type mobile_carrier
remove_prefix test
add_prefix merged
config_yaml test/data/config1.yaml
key_name ip_address
  )

  CONFIG2 = %(
type mobile_carrier
remove_prefix test
add_prefix merged
config_yaml test/data/config1.yaml
key_name ip
unknown_carrier unknown
out_key_mobile_carrier mc
  )

  CONFIG_ERROR1 = %(
type mobile_carrier
remove_prefix test
add_prefix merged
key_name ip_address
  )

  CONFIG_ERROR2 = %(
type mobile_carrier
remove_prefix test
add_prefix merged
key_name ip_address
config_yaml test/data/not_found.yaml
  )

  CONFIG_ERROR3 = %(
type mobile_carrier
remove_prefix test
add_prefix merged
key_name ip_address
config_yaml test/data/wrong.yaml
  )

  def create_driver(conf = CONFIG1, tag = 'test')
    Fluent::Test::OutputTestDriver.new(Fluent::MobileCarrierOutput, tag).configure(conf)
  end

  def test_configure
    # through & merge
    d = create_driver CONFIG1
    assert_equal 'ip_address', d.instance.key_name
    assert_equal 'test',    d.instance.remove_prefix
    assert_equal 'merged',  d.instance.add_prefix

    assert_equal 'UNKNOWN',        d.instance.unknown_carrier
    assert_equal 'mobile_carrier', d.instance.out_key_mobile_carrier

    # filter & merge
    d = create_driver CONFIG2
    assert_equal 'ip',     d.instance.key_name
    assert_equal 'test',   d.instance.remove_prefix
    assert_equal 'merged', d.instance.add_prefix

    assert_equal 'unknown', d.instance.unknown_carrier
    assert_equal 'mc',      d.instance.out_key_mobile_carrier

    assert_raise_with_message(Fluent::ConfigError, "'config_yaml' parameter is required") do
      d = create_driver CONFIG_ERROR1
    end

    assert_raise(Errno::ENOENT) do
      d = create_driver CONFIG_ERROR2
    end

    assert_raise(RuntimeError) do
      d = create_driver CONFIG_ERROR3
    end
  end

  def test_tag_mangle
    p = create_driver(CONFIG1).instance
    assert_equal 'merged.data', p.tag_mangle('data')
    assert_equal 'merged.data', p.tag_mangle('test.data')
    assert_equal 'merged.test.data', p.tag_mangle('test.test.data')
    assert_equal 'merged', p.tag_mangle('test')
  end

  def test_emit1
    d = create_driver(CONFIG1, 'test.message')
    time = Time.parse('2012-07-20 16:40:30').to_i
    d.run do
      d.emit({ 'value' => 0 }, time)
      d.emit({ 'value' => 1, 'ip_address' => '192.168.0.5' }, time)
      d.emit({ 'value' => 2, 'ip_address' => '192.168.1.10' }, time)
      d.emit({ 'value' => 3, 'ip_address' => '192.168.2.100' }, time)
      d.emit({ 'value' => 4, 'ip_address' => '192.168.3.200' }, time)
      d.emit({ 'value' => 5, 'ip_address' => '192.168.4.1' }, time)
    end

    emits = d.emits
    assert_equal 6,                emits.size
    assert_equal 'merged.message', emits[0][0]
    assert_equal time,             emits[0][1]

    m = emits[0][2]
    assert_equal 0,         m['value']
    assert_equal 'UNKNOWN', m['mobile_carrier']

    m = emits[1][2]
    assert_equal 1,   m['value']
    assert_equal 'D', m['mobile_carrier']

    m = emits[2][2]
    assert_equal 2,   m['value']
    assert_equal 'E', m['mobile_carrier']

    m = emits[3][2]
    assert_equal 3,   m['value']
    assert_equal 'D', m['mobile_carrier']

    m = emits[4][2]
    assert_equal 4,   m['value']
    assert_equal 'E', m['mobile_carrier']

    m = emits[5][2]
    assert_equal 5,         m['value']
    assert_equal 'UNKNOWN', m['mobile_carrier']
  end
end
