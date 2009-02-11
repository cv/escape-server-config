
var EscSidebar = function() {
    var toggleMinus = '/images/minus.jpg';
    var togglePlus = '/images/plus.jpg';

    return {


        getListofEnvsAndApps : function() {
            $.getJSON("/environments", function(data){
                var list = "<ul>";
                $.each(data, function(i, thisEnv){
                    list += ('<li id="' + thisEnv + '"><img src="' + togglePlus + '" alt="collapse this section" > ' + thisEnv);
                    var url = "/environments/" + thisEnv;
                    $.getJSON(url, function(data){
                        list = '<ul class="children"';
                        $.each(data, function(i, thisApp){	
                            list += "<li id='" + thisApp + "'>" + thisApp + "</li>";	
                        });
                        list += "</ul>";
                        $('#hidden #' + thisEnv).append(list);					
                    });
                    list += ('</li>');
                });
                list += "</ul>";
                $('#hidden').html(list);				
            });
        },


        makeCollapsible : function() {
            var subHead = $('.children').parent();
            $('#sidebar').html(subHead)
            //By Default put the Menu in collapsed state
            $('.children').parent().children('ul').slideUp('fast');

            //Expand All Code
            $('.expand').click(function() {
                subHead.children('ul').slideDown('fast');
                $('img', subHead).attr('src', toggleMinus);
            });

            //Contract All Code
            $('.contract').click(function() {
                subHead.attr('src', toggleMinus).children('ul').slideUp('fast');
                $('img', subHead).attr('src', togglePlus);
            });

            //Expand or Contract one particular Nested ul
            $('img', subHead).addClass('clickable').click(function() {
                var toggleSrc = $(this).attr('src');
                if ( toggleSrc == toggleMinus ) {
                    $(this).attr('src', togglePlus).parent().children('ul').slideUp('fast');
                } else{
                    $(this).attr('src', toggleMinus).parent().children('ul').slideDown('fast');
                };
            });
	
            // Click on an app to get stuff in the content pane
            $('#sidebar li li').click(function(appclick){
                var thisEnv = $(this).parents("li:first").attr("id");
                var thisApp = $(this).attr("id");
                var url = "/environments/" + thisEnv + "/" + thisApp;
                $('#content').html(url);		
            });
        },

// End of namespace
    };
}();

$(document).ready(function() {
    EscSidebar.makeCollapsible();
    // Get nested list of environments/apps
    $('#env').click(function(){
        EscSidebar.makeCollapsible();
    })
    EscSidebar.getListofEnvsAndApps();
});

