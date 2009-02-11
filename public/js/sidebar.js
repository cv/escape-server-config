
var EscSidebar = function() {
    var toggleMinus = '/images/minus.jpg';
    var togglePlus = '/images/plus.jpg';

    return {

        makeCollapsible : function(target, subHead) {
            //By Default put the Menu in collapsed state
            $('.children').parent().children('ul').slideUp('fast');

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
            $(target + ' li li').click(function(appclick) {
                var thisEnv = $(this).parents("li:first").attr("id").replace('_env', '');
                var thisApp = $(this).attr("id").replace('_app', '');
                var url = "/environments/" + thisEnv + "/" + thisApp;
                EscEditor.editPropertiesFor(thisEnv, thisApp);
            });
        },

        contract : function(target) {
            target.attr('src', toggleMinus).children('ul').slideUp('fast');
            $('img', target).attr('src', togglePlus);
        },

        expand : function(target) {
            target.children('ul').slideDown('fast');
            $('img', target).attr('src', toggleMinus);
        },

        getListofEnvsAndApps : function(target) {
            $.getJSON("/environments", function(envData) {
                var envList = "<ul>";
                $.each(envData, function(i, thisEnv) {
                    envList += ('<li id="' + thisEnv + '_env"><img src="' + togglePlus + '" alt="collapse this section" > ' + thisEnv);
                    var url = "/environments/" + thisEnv;
                    $.getJSON(url, function(appData) {
                        appList = '<ul class="children"';
                        $.each(appData, function(i, thisApp) {
                            appList += "<li id='" + thisApp + "_app'>" + thisApp + "</li>";
                        });
                        appList += "</ul>";
                        $(target + ' #' + thisEnv + '_env').append(appList);
                    });
                    envList += ('</li>');
                });
                envList += '<li><form id="new_env_form" action="javascript:void(0);"><input type="text" id="new_env_name" name="new_env_name"/></form></li>';
                envList += "</ul>";
                $(target).html(envList);
                $(target + " #new_env_form").submit(EscSidebar.createNewEnv);
            });
        },

        validateEnvName : function(name) {
            if ((name == "default") || (name == "")) {
                return false;
            } else {
                return true;
            }
        },

        createNewEnv : function() {
            var newName = $('#new_env_name').val();
            if (EscSidebar.validateEnvName(newName)) {
                $('#new_env_name').val("");
                $.ajax({
                    type: "POST",
                    url: "/environments/" + newName,
                    data: {},
                    success: function(data, textStatus) {
                        EscSidebar.getListofEnvsAndApps('#sidebar');
                    },
                    error: function(XMLHttpRequest, textStatus, errorThrown) {
                        alert("Error creating new environment '" + newName);
                    },
                });
            } else {
                alert("Not going to create new environment called " + newName);
            }
        },

// End of namespace
    };
}();

$(document).ready(function() {
    // Get nested list of environments/apps
    $('#show_env').click(function() {
        var subHead = $('.children').parent();
        EscSidebar.makeCollapsible('#sidebar', subHead);
    })

    //Expand All Code
    $('.expand').live("click", function() {
        $(this).children('ul').slideDown('fast');
        $('img', $(this)).attr('src', toggleMinus);
    });

    //Contract All Code
    $('.contract').live("click", function() {
        $(this).attr('src', toggleMinus).children('ul').slideUp('fast');
        $('img', $(this)).attr('src', togglePlus);
    });

    EscSidebar.getListofEnvsAndApps('#sidebar');
});

