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
  
  # TODO should be case insensitive ?
end