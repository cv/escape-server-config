class ShowController < Ramaze::Controller
    require 'open-uri'
    require 'json'
    map('/show')
#    layout '/page'
#    helper :xhtml
#    engine :Ezamar
    def index
      @title = "Esc Management Page"
      @content="Don't know what to show!"
      @content += "<br/>Try <a href='/show/environments'>Environments</a>"
      return @content
    end
    def environments(env = nil, app = nil)
      url = "http://localhost:7000/environments/#{env}/#{app}"
      return json_to_list(url)
    end
    def applications
      @sidebar = json_to_list("http://localhost:7000/environments/default")
      @content = ""
    end
    
    private
    def json_to_list(url)
      everything = JSON.parse(open(url).read)
      retval = "<ul>"
      everything.each do |single_thing|
        retval << "<li>#{single_thing}</li>"
      end
      retval << "</ul>"
      return retval
    end
  
end