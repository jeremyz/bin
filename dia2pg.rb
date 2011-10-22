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
options.drop = false
options.create = false
options.odids = false
options.user = 'postgres'
options.tbl_prefix = nil
#
opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on( "-i",  "--input FILENAME",             "input file" )                          { |n| options.input = n }
    opts.on( "-V",  "--verbose",                    "produce verbose output" )              { options.verbose = true }
    opts.on( "-d",  "--drop",                       "generate drop table statements" )      { options.drop = true }
    opts.on( "-c",  "--create",                     "generate create table statements" )    { options.create = true }
    opts.on( "-u",  "--user USER",                  "set table owner's" )                   { |n| options.user = n }
    opts.on( "-p",  "--prefix PREFIX",              "add a table prefix" )                  { |n| options.tbl_prefix = n }
    opts.on( "-o",  "--oids",                       "set OIDS" )                            { options.oids = true }
end
#
opts.parse!(ARGV)
#
if options.input.nil?
    $stderr << "missing input file argument\n"
    exit 1
end
#
options.tbl_prefix = ( options.tbl_prefix ? options.tbl_prefix+(options.tbl_prefix[-1]=='_' ? '' : '_') : '' )
#
HEADER="\n -- generated with dia2pg\n"
SEP="/**********************************************************************/"
DATABASE = {}
RELATIONS = []
#
class Table
    #
    def initialize opts
        @opts = opts
        @attributes = []
        @attr_prefix = nil
        @tbl_prefix = nil
    end
    #
    attr_reader :attr_prefix
    attr_writer :name
    attr_accessor :id
    #
    def to_s
        r = "Table #{@id} - #{@name} - #{@comment}\n"
        @attributes.inject(r) do |r,a| r<<a.to_s end
    end
    #
    def comment= c
        @comment = c
        if c=~/attr_prefix=(.*)$/
            @attr_prefix = $1
            @attr_prefix+='_' if @attr_prefix[-1]!='_'
        end
        if c=~/tbl_prefix=(.*)$/
            @tbl_prefix = $1
            @tbl_prefix+='_' if @tbl_prefix[-1]!='_'
        end
    end
    #
    def no_export?
        return false if @comment.nil?
        @comment=~/no_export=1/
    end
    #
    def << a
        @attributes << a
    end
    #
    def attr n
        @attributes[((n-10)/2)-1]
    end
    #
    def name
        ( @tbl_prefix ? @tbl_prefix+@name : @opts.tbl_prefix+@name )
    end
    #
    def to_sql
        r = ''
        if @attr_prefix or @opts.tbl_prefix
            r << "-- dia2pg"
            r << " tbl_prefix=#{@opts.tbl_prefix}" if @opts.tbl_prefix
            r << " attr_prefix=#{@attr_prefix}" if @attr_prefix
            r << "\n"
        end
        r << "CREATE TABLE #{name}\n(\n"
        pk = []
        uq = { :all=>[] }
        @attributes.each do |attr|
            sql = attr.to_sql
            next if sql.nil?
            r << sql
            pk << attr.real_name if attr.primary_key
            if attr.unique and not attr.primary_key
                if attr.comment=~/U./
                    uq[attr.comment] ||= []
                    uq[attr.comment]<< attr.real_name
                else
                    uq[:all] << attr.real_name
                end
            end
        end
        uq.each do |k,v| r << "    UNIQUE(#{v.join ','}),\n" unless v.empty? end
        r << "    CONSTRAINT pk_#{name} PRIMARY KEY (#{pk.join ','})\n" if pk.length>0
        r.sub!(/,\n$/,"\n")
        r << ")\nWITH (\n    OIDS=#{@opts.oids ? 'TRUE' : 'FALSE'}\n);\n"
        r << "ALTER TABLE #{name} OWNER TO #{@opts.user};\n"
        r
    end
    #
    def drop
        puts "DROP TABLE IF EXISTS #{name} CASCADE;\n"
    end
    #
