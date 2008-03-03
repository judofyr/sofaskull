#!/usr/bin/ruby

require 'rubygems'
require 'treetop'
begin
  require 'sofaskullparser' 
rescue
  # For development
  Treetop.load(File.expand_path(File.dirname(__FILE__)+"/../grammar/sofaskull"))
end

module SofaSkull
  class SyntaxError < StandardError;def message()"There is a syntax error"end;end
  
  module Common
    def cell
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
    
    def sub
      super.text_value.to_i
    end
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

  module PrintCell
    include Common
  end

  module ReadCell
    include Common
  end

  class Program
    EOF = 0
    attr_accessor :cells, :subroutines, :io_mode, :statements, :stdin, :stdout
 
    def initialize(source)
      @statements = parse(source)
      @cells = Hash.new{|hash,key|hash[key]=0}
      @subroutines = Hash.new{|hash,key|hash[key]=[]}
      @io_mode = :asc
      @stdin = $stdin
      @stdout = $stdout
    end
 
    def step
      s = @statements.shift
      return false if s.nil?
      case s
      when IOMode
        @io_mode = s.to_sym
      when ModCell
        mod_cell(s.cell, s.op, s.value)
      when PrintCell
        print_cell(s.cell)
      when ReadCell
        read_cell(s.cell)
      when WhileBlock
        while_block(s.cell, s.statements.elements)
      when AddSub
        @subroutines[s.cell] = s.statements.elements
      when RunSub
        sub(@subroutines[s.cell])
      when ConRunSub
        sub(@subroutines[s.sub]) if self[s.cell].zero?
      end
      true
    end
 
    def run
      step until @statements.empty?
    end
 
    def [](cell)
      @cells[cell]
    end
 
    def []=(cell, value)
      value %= 256
      @cells[cell] = value
    end
 
    def asc?
      @io_mode == :asc
    end
    
    def data
      [@cells, @subroutines, @io_mode, @stdin, @stdout]
    end
    
    def data=(a)
      @cells, @subroutines, @io_mode, @stdin, @stdout = *a
    end
    
    # Cleans it up and parses the source. Returns a list of statements or raises SyntaxError. 
    def parse(source)
      return source if source.is_a?(Array)
      SofaSkullParser.new.parse(clean(source)).elements rescue raise(SofaSkull::SyntaxError)
    end

    # Removes comments and spaces
    def clean(s)
      s.gsub(/\/\/.*/,'').tr("\n\r\t\040",'')
    end
 
    private
 
    # Prints a cell
    def print_cell(cell)
      o = self[cell]
      o = o.chr if asc?
      @stdout.print(o)
      @stdout.flush
    end
 
    # Reads a cell
    def read_cell(cell)
      o = @stdin.getc || EOF
      o = o.chr.to_i unless asc?
      self[cell] = o
    end
 
    # Modifies a cell
    def mod_cell(cell, op, value)
      self[cell] = op ? self[cell].send(op, value) : value
    end
 
    # Runs a while block
    def while_block(cell, code)
      while self[cell] != 0
        sub(code)
      end
    end
 
    def sub(code)
      p = self.class.new(code.dup)
      p.data = *data
      p.run
      data = p.data
    end
  end
end