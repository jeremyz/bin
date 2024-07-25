#! /bin/ruby

require 'json'
require 'open-uri'

# tmdb [movie_path] [db_path]
n = ARGV.size
mpath = n.positive? ? ARGV.shift : File.dirname(__FILE__)
dbpath = n > 1 ? ARGV.shift : File.join(mpath, 'db')

puts "  movies : #{mpath}\n      db : #{dbpath}"

API_KEY = JSON.parse(File.read(File.expand_path('~/.tmdb.json')))['apikey']
API_URL = 'https://api.themoviedb.org/3'.freeze
SEARCH_M = "#{API_URL}/search/movie?api_key=#{API_KEY}&language=en-US&page=1&include_adult=true&".freeze
SEARCH_T = SEARCH_M.sub(%r{/movie}, '/tv').freeze
FETCH_M = "#{API_URL}/movie/ID?api_key=#{API_KEY}".freeze
FETCH_T = FETCH_M.sub(%r{/movie}, '/tv').freeze
FETCH_CM = "#{API_URL}/movie/ID/credits?api_key=#{API_KEY}".freeze
FETCH_CT = FETCH_CM.sub(%r{/movie}, '/tv').freeze
URL_M = 'https://www.themoviedb.org/movie/'.freeze
URL_T = URL_M.sub(%r{/movie}, '/tv').freeze
URL_A = 'https://www.themoviedb.org/person/'.freeze
URL_I = 'https://www.themoviedb.org/t/p/original/'.freeze
ACTORS_N = 6
ASZ = 150
MSZ = 350
BLANK = 'blank.png'.freeze
DB = File.join(dbpath, 'db.json')
FIX = File.join(dbpath, 'fix.json')
FAIL = File.join(dbpath, 'failed.json')
DBA = File.join(dbpath, 'a')
DBM = File.join(dbpath, 'm')
HTML_I = File.join(dbpath, 'index.html')
HTML_M = File.join(dbpath, 'movies.html')
HTML_A = File.join(dbpath, 'actors.html')
HTML_F = File.join(dbpath, 'failed.html')
HTML_N = File.join(dbpath, 'new.html')

Dir.mkdir(dbpath) unless Dir.exist?(dbpath)
Dir.mkdir(DBA) unless Dir.exist?(DBA)
Dir.mkdir(DBM) unless Dir.exist?(DBM)

def write_db(next_db)
  puts "write #{DB}"
  File.open(DB, 'w') { |f| f << next_db.to_json }
end

def num
  ('1'..'9').inject('') { |r, i| "#{r}<div class=link><a class=dic href='##{i}'>#{i}</a></div>" }
end

def alpha
  ('A'..'Z').inject('') { |r, i| "#{r}<div class=link><a class=dic href='##{i}'>#{i}</a></div>" }
end

def menu(*links)
  t = '<div id=menu>'
  links.each { |link| t << "<a class=linkm href='#{link.downcase}.html'>#{link}</a>" }
  t << '</div>'
end

def prelude(title)
  f = "<html><head><title>#{title}</title><meta charset='utf-8' />\n"
  f << '<link rel="stylesheet" href="db.css" />'
  f << '<script src="lazy.js"></script>'
  f << "</head><body>\n"
end

def write_index(next_db)
  puts "write #{HTML_I}"
  File.open(HTML_I, 'w') do |f|
    f << prelude('Movies Index')
    f << menu('Movies', 'Actors', 'New', 'Failed')
    f << '<div id=toc>'
    f << "<div id=adic class=dic>#{alpha}</div>\n"
    f << "<div id=ndic class=dic>#{num}</div>\n"
    letter = nil
    next_db.each do |m|
      l = m['title'][0].upcase
      if l != letter
        f << '</table></div>' unless letter.nil?
        letter = l
        f << "<div class=letter>\n  <div name=#{letter} id=#{letter} class=alpha>#{letter}</div>\n<table class=index>"
      end
      f << "<tr class=entry><td class=movie><a class=link href='movies.html##{m['id']}'>#{m['title']}#{' - TV' if m['is_tv']}</a></td>\n"
      f << "  <td class=release>#{m['release_date'][0..3]}</td></tr>\n"
    end
    f << '</table></div></body></html>'
  end
end

