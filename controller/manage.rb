class ManageController < Ramaze::Controller
    map('/manage')
    layout '/page'
    helper :xhtml
    engine :Ezamar
    def index
      @title = "Esc Management Page"
    end
end