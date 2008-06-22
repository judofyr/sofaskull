#!/usr/bin/ruby

require 'rubygems'
require 'set'
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
    DEPENDENCIES = {
      :order => [:cells, :subs, :print, :get_cell, :set_cell, :read,
                 :copy_cell, :set_sub, :call_sub],
      :get_cell => :cells,
      :set_cell => :get_cell,
      :copy_cell => :set_cell,
      :read => :set_cell,
      :print => :get_cell,
      :set_sub => :subs,
      :call_sub => :subs,
    }
    EOF = 0
    attr_reader :statements, :clean
    attr_accessor :io_mode, :dependencies
 
    def initialize(source, sub = false)
      @statements = parse(source)
      @sub = sub
      @io_mode = :asc
      @result = String.new 
      @dependencies = Set.new
    end
 
    def step
      s = @statements.shift
      return false if s.nil?
      case s
      when IOMode
        @io_mode = s.to_sym 
      when ModCell
        depends_on :set_cell
        op = "-" if s.op == :-
        mod = (!s.op.nil?).to_s
        @result << "set_cell(#{s.cell}, #{op}#{s.value}, #{mod});"
      when CopyCell
        depends_on :copy_cell
        @result << "copy_cell(#{s.cell}, #{s.to});"
      when PrintCell    
        depends_on :print
        @result << "$print(sprintf(#{ps}, get_cell(#{s.cell})));"
      when ReadCell    
        depends_on :read
        @result << "read_cell(#{s.cell}, #{io_mode == :asc});"
      when WhileBlock  
        depends_on :get_cell
        @result << "while(get_cell(#{s.cell})!=0){#{sub(s.statements.elements)}}"
      when AddSub
        depends_on :set_sub
        @result << "set_sub(#{s.sub}, function(){#{sub(s.statements.elements)}});"
      when RunSub
        depends_on :call_sub
        @result << "call_sub(#{s.sub});"
      when ConRunSub
        depends_on :get_cell, :call_sub
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
    
    def depends_on(*d)
      @dependencies.merge(d.each do |x|
        more = [DEPENDENCIES[x]].flatten.compact
        unless @dependencies.include?(x) && more.empty?
          depends_on(*more)
        end
      end)
    end
    
    def dependencies
      @dependencies.to_a.sort_by { |x| DEPENDENCIES[:order].index(x) }
    end
    
    def headers
      dependencies.map do |dep|
        File.read(File.join(File.dirname(__FILE__), "helpers", "#{dep}.neko"))
      end.join($/)
    end
      
    def result(with_headers = true)
       (with_headers ? headers : "") + @result
    end

    # Removes comments and spaces
    def self.clean(s)
      s.gsub(/(\/\/|#).*/,'').tr("\n\r\t\040",'')
    end
 
    private

    def sub(code)
      p = self.class.new(code.dup, true)
      p.io_mode = io_mode
      p.dependencies = @dependencies
      p.run
      @dependencies = p.dependencies.to_set
      p.result(false)
    end
  end
end
