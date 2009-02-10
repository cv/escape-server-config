#   Copyright 2009 ThoughtWorks
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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
