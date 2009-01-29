class ManageController < Ramaze::Controller
    map('/manage')
    layout '/page'
    helper :xhtml
    engine :Ezamar
    def index
      @title = "Esc Management Page"
      @content="Environments: <a href='/show/environments'>show</a>"
    end
end