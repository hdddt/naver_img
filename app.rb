require 'sinatra'
require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'uri'
require 'zipruby'
require 'find'
require 'nkf'

get '/' do
  erb :index
end

get '/:id' do
  make_zip(params[:id])
  send_file("imgs/#{params[:id]}.zip")
  redirect "/"
end

post '/give_me_img' do
  id = params[:url].gsub("http://","").gsub("matome.naver.jp/odai/","")
  get_imgs(id)
  redirect "/#{id}"
end

helpers do
  def get_imgs(id)
    page = Nokogiri::HTML(open("http://matome.naver.jp/odai/#{id}"))
    first_url = page.search('div.mdMTMWidget01ItemImg01')[0].search('a').attribute('href').value
    page = Nokogiri::HTML(open(first_url))
    i=0
    loop {
      p img_url = page.search('div.LyMain').search('img')[0].attribute('src').value
      p next_url = page.search('p.mdMTMEnd01Pagination01').search('a.mdMTMEnd01Pagination01Next').attribute('href').value
      page = Nokogiri::HTML(open(next_url))
      p fileName = File.basename(img_url)
      dirName = "./imgs/#{id}/"
      filePath = dirName + fileName
      FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)
      open(filePath, 'wb') do |output|
        open(img_url) do |data|
          output.write(data.read)
        end
      end
      i += 1
    }
  rescue
  end
  def make_zip(id)
    Zip::Archive.open("imgs/#{id}.zip", Zip::CREATE) do |ar|
      Find.find("imgs/#{id}") do |path|
        entry = NKF.nkf('-U -s -Lw', path)
        if File.directory?(path)
          ar.add_dir(entry)
        else
          ar.add_file(entry, path)
        end
      end
    end
  end
end