end
#
class Attribute
    #
    def initialize tbl
        @tbl = tbl
    end
    #
    attr_reader :name, :primary_key, :unique, :comment
    attr_writer :name, :type, :comment, :primary_key, :nullable, :unique
    #
    def to_s
        "  # #{@name} - #{@type} - #{@comment} - #{@primary_key} - #{@nullable} - #{@unique}\n"
    end
    #
    def foreign?
        @type=~/foreign/
    end
    #
    def no_rename?
        return false if @comment.nil?
        @comment=~/no_rename=1/
    end
    #
    def no_prefix?
        return false if @comment.nil?
        @comment=~/no_prefix=1/
    end
    #
    def no_export?
        return false if @comment.nil?
        @comment=~/no_export=1/
    end
    #
    def real_name
        if foreign? and not  no_rename?
            rl = RELATIONS.find { |r| r.tbl_to==@tbl and r.attr_to.name==@name }
            if rl.nil?
                $stderr << "MISSING RELATION FOR FOREIGN KEY table:#{@tbl.name} attribute:#{@name}\n"
                raise Exception .new "MISSING RELATION FOR FOREIGN KEY table:#{@tbl.name} attribute:#{@name}\n"
            end
            if rl.tbl_from==@tbl
                ( (@tbl.attr_prefix.nil? or no_prefix?) ? @name : @tbl.attr_prefix+@name )
            else
                rl.attr_from.real_name
            end
        else
            ( (@tbl.attr_prefix.nil? or no_prefix?) ? @name : @tbl.attr_prefix+@name )
        end
    end
    #
    def type
        foreign? ? 'integer' : @type
    end
    #
    def to_sql
        return if no_export?
        r = "    #{format "%-35s", real_name}"
        if foreign?
            rl = RELATIONS.find { |r| r.tbl_to==@tbl and r.attr_to.name==@name }
            if rl.nil?
                $stderr << "MISSING RELATION FOR FOREIGN KEY #{@tbl.name} #{@name}\n"
                raise Excpetion.new "MISSING RELATION FOR FOREIGN KEY #{@tbl.name} #{@name}\n"
            else
                r << "integer REFERENCES #{rl.tbl_from.name}(#{rl.attr_from.real_name})"
                r << " NOT NULL" if not @nullable
            end
        elsif @nullable
            r << type
        else
            r << "#{type} NOT NULL"
        end
        r << ",\n"
    end
    #
end
#
class Relation
    #
    attr_accessor :tbl_from, :attr_from, :m_from, :tbl_to, :attr_to, :m_to
    #
    def to_s
        "  # #{tbl_from.name}.#{attr_from.name} (#{m_from}) => #{tbl_to.name}.#{attr_to.name} (#{m_to})"
    end
    #
end
#
require 'zlib'
require 'nokogiri'
doc = Nokogiri::XML( Zlib::GzipReader.new( File.open(options.input) ).read )
#
doc.xpath('//dia:object[@type="Database - Table"]').each do |node|
    tbl = Table.new options
    tbl.id = node.xpath('@id').to_s
    tbl.name = node.xpath('dia:attribute[@name="name"]/dia:string').first.content[1..-2]
    $stderr << "# parse #{tbl.id} #{tbl.name}\n" if options.verbose
    tbl.comment = node.xpath('dia:attribute[@name="comment"]/dia:string').first.content[1..-2]
