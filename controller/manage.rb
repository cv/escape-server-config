class ManageController < Ramaze::Controller
    map('/manage')
    layout '/page'
    helper :xhtml
    engine :Ezamar
    def index
      @title = "Esc Management Page"
      @content="<ul>"
      @content+="<li>Environments: <a href='/show/environments'>show</a></li>"
      @content+="<li>Applications: <a href='/show/applications'>show</a></li>"
      @content+="</ul>"
    end
end