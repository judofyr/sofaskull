require 'stringio'
require 'rubygems'
begin
  require 'sofaskull'
rescue LoadError
  require File.expand_path(File.dirname(__FILE__)+'/../lib/sofaskull')
end

# Shortcuts...
IM = SofaSkull::IOMode
AS = SofaSkull::AddSub
RS = SofaSkull::RunSub
CS = SofaSkull::ConRunSub
WB = SofaSkull::WhileBlock
MC = SofaSkull::ModCell
PC = SofaSkull::PrintCell
RC = SofaSkull::ReadCell

module SofaSkullHelpers  
  def should_parse(string, *expected)
    s = @parser.parse(string)
    s.should_not == nil
    return unless s
    e = s.elements
    match_class(s, expected)
    yield e.length==1?e[0]:e if block_given?
    s
  end
  
  def match_class(s, expected)
    expected.each_with_index do |klass, index|
      case klass
      when Array
        s.elements[index].should === klass.shift
        match_class(s.elements[index].statements, klass)
      else
        s.elements[index].should === klass
      end
    end 
  end
end