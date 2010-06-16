require 'test_helper'

class RulesEngineTest < ActiveSupport::TestCase

  include RulesEngine
    
  test "empty rules" do
    assert_nil apply(nil, nil)
  end
  
  test "empty rules 2" do
    assert_nil apply(nil, [])
  end
  
  test "apply if empty matchings, apply action" do
    rules = [
        rule(nil,[action(:propA,2)])
    ]
    
    res = apply(nil, rules)
    assert_equal 2, res[:propA]
  end
  
  test "apply many actions in same rule" do
    rules = [
        rule(nil,[action(:propA,2),action(:propB,'lorem')])
    ]
    
    res = apply(nil, rules)
    assert_equal 2, res[:propA]
    assert_equal 'lorem', res[:propB]
  end
  
  
  test "apply many actions along many rules" do
    rules = [
        rule(nil,[action(:propA,2)]),
        rule(nil,[action(:propB,'lorem')])
    ]
    
    res = apply(nil, rules)
    assert_equal 2, res[:propA]
    assert_equal 'lorem', res[:propB]
  end
  
  test "equal matching matches" do
    rules = [
        rule([matching(:prop, OP_EQUALS, 'lorem')], [action(:prop, 'ipsum')])
    ]
    
    ctx = { :prop => 'lorem' }
    res = apply(ctx, rules)
    assert_equal 'lorem', ctx[:prop]
    assert_equal 'ipsum', res[:prop]
  end
  
  test "equal matching not matches" do
    rules = [
        rule([matching(:prop, OP_EQUALS, 'lorem')], [action(:prop, 'ipsum')])
    ]
    
    ctx = { :prop => 'not lorem' }
    res = apply(ctx, rules)
    assert_equal 'not lorem', ctx[:prop]
    assert_nil res
  end
  
  test "not equal matching matches" do
    rules = [
        rule([matching(:prop, OP_NOT_EQUALS, 'lorem')], [action(:prop, 'ipsum')])
    ]
    
    ctx = { :prop => 'not lorem' }
    res = apply(ctx, rules)
    assert_equal 'not lorem', ctx[:prop]
    assert_equal 'ipsum', res[:prop]
  end
  
  test "not equal matching not matches" do
    rules = [
        rule([matching(:prop, OP_NOT_EQUALS, 'lorem')], [action(:prop, 'ipsum')])
    ]
    
    ctx = { :prop => 'lorem' }
    res = apply(ctx, rules)
    assert_equal 'lorem', ctx[:prop]
    assert_nil res
  end
  
  test "prefix matching matches" do
    rules = [
        rule([matching(:prop, OP_STARTS_WITH, 'lor')], [action(:prop, 'ipsum')])
    ]
    
    res = apply({:prop => 'lorem'}, rules)
    assert_equal 'ipsum', res[:prop]
  end
  
  test "prefix matching not matches" do
    rules = [
        rule([matching(:prop, OP_STARTS_WITH, 'lor')], [action(:prop, 'ipsum')])
    ]
    
    res = apply({:prop => 'not lorem'}, rules)
    assert_nil res
  end
  
  test "regex matching matches" do
    rules = [
        rule([matching(:prop, OP_REGEX, 'em$')], [action(:prop, 'ipsum')])
    ]
    
    res = apply({:prop => 'lorem'}, rules)
    assert_equal 'ipsum', res[:prop]
  end
  
  test "regex matching not matches" do
    rules = [
        rule([matching(:prop, OP_REGEX, 'other$')], [action(:prop, 'ipsum')])
    ]
    
    res = apply({:prop => 'not lorem'}, rules)
    assert_nil res
  end
  
  test "many matchings perform logical and" do
    rules = [
      rule([
        matching(:propA, OP_EQUALS, 'foo'), 
        matching(:propB, OP_STARTS_WITH, 'b')
      ],[
        action(:prop, 'a')
      ])
    ]
    
    assert_equal 'a', apply({:propA => 'foo', :propB => 'bar'}, rules)[:prop]
    assert_nil apply({:propA => 'foo', :propB => 'not bar'}, rules)
  end
  
  test "not match if property is not defined in context" do
    rules = [
      rule([
        matching(:propA, OP_EQUALS, 'foo')
      ],[
        action(:prop, 'a')
      ])
    ]
    
    assert_nil apply({:propB => 'foo'}, rules)
  end
  
  test "if context has many values for same property match if any" do
    rules = [
      rule([
        matching(:propA, OP_EQUALS, 'foo')
      ],[
        action(:prop, 'a')
      ])
    ]

    assert_not_nil apply({:propA => ['bar','foo']}, rules)
    assert_nil apply({:propA => ['bar','baz']}, rules)
  end
  
  test "rules execute in order" do
    rules = [
      rule([],[action(:propC, 'c')], false),
      rule([],[action(:propA, 'a')], true),
      rule([],[action(:propB, 'b')], false)
    ]
    
    res = apply({}, rules)
    
    assert res.has_key?(:propC)
    assert res.has_key?(:propA)
    assert !res.has_key?(:propB)
  end
  
  test "regex matching with group replacement" do
    rules = [
        rule([matching(:prop, OP_REGEX, 'sms://(.*)')], [action(:prop, 'mailto://${1}')])
    ]
    
    res = apply({:prop => 'sms://foo'}, rules)
    assert_equal 'mailto://foo', res[:prop]
  end
  
  test "regex matching with group replacement second group" do
    rules = [
        rule([matching(:prop, OP_REGEX, '(.*?)://(.*)')], [action(:prop, 'foobar://${2}')])
    ]
    
    res = apply({:prop => 'sms://foo'}, rules)
    assert_equal 'foobar://foo', res[:prop]
  end
  
  test "regex matching with property group replacement" do
    rules = [
        rule([
          matching('prop1', OP_REGEX, 'sms://(.*)'),
          matching('prop2', OP_REGEX, '(.*?)://(.*)')
        ], [action('prop', 'mailto://${prop1.1}.${prop2.2}')]),
    ]
    
    res = apply({'prop1' => 'sms://foo', 'prop2' => 'lala://lele'}, rules)
    assert_equal 'mailto://foo.lele', res['prop']
  end
  
  test "regex matching with group replacement no match" do
    rules = [
        rule([matching(:prop, OP_REGEX, 'sms://(.*)')], [action(:prop, 'mailto://${2}')])
    ]
    
    res = apply({:prop => 'sms://foo'}, rules)
    assert_equal 'mailto://', res[:prop]
  end
  
  [false, true].each do |stop|
    test "regex matching with group replacement and stop=#{stop} clickatell case" do
      rules = [
          rule([matching('body', OP_REGEX, '(\d+) - (.*)')], [
            action('from', 'sms://${1}'),
            action('body', '${2}')
          ], stop)
      ]
      
      res = apply({'body' => '1234321 - It works!'}, rules)
      assert_equal 'sms://1234321', res['from']
      assert_equal 'It works!', res['body']
    end
  end
  
  # TODO should be case insensitive ?
end