#    tbl.comment = $1.to_s
    node.xpath('dia:attribute[@name="attributes"]').each do |el|
        el.xpath('dia:composite[@type="table_attribute"]').each do |a|
            attr = Attribute.new tbl
            attr.name = a.xpath('dia:attribute[@name="name"]/dia:string').first.content[1..-2]
            attr.type = a.xpath('dia:attribute[@name="type"]/dia:string').first.content[1..-2]
            $stderr << "   # #{attr.name} #{attr.type}\n" if options.verbose
            attr.comment = a.xpath('dia:attribute[@name="comment"]/dia:string').first.content[1..-2]
            attr.primary_key = a.xpath('dia:attribute[@name="primary_key"]/dia:boolean/@val').to_s=='true'
            attr.nullable = a.xpath('dia:attribute[@name="nullable"]/dia:boolean/@val').to_s=='true'
            attr.unique = a.xpath('dia:attribute[@name="unique"]/dia:boolean/@val').to_s=='true'
            tbl << attr
        end
    end
    DATABASE[tbl.id]=tbl
end
# DATABASE REFERENCES
doc.xpath('//dia:object[@type="Database - Reference"]').each do |node|
    r = Relation.new options
    r.m_from = node.xpath('dia:attribute[@name="start_point_desc"]/dia:string').first.content[1..-2]
    r.m_to = node.xpath('dia:attribute[@name="end_point_desc"]/dia:string').first.content[1..-2]
    r.tbl_from = DATABASE[node.xpath('dia:connections/dia:connection[@handle="0"]/@to').to_s]
    r.tbl_to = DATABASE[node.xpath('dia:connections/dia:connection[@handle="1"]/@to').to_s]
    next if r.tbl_from.nil? or r.tbl_to.nil?
    r.attr_from = r.tbl_from.attr node.xpath('dia:connections/dia:connection[@handle="0"]/@connection').to_s.to_i
    r.attr_to = r.tbl_to.attr node.xpath('dia:connections/dia:connection[@handle="1"]/@connection').to_s.to_i
    $stderr << "# connection : #{r.to_s}\n" if options.verbose
    RELATIONS << r
end
#
doc.xpath('//dia:object[@type="UML - Association"]').each do |node|
    r = Relation.new
    node.xpath('dia:attribute[@name="name"]/dia:string').first.content[1..-2]
    r.m_from = node.xpath('dia:attribute[@name="multipicity_a"]/dia:string').first.content[1..-2]
    r.m_to = node.xpath('dia:attribute[@name="multipicity_b"]/dia:string').first.content[1..-2]
    node.xpath('dia:attribute[@name="role_a"]/dia:string').first.content[1..-2]
    node.xpath('dia:attribute[@name="role_b"]/dia:string').first.content[1..-2]
    r.tbl_from = DATABASE[node.xpath('dia:connections/dia:connection[@handle="0"]/@to').to_s]
    r.tbl_to = DATABASE[node.xpath('dia:connections/dia:connection[@handle="1"]/@to').to_s]
    r.attr_from = r.tbl_from.attr node.xpath('dia:connections/dia:connection[@handle="0"]/@connection').to_s.to_i
    r.attr_to = r.tbl_to.attr node.xpath('dia:connections/dia:connection[@handle="1"]/@connection').to_s.to_i
    RELATIONS << r
end
#
TBL_DEBS= {}
#
RELATIONS.each do |r|
    TBL_DEBS[r.tbl_to.id] ||=[]
    TBL_DEBS[r.tbl_to.id] << r.tbl_from.id
end
#
FLUSHED = []
#
def flush tbl, l
    if l==DATABASE.length
        $stderr << "Can't resolve dependecy loop\n"
        exit 1
    end
    return if FLUSHED.include? tbl.id or tbl.no_export?
    if not TBL_DEBS[tbl.id].nil?
        TBL_DEBS[tbl.id].each do |t|
            # not self depend
            flush( DATABASE[t], l+1) if not t==tbl.id
        end
    end
    puts SEP
    puts tbl.to_sql
    puts ""
    FLUSHED << tbl.id
end
#
puts HEADER
if options.drop
    DATABASE.each do |k,tbl|
        tbl.drop unless tbl.no_export?
    end
    puts ''
end
if options.create
    DATABASE.each do |k,tbl|
        flush tbl, 0
    end
end
#
