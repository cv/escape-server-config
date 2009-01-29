class ShowController < Ramaze::Controller
    require 'open-uri'
    map('/show')
    layout '/page'
    helper :xhtml
    engine :Ezamar
    def index
      @title = "Esc Management Page"
      @content="Don't know what to show!"
      @content += "<br/>Try <a href='/show/environments'>Environments</a>"
      return @content
    end
    def environments
      url = "http://localhost:7000/environments"
      @content = open(url).read
    end
    def applications
      url = "http://localhost:7000/environments/default"
      @content = open(url).read
    end
end