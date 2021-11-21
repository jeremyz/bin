#! /bin/ruby

require 'json'
require 'open-uri'

n = ARGV.size
mpath=File.dirname(__FILE__)
mpath = ARGV.shift if n > 0
dbpath=File.join(mpath, 'db')
dbpath = ARGV.shift if n > 1

# TODO indicate if srt file is here

puts "  movies : #{mpath}\n      db : #{dbpath}"

API_KEY = 'c4202eaa738af60ae7a784c349a0cc63'
SEARCH_M="https://api.themoviedb.org/3/search/movie?api_key=#{API_KEY}&language=en-US&page=1&include_adult=true&query="
FETCH_M="https://api.themoviedb.org/3/movie/ID?api_key=#{API_KEY}"
FETCH_C="https://api.themoviedb.org/3/movie/ID/credits?api_key=#{API_KEY}"
URL_M='https://www.themoviedb.org/movie/'
URL_A='https://www.themoviedb.org/person/'
URL_I='https://www.themoviedb.org/t/p/original/'
DB=File.join(dbpath, 'db.json')
FIX=File.join(dbpath, 'fix.json')
FAIL=File.join(dbpath, 'failed.json')
DBA=File.join(dbpath, 'a')
DBM=File.join(dbpath, 'm')
HTML_I=File.join(dbpath, 'index.html')
HTML_M=File.join(dbpath, 'movies.html')
HTML_A=File.join(dbpath, 'actors.html')
BLANK='blank.png'

Dir.mkdir(dbpath) if not Dir.exist?(dbpath)
Dir.mkdir(DBA) if not Dir.exist?(DBA)
Dir.mkdir(DBM) if not Dir.exist?(DBM)

failed = []
fix = File.exist?(FIX) ? JSON.load(File.read(FIX)) : {}
prev_db = File.exist?(DB) ? JSON.load(File.read(DB)) : []
idx = prev_db.collect { |m| m['filename'] }
current_db = []

