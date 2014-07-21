
require 'sinatra'
require 'slim'
require 'mongo'
require 'json'

before do
  db_con = Mongo::Connection.new('localhost', 27017)
  @db    = db_con.db('sample_db')
  @hostinfos = @db.collection('hostinfos')
end

def bytes_to_string(bytes)

  kb = 1024
  mb = 1024*kb
  gb = 1024*mb
  tb = 1024*gb

  if bytes <= kb
    return sprintf("%dB", bytes) 
  elsif bytes <= mb
    return sprintf("%.1fKiB", bytes / kb.to_f)
  elsif bytes <= gb
    return sprintf("%.1fMiB", bytes / mb.to_f)
  elsif bytes <= tb
    return sprintf("%.1fGiB", bytes / gb.to_f)
  else
    return sprintf("%.1fTiB", bytes / tb.to_f)
  end
end

def hdd_size_string(hddInfo)
  used = hddInfo["Used"].to_i
  total = hddInfo["Total"].to_i
  sprintf( "%s/%s", bytes_to_string(used), bytes_to_string(total) )
end

def hdd_size_percent(hddInfo)
  used = hddInfo["Used"].to_i
  total = hddInfo["Total"].to_i
  sprintf( "%d%%", used * 100 / total )
end

get '/' do
  slim :index
end

DEFAULT_HASH = {
  "name" => "unknown",
  "memory" => "unknown",
  "hdd" => "unknown"
}

post '/update' do
  puts "params: #{params.to_s}"
  h = DEFAULT_HASH.merge(params)
  info = @hostinfos.find_one( { "name" => params[:name] } )
  puts "info: #{info.to_s}"
  if info
    p @hostinfos.update( { "_id" => info["_id"]}, { "$set" => h } )
  else
    @hostinfos.insert( h )
  end
  slim :index
end

post '/json' do
  params = JSON.parse request.body.read
  info = @hostinfos.find_one( { "name" => params[:name] } )
  if info 
    @hostinfos.update( { "_id" => info["_id"]}, { "$set" => params } )
  else
    @hostinfos.insert( params )
  end
  "ok"
end
