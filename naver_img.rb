require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'uri'

matome_url = ARGV[0]
page = Nokogiri::HTML(open(matome_url))
title = page.search('h1')[1].text
dirName = "./tmp/imgs/#{title}/"
first_url = page.search('div.mdMTMWidget01ItemImg01')[0].search('a').attribute('href').value
page = Nokogiri::HTML(open(first_url))
loop {
  sleep 3
  p img_url = page.search('div.LyMain').search('img')[0].attribute('src').value
  next_url = page.search('p.mdMTMEnd01Pagination01').search('a.mdMTMEnd01Pagination01Next').attribute('href').value
  page = Nokogiri::HTML(open(next_url))
  fileName = File.basename(img_url)
  filePath = dirName + fileName
  FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)
  open(filePath, 'wb') do |output|
    open(img_url) do |data|
      output.write(data.read)
    end
  end
}