def write_actors(actors)
  puts "write #{HTML_A}"
  File.open(HTML_A, 'w') do |f|
    f << prelude('Actors')
    f << menu('Index', 'Movies', 'New', 'Failed')
    f << '<div id=toc>'
    f << "<div id=adic class=dic>#{alpha}</div>\n"
    f << "<div id=ndic class=dic>#{num}</div>\n"
    letter = nil
    actors.keys.sort! { |a, b| a.downcase <=> b.downcase }.each do |aname|
      l = aname[0].upcase
      if l != letter
        f << '</table></div>' unless letter.nil?
        letter = l
        f << "<div class=letter>\n  <div name=#{letter} id=#{letter} class=alpha>#{letter}</div>\n<table class=index>"
      end
      d = actors[aname]
      d['movies'].sort! { |a, b| b[2] <=> a[2] }
      m = d['movies'].shift
      f << "<tr class=entry><td class=actor><a class=link href='#{URL_A}#{d['id']}'>#{aname}</a></td>\n"
      f << "<td class=movie><a class=link href='movies.html##{m[0]}'>#{m[1]}</a></td>"
      f << "<td class=release>#{m[2][0..3]}</td></tr>"
      d['movies'].each do |mov|
        f << "<tr class=entry><td>&nbsp;</td><td class=link><a class=link href='movies.html##{m[0]}'>#{mov[1]}</a></td>"
        f << "<td class=release>#{mov[2][0..3]}</td></tr>"
      end
    end
    f << '</table></div></body></html>'
  end
end

def __write_movies(fout, movies, actors = nil)
  movies.each do |m|
    url = m['is_tv'] ? URL_T : URL_M
    img = (m['img'].nil? ? BLANK : "m/#{m['img']}")
    fout << "<div class=movie id=#{m['id']}><div class=poster>"
    fout << "<a href='#{url}#{m['id']}'><img class=lazy data-src=#{img} height=#{MSZ}px /></a></div>"
    fout << '<div class=cont0><div class=info>'
    fout << "<div class=title>#{m['title']}</div>"
    fout << "<div class=original>(#{m['original_title']})</div>" if m['title'] != m['original_title']
    if m['is_tv']
      fout << "<div class=year>#{m['release_date'][0..3]}-#{m['last_air_date'][0..3]}</div>"
      fout << "<div class=season>#{m['eps']}/#{m['number_of_episodes']} episodes -#{m['number_of_seasons']} seasons</div>"
    else
      fout << "<div class=year>#{m['release_date'][0..3]}</div>"
    end
    # fout << "<div class=fn>[#{m['fname']}]</div>"
    fout << "</div><div class=cast>\n"
    m['cast'].each do |a|
      img = a['img']
      img = (img.nil? ? BLANK : "a/#{img}")
      fout << "<div class=actor><h2>#{a['name']}</h2>"
      fout << "<a href='#{URL_A}#{a['id']}'><img class=lazy data-src=#{img} width=#{ASZ}px /></a></div>\n"
      unless actors.nil?
        actors[a['name']] ||= { 'id' => a['id'], 'movies' => [] }
        actors[a['name']]['movies'] << [m['id'], m['title'], m['release_date']]
      end
    end
    fout << "</div><div class=overview>#{m['overview']}</div>\n"
    fout << "</div></div>\n"
  end
end

def write_movies(movies)
  puts "write #{HTML_M}"
  actors = {}
  File.open(HTML_M, 'w') do |f|
    f << prelude('Movies')
    f << menu('Index', 'Actors', 'New', 'Failed') << "\n"
    __write_movies(f, movies, actors)
    f << '</body></html>'
  end
  actors
end

def write_failed(failed)
  puts "write #{HTML_F}"
  File.open(HTML_F, 'w') do |f|
    f << prelude('Failed')
    f << menu('Index', 'Actors', 'New', 'Failed') << "\n"
    failed.each do |fn|
      f << "<div class=movie>#{fn}</div>\n"
    end
    f << '</body></html>'
  end
end

def write_new(movies)
  puts "write #{HTML_N}"
  File.open(HTML_N, 'w') do |f|
    f << prelude('New')
    f << menu('Index', 'Movies', 'Actors', 'Failed') << "\n"
    __write_movies(f, movies)
    f << '</body></html>'
  end
end

def download(id, path, base)
  return nil if path.nil?

  fn = id.to_s + File.extname(path)
  dst = File.join(base, fn)
  unless File.exist? dst
    puts "     get : #{dst}"
    File.open(dst, 'wb') { |f| f.write URI(URL_I + path).open.read }
  end
  system("magick #{dst} -resize x#{MSZ} #{dst}") if base == DBM
  system("magick #{dst} -resize #{ASZ}x #{dst}") if base == DBA
  fn
end

