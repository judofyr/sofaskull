require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

describe SofaSkullParser do
  include SofaSkullHelpers
  
  before(:each) do
    @parser = SofaSkullParser.new
  end
  
  it "should accept a null program" do
    should_parse("")
  end
  
  it "should not accept spaces" do
    s = @parser.parse(" ")
    s.should == nil
  end
  
  it "should accept io-mode" do
    should_parse(":ASC:", IM) do |e|
      e.to_sym.should == :asc
    end
    
    should_parse(":NUM:", IM) do |e|
      e.to_sym.should == :num
    end
  end
  
  it "should accept running of subroutines" do
    should_parse("!1!", RS) do |e|
      e.cell.should == 1
    end
  end
  
  it "should accept printing of cell" do
    should_parse("<6>", PC) do |e|
      e.cell.should == 6
    end
    
    should_parse("!8!") do |e|
      e.cell.should == 8
    end
  end
  
  it "should accept reading of cell" do
    should_parse(">7<", RC) do |e|
      e.cell.should == 7
    end
  end
  
  it "should accept modification of cell" do
    should_parse("{7[6]}", MC) do |e|
      e.cell.should == 7
      e.op.should == nil
      e.value.should == 6
    end
    
    should_parse("{0[+7]}", MC) do |e|
      e.cell.should == 0
      e.op.should == :+
      e.value.should == 7
    end
    
    should_parse("{8[-3]}", MC) do |e|
      e.cell.should == 8
      e.op.should == :-
      e.value.should == 3
    end
  end
  
  it "should accept whileblock" do
    should_parse("{2{}}", WB) do |e|
      e.cell.should == 2
      e.statements.elements.should == []
    end
    
    should_parse("{3{:ASC:>0<}}", [WB, IM, RC]) do |e|
      e.cell.should == 3
      e.statements.elements.length.should == 2
    end
  end
  
  it "should accept subroutines" do
    should_parse("{10()}", AS) do |e|
      e.cell.should == 10
      e.statements.elements.should == []
    end
    
    should_parse("{2(:ASC:<0>)}", [AS, IM, PC]) do |e|
      e.cell.should == 2
      e.statements.elements.length.should == 2
    end
  end
  
  it "should handle multiple statements" do
    should_parse(":ASC:<5>>7<:NUM:!2!{9[3]}{8{|10|}}{0(>7<)}", IM, PC, RC, IM, RS, MC, [WB, PC], [AS, RC])
  end
end