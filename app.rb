require 'sinatra'
require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'uri'
require 'zipruby'
require 'find'
require 'nkf'
require 'eventmachine'

get '/' do
  erb :index
end

get '/:id' do
  if FileTest.exist?("./tmp/imgs/#{params[:id]}.zip")
    @flag_getting = false
  else
    @flag_getting = true
  end
  erb :id
end

get '/download/:id' do
  send_file("./tmp/imgs/#{params[:id]}.zip")
end

post '/give_me_img' do
  id = params[:url].gsub("http://","").gsub("matome.naver.jp/odai/","").gsub("matome.naver.jp/m/odai/","").gsub("/","")

  if id == nil
    redirect "/"
  end

  EM::defer do
    get_imgs(id)
    make_zip(id)
  end
  redirect "/#{id}"
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def id_is_valid?(id)
    #TODO
    #数字だけ？
    #page = Nokogiri::HTML(open("http://matome.naver.jp/odai/#{id}"))
    #開ける？
    true
  end

  def file_present?(id)
    #TODO
  end

  def get_imgs(id)
    dirName = "./tmp/imgs/#{id}/"
    return if FileTest.exist?(dirName)
    page = Nokogiri::HTML(open("http://matome.naver.jp/odai/#{id}"))
    first_url = page.search('div.mdMTMWidget01ItemImg01')[0].search('a').attribute('href').value
    page = Nokogiri::HTML(open(first_url))
    i=0
    loop {
      p img_url = page.search('div.LyMain').search('img')[0].attribute('src').value
      p next_url = page.search('p.mdMTMEnd01Pagination01').search('a.mdMTMEnd01Pagination01Next').attribute('href').value
      page = Nokogiri::HTML(open(next_url))
      p fileName = File.basename(img_url)
      filePath = dirName + fileName
      FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)
      open(filePath, 'wb') do |output|
        open(img_url) do |data|
          output.write(data.read)
        end
      end
      i += 1
      #とりあえず100枚でブレイク
      break if i == 100
    }
  rescue
  end

  def make_zip(id)
    Zip::Archive.open("./tmp/imgs/#{id}.zip", Zip::CREATE) do |ar|
      Find.find("./tmp/imgs/#{id}") do |path|
        entry = NKF.nkf('-U -s -Lw', path)
        if File.directory?(path)
          ar.add_dir(entry)
        else
          ar.add_file(entry, path)
        end
      end
    end
  rescue
  end

end