def search fn
  fn = fn.downcase.tr('àáâäçèéêëìíîïòóôöùúûü','aaaaceeeeiiiioooouuuu')
  b,e = fn.split '.'
  ar = b.split '-'
  name = ar[0].gsub('_', ' ')
  if ar.size == 2
    year = ar[1]
  elsif ar.size == 3
    sequel = ar[1].gsub('_', ' ')
    year = ar[2]
  end
  puts "search : #{name} - #{year} - #{sequel}"
  begin
    res = JSON.load URI.open(SEARCH_M+name.tr('&','')).read
  rescue
    return nil
  end
  return nil if res['total_results'] == 0
  sel = res['results'].select { |r| (r['release_date']||'nope')[0..3] == year }
  return nil if sel.size == 0
  if sel.size == 1
    puts "  found '#{sel[0]['title']}'"
  else
    puts "  found #{sel.map {|s| s['title'] + ' ' + s['release_date']||'?' }}"
    s = sel.select { |r| r['title'].downcase == name }
    sel = s if s.size > 0
    s = sel.select { |r| r['title'].downcase.gsub(/[^ a-z]/, '') =~ /#{name.gsub(/[^ a-z]/, '')}/ } if sel.size != 1
    sel = s if s.size > 0
    sel = sel.select { |r| r['title'].downcase =~ /#{sequel}/ } if sel.size != 1
    return nil if sel.size != 1
    puts "  choose '#{sel[0]['title']}'"
  end
  sel[0]
end

def download id, p, base
  return nil if p.nil?
  fn = id.to_s + File.extname(p)
  dst = File.join(base, fn)
  if not File.exist? dst
    puts " download #{URL_I + p} -> #{dst}"
    File.open(dst, 'wb') { |f| f.write URI.open(URL_I + p).read }
  end
  fn
end

def fetch id, fn, m
  m['filename'] = fn
  m['img'] = download(id, m['poster_path'], DBM)
  m['cast'] = []
  JSON.load(URI.open(FETCH_C.sub(/ID/, id.to_s)).read)['cast'].each_with_index do |a, i|
    break if i > 6
    a['img'] = download(a['id'], a['profile_path'], DBA)
    m['cast'] << a
  end
  m
end

Dir.glob(File.join(mpath, '*')) do |fn|
  next if File.directory? fn
  next if fn =~ /\.srt/ or fn =~ /\.rb/ or fn =~ /\.sub/ or fn =~ /\.jpg/
  fn = fn.split('/')[-1]
  id = fix[fn]
  if not id.nil?
    m = prev_db.find{ |i| i['id'] == id and i['filename'] == fn }
    m = JSON.load URI.open(FETCH_M.sub(/ID/, id.to_s)).read if m.nil?
    current_db << fetch(id, fn, m)
    next
  end
  if idx.include? fn
    current_db << prev_db.find{ |i| i['filename'] == fn }
    next
  end
  m = search fn
  if m.nil?
    puts '  failed'
    failed << fn
  else
    current_db << fetch(m['id'], fn, m)
  end
end

CSS=-<<EOF
html, body  { height:98%; overflow:auto; }
div#toc     { margin:auto; padding:30 50px; width:800px; }
div#anchors { margin:auto; padding:30 50px; }
a           { color:black; text-decoration: none; width:100%; height:100%; }
a:hover     { color:#96281b;}
td          { padding:0px; }
 .alpha     { padding:10px; font-weight:bold; font-size:18px; color:#96281b; }
 a.alpha:hover { font-size:35px; }
 .active    { font-size:35px; }
ul          { list-style-type: none; }
table.mid   { margin:auto; padding:0 50px; }
td.release  { padding-left:20px; }
td.link     { width:250px; }
td.link:hover  { background-color:#95a5a6; }
div.link    { padding:10px; }
div.entry   { margin:20px; background-color:#bdc3c7; overflow:auto; }
div.poster  { padding:20px; margin:auto; float:left; }
div.left    { float:right; width:1500px; }
div.meta    { padding:20px; width:1450px; float:left; }
div.title   { font-weight:bold; font-size:30px; color:#96281b; float:left; }
div.original{ font-size:30px; padding-left:10px; float:left; }
div.year    { font-size:30px; padding-left:10px; float:left; }
div.fn      { font-size:20px; float:right; }
div.cast    { float:left; background-color:#dadfe1;}
div.actor   { margin: 0 15px; float:left; }
div.overview{ margin: 15px; float:left; }
#fixed-div  { background-color:#6bb9f0; position:absolute; bottom: 4em; right: 4em; padding:20px;}
#letters    { position:absolute; top: 1em; right: 10em; width:50px; }
li          { padding:4px; }
EOF

current_db.sort! {|a,b| a['title'].downcase <=> b['title'].downcase }
File.open(DB, 'w') { |f| f << current_db.to_json }
File.open(HTML_I, 'w') do |f|
  f << '<html><head><title>Movies Index</title><meta charset="utf-8"></head><style>'
  f << 'body { background-color:#bdc3c7; }'
  f << CSS
  f << "</style><body>\n<div id=fixed-div><a href=movies.html>Movies</a><br/><br/><a href=actors.html>Actors</a></div>\n<div id=toc>"
  f << "<div id=letters><ul>" + ('A'..'Z').inject('') {|r,i| r+ "<li><a href='##{i}' class=alpha>#{i}</a></li>"} + '</ul></div>'
  letter=nil
  current_db.each do |m|
    l = m['title'][0].upcase
    if l != letter
      letter = l
      f << '</table>' if not letter.nil?
      f << "<div name=#{letter} id=#{letter} class=\"alpha active\">#{letter}</div><table class=mid>"
    end
    f << "<tr><td class=link><a href=movies.html##{m['id']}><div class=link>#{m['title']}</div></a></td><td class=release>#{m['release_date'][0..3]}</td></tr>"
  end
  f << '</table></div></body></html>'
end
actors = {}
File.open(HTML_M, 'w') do |f|
  f << '<html><head><title>My Movies</title><meta charset="utf-8"></head><style>'
   f << 'body  { background-color:#89c4f4; }'
  f << CSS
  f << "</style><body>\n<div id=fixed-div><a href=index.html>Index</a><br/><br/><a href=actors.html>Actors</a></div>"
  current_db.each do |m|
    img = m['img']
    img = (img.nil? ? BLANK : ('m/' + img))
    f << "<div class=entry id=#{m['id']}>"
    f << "<div class=poster><a href='#{URL_M}#{m['id']}'><img src=#{img} height=380px/></a></div><div class=left>"
    f << "<div class=meta><div class=title>#{m['title']}</div>"
    f << "<div class=original>(#{m['original_title']})</div>" if m['title'] != m['original_title']
    f << "<div class=year>- #{m['release_date'][0..3]}</div>"
    f << "<div class=fn>[#{m['filename']}]</div></div><div class=cast>\n"
    m['cast'].each do |a|
      img = a['img']
      img = (img.nil? ? BLANK : ('a/' + img))
      f << "<div class=actor><h3>#{a['original_name']}<h3><a href='#{URL_A}#{a['id']}'><img src=#{img} width=150px/></a></div>\n"
      actors[a['name']] ||= {'id'=>a['id'], 'movies'=>[]}
      actors[a['name']]['movies'] << [m['id'], m['title'], m['release_date']]
    end
    f << "</div><div class=overview>#{m['overview']}</div>\n"
    f << "</div></div>\n"
  end
  f << '</body></html>'
end

File.open(HTML_A, 'w') do |f|
  f << '<html><head><title>Actors Index</title><meta charset="utf-8"></head><style>'
  f << 'body { background-color:#bdc3c7; }'
  f << CSS
  f << "</style><body>\n<div id=fixed-div><a href=index.html>Index</a><br/><br/><a href=movies.html>Movies</a></div>\n<div id=toc>"
  f << "<div id=letters><ul>" + ('A'..'Z').inject('') {|r,i| r+ "<li><a href='##{i}' class=alpha>#{i}</a></li>"} + '</ul></div>'
  letter=nil
  actors.keys.sort! {|a,b| a.downcase <=> b.downcase }.each do |aname|
    l = aname[0].upcase
    if l != letter
      letter = l
      f << '</table>' if not letter.nil?
      f << "<div name=#{letter} id=#{letter} class=\"alpha active\">#{letter}</div><table class=mid>"
    end
    d = actors[aname]
    d['movies'].sort! { |a,b| b[2] <=> a[2] }
    m = d['movies'].shift
    f << "<tr><td class=link><a href='#{URL_A}#{d['id']}'><div class=link>#{aname}</div></a></td>"
    f << "<td class=link><a href='#{URL_M}#{m[0]}'><div class=link>#{m[1]}</div></a></td><td class=release>#{m[2][0..3]}</td></tr>"
    d['movies'].each do |m|
      f << "<tr><td>&nbsp;</td><td class=link><a href='#{URL_M}#{m[0]}'><div class=link>#{m[1]}</div></a></td><td class=release>#{m[2][0..3]}</td></tr>"
    end
  end
  f << '</table></div></body></html>'
end

puts "FAILED :"
File.open(FAIL, 'w') { |f| f << failed.to_json }
failed.each { |fn| puts "  -> #{fn}" }
