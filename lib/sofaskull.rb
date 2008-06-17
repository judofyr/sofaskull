#!/usr/bin/ruby

require 'rubygems'
require 'treetop'
begin
  require 'sofaskullparser' 
rescue LoadError
  # For development
  Treetop.load(File.expand_path(File.dirname(__FILE__)+"/../grammar/sofaskull"))
end

module SofaSkull
  class SyntaxError < StandardError;def message()"You have a syntax error"end;end
  
  module Common
    def cell
      super.text_value.to_i
    end
    
    def sub
      super.text_value.to_i
    end

    def ===(m)
      (m.is_a?(Module))?self.is_a?(m):super
    end
  end
  
  module IOMode
    include Common

    def to_sym
      text_value.tr(':','').downcase.to_sym
    end
  end

  module WhileBlock
    include Common
  end
  
  module AddSub
    include Common
  end
  
  module RunSub
    include Common
  end
  
  module ConRunSub
    include Common
  end

  module ModCell
    include Common

    def value
      super.text_value.to_i
    end

    def op
      negopos.text_value.to_sym unless negopos.text_value.empty?
    end
  end
  
  module CopyCell
    include Common
    
    def to
      super.text_value.to_i
    end
  end

  module PrintCell
    include Common
  end

  module ReadCell
    include Common
  end

  class Program
    EOF = 0
    attr_reader :result, :statements, :clean
    attr_accessor :io_mode
 
    def initialize(source, sub = false)
      @statements = parse(source)
      @sub = sub
      @io_mode = :asc
      @result = String.new
      header! unless sub
    end

    def header!
      @result << File.read(File.join(File.dirname(__FILE__), "helpers.neko"))
    end
 
    def step
      s = @statements.shift
      return false if s.nil?
      case s
      when IOMode
        @io_mode = s.to_sym 
      when ModCell
        op = "-" if s.op == :-
        mod = (!s.op.nil?).to_s
        @result << "set_cell(#{s.cell}, #{op}#{s.value}, #{mod});"
      when CopyCell
        @result << "copy_cell(#{s.cell}, #{s.to});"
      when PrintCell
        @result << "$print(sprintf(#{ps}, get_cell(#{s.cell})));"
      when ReadCell
        @result << "read_cell(#{s.cell}, #{io_mode == :asc});"
      when WhileBlock
        @result << "while(get_cell(#{s.cell})!=0){#{sub(s.statements.elements)}}"
      when AddSub
        @result << "set_sub(#{s.sub}, function(){#{sub(s.statements.elements)}});"
      when RunSub
        @result << "call_sub(#{s.sub});"
      when ConRunSub
        @result << "if(get_cell(#{s.cell})==0){call_sub(#{s.sub})}"
      end
      true
    end
 
    def run
      step until @statements.empty?
    end

    def ps
      @io_mode == :asc ? '"%c"' : '"%d"'
    end
 
    # Cleans it up and parses the source. Returns a list of statements or raises SyntaxError. 
    def parse(source)
      return source if source.is_a?(Array)
      @clean = self.class.clean(source)
      if i=SofaSkullParser.new.parse(@clean)
        i.elements
      else
        raise SofaSkull::SyntaxError
      end
    end

    # Removes comments and spaces
    def self.clean(s)
      s.gsub(/(\/\/|#).*/,'').tr("\n\r\t\040",'')
    end
 
    private

    def sub(code)
      p = self.class.new(code.dup, true)
      p.io_mode = io_mode
      p.run
      p.result
    end
  end
end