def get_all(data)
  id = data['id']
  data['img'] = download(id, data['poster_path'], DBM)
  data['cast'] = []
  url = data['is_tv'] ? FETCH_CT : FETCH_CM
  JSON.parse(URI(url.sub(/ID/, id.to_s)).open.read)['cast']
      .sort { |a, b| a['order'] <=> b['order'] }.each_with_index do |a, i|
    break if i == ACTORS_N

    a['img'] = download(a['id'], a['profile_path'], DBA)
    data['cast'] << a
  end
  data
end

def filter_results(res, data)
  sel = res.select { |r| (r['release_date'] || 'nope')[0..3] == data[:year] }
  return nil if sel.empty?

  if sel.size > 1
    puts "     #{sel.map { |s| "#{s['title']} #{s['release_date'] || '?'}" }.join("\n     ")}"
    s = sel.select { |r| r['stitle'] =~ /#{data[:sequel]}/ } unless data[:sequel].nil?
    sel = s unless s.nil? || s&.empty?
    s = sel.select { |r| r['stitle'] == data[:name] }
    sel = s unless s.empty?
    return nil if sel.size != 1

  end

  puts "    => : '#{sel[0]['title']}' #{sel[0]['id']}"
  sel[0]['id']
end

def normalise_results(res)
  res.each do |r|
    r['release_date'] = r['first_air_date'] unless r.key? 'release_date'
    r['title'] = r['name'] unless r.key? 'title'
    r['original_title'] = r['original_name'] unless r.key? 'original_title'
    r['stitle'] = r['title'].downcase.gsub(/[^ a-z0-9]/, '')
  end
  res
end

def fetch(data)
  url = data['is_tv'] ? FETCH_T : FETCH_M
  [] << JSON.parse(URI(url.sub(/ID/, data['id'].to_s)).open.read)
end

def search(data)
  url = data['is_tv'] ? SEARCH_T : SEARCH_M
  res = JSON.parse(URI.parse(url + URI.encode_www_form('query' => data[:name])).read)['results']
  normalise_results(res)
  filter_results(res, data)
end

def process_fname(data)
  puts "#{data['fname']} :"
  fname = data['fname'].downcase.tr('àáâäçèéêëìíîïòóôöùúûü', 'aaaaceeeeiiiioooouuuu').gsub('_', ' ')
  fname = fname[..-5] unless data['is_tv']
  name, *more = fname.split '-'
  year = more[-1]
  sequel = more[0] if more.size == 2
  data.merge(name: name, year: year, sequel: sequel)
end

def process(data)
  data = process_fname(data)
  data['id'] = search(data) if data['id'].nil?
  return nil if data['id'].nil?

  data.merge!(normalise_results(fetch(data))[0])
  get_all(data)
end

def in_prev_db?(fname, prev_db)
  prev_db.find { |i| i['fname'] == fname } if @db_idx.include?(fname)
end

failed = []
fix_db = File.exist?(FIX) ? JSON.parse(File.read(FIX)) : {}
prev_db = File.exist?(DB) ? JSON.parse(File.read(DB)) : []
@db_idx = prev_db.collect { |m| m['fname'] }
next_db = []

def skip?(fname)
  fname =~ /\.srt$/ || fname =~ /\.sub$/ || fname =~ /\.jpg$/ || fname =~ /^db/
end

def eps(path)
  n = 0
  Dir.glob(File.join(path, '*')) do |fn|
    n += 1 unless skip?(fn)
  end
  n
end

# FIXME: list seasons -> x/N
Dir.glob(File.join(mpath, '*')) do |path|
  fname = path.split('/')[-1]
  next if skip?(fname)

  data = in_prev_db?(fname, prev_db)
  if data.nil?
    is_tv = File.directory?(path)
    mtime = File.mtime(path).to_i.to_s
    eps = is_tv ? eps(path) : 0
    data = process('id' => fix_db[fname], 'fname' => fname, 'is_tv' => is_tv, 'eps' => eps, 'mtime' => mtime)
  end
  failed << fname if data.nil?
  next_db << data unless data.nil?
end

next_db.sort! { |a, b| a['title'].downcase <=> b['title'].downcase }
write_db(next_db)
write_index(next_db)
write_actors(write_movies(next_db))
write_failed(failed)
write_new(next_db.sort { |a, b| b['mtime'] <=> a['mtime'] }[..20])

puts 'FAILED :'
File.open(FAIL, 'w') { |f| f << failed.to_json }
failed.each { |fn| puts "  -> #{fn}" }

# jq '.[] | select(.fname | test("Fargo"))' db.json
# curl --request GET --url 'https://api.themoviedb.org/3/tv/60622/season/2/credits?api_key=c4202eaa738af60ae7a784c349a0cc63' | jq '.cast'
# 'https://api.themoviedb.org/3/tv/series_id/season/season_number/credits?languag
