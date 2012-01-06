#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#----------------------------------------------------------------------------
#
# File     : dia2pg.rb
# Author   : Jérémy Zurcher <jeremy@asynk.ch>
# Date     : 24/08/10
# License  :
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject to
#  the following conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#----------------------------------------------------------------------------
#
require 'ostruct'
require 'optparse'
#
class OpenStruct
    def to_h; @table end
end
#
options = OpenStruct.new
#
options.verbose = false
options.input = nil
options.database = nil
options.indent=4
#
opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on( "-i",  "--input FILENAME",             "input file" )                  { |n| options.input = n }
    opts.on( "-V",  "--verbose",                    "produce verbose output" )      { options.verbose = true }
    opts.on( "-d",  "--database DATABASE",          "set default database" )        { |n| options.database = n }
    opts.on( "-n",  "--indent N",                   "set number of indentation spaces" )        { |n| options.indent = n.to_i }
end
#
options.tbl_prefix+='_' if not options.tbl_prefix.nil? and options.tbl_prefix[-1]!='_'
#
opts.parse!(ARGV)
#
if options.input.nil?
    $stderr << "missing input file argument\n"
    exit 1
end
#
INDENT="\n"+" "*options.indent
#
class Table
    #
    def initialize n, t, a, d
        @name = n
        @tbl_prefix = t
        @attr_prefix = a
        @db = d
        @ids = []
        @bools = []
        @floats = []
        @integers = []
        @texts = []
        @times = []
    end
    attr_reader :ids, :bools, :floats, :integers, :texts, :times
    #
    def name
        (@tbl_prefix.nil? ? @name : @name[@tbl_prefix.length..-1]).capitalize   # TODO replace _(.) by $1.capitalize
    end
    #
    def to_s
        r="class #{name}"
        r << INDENT+'#'
        r << INDENT+'include Hmsa_lib::PgsqlModel'
        r << INDENT+'#'
        r << INDENT+"db '#{@db}'.freeze" unless @db.nil?
        r << INDENT+"prefix '#{@attr_prefix}'.freeze" unless @attr_prefix.nil?
        r << INDENT+'#' unless @db.nil? and @attr_prefix.nil?
        r << INDENT+"ids " + @ids.collect { |i| ":#{i}" }.join(', ') unless @ids.empty?
        [ :bools, :floats, :integers, :texts, :times].each do |sym|
            attrs = send sym
            next if attrs.empty?
            r << INDENT+"#{sym} " + attrs.collect { |a| ":#{@attr_prefix.nil? ? a : a[@attr_prefix.length..-1]}" }.join(', ')
        end
        r << INDENT+'#'
        r << INDENT+'sql_stmts( {'
        r << INDENT+" # :exists => [ 'select count(*) from #{@name} where #{@ids[0]}=$1::int', :#{@ids[0]} ]," unless @ids.empty?
        r << INDENT+'} )'
        r << INDENT+'#'
        r << "\nend"
    end
end
#
TABLES=[]
#
tbl=nil
tbl_prefix=nil
attr_prefix=nil
File.open(options.input).readlines.each do |l|
#    puts l
    if l=~/dia2pg/
        l.split.each do |s|
            k,v = s.split '='
            if k=~/tbl_prefix/
                tbl_prefix=v
            elsif k=~/attr_prefix/
                attr_prefix=v
            end
        end
    elsif l=~/CREATE TABLE (\S+)/
        tbl = Table.new $1, tbl_prefix, attr_prefix, options.database
        tbl_prefix=nil
        attr_prefix=nil
        TABLES << tbl
    elsif l=~/PRIMARY\s+KEY\s+\((\w*)\)/
        $1.split(/,/).reverse.each do |i|
            tbl.ids.insert 0, i
        end
    elsif l=~/(\w+)\s+integer\s+REFERENCES/
        tbl.ids << $1
    elsif l=~/(\w+)\s+boolean/
        tbl.bools << $1
    elsif l=~/(\w+)\s+double/
        tbl.floats << $1
    elsif l=~/(\w+)\s+integer/
        tbl.integers << $1
    elsif l=~/(\w+)\s+text/
        tbl.texts << $1
    elsif l=~/(\w+)\s+char/
        tbl.texts << $1
    elsif l=~/(\w+)\s+timestamp/
        tbl.times << $1
    end
end
#
TABLES.each do |t|
    puts "#"
    puts t
end
