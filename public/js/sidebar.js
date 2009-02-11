
var EscSidebar = function() {
    var toggleMinus = '/images/minus.jpg';
    var togglePlus = '/images/plus.jpg';

    return {
        toggleMinus : toggleMinus,

        togglePlus : togglePlus,

        getListofEnvsAndApps : function(target) {
            $.getJSON("/environments", function(envData) {
                var envList = "<ul>";
                $.each(envData, function(i, thisEnv) {
                    envList += ('<li id="' + thisEnv + '_env"><img src="' + togglePlus + '" alt="collapse this section" class="expander" class="clickable"> ' + thisEnv);
                    var url = "/environments/" + thisEnv;
                    $.getJSON(url, function(appData) {
                        appList = '<ul class="children"';
                        $.each(appData, function(i, thisApp) {
                            appList += "<li id='" + thisApp + "_app'>" + thisApp + "</li>";
                        });
                        appList += '<li><form id="' + thisEnv + '_new_app_form" class="new_app_form" action="javascript:void(0);"><input type="text" id="new_app_name"/></form></li>';
                        appList += "</ul>";
                        $(target + ' #' + thisEnv + '_env').append(appList);
                        // Collapse all the childrens...
                        $('.children').parent().children('ul').slideUp('fast');
                        $(target + " .new_app_form").submit(EscSidebar.createNewApp);
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
            // TODO: Put some propper rules in here
            if ((name == "default") || (name == "")) {
                return false;
            } else {
                return true;
            }
        },

        validateAppName : function(name) {
            // TODO: Put some propper rules in here
            return true;
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

        createNewApp : function() {
            var envName = $(this).attr("id").replace('_new_app_form', '');
            var newName = $(this).find(":input").val();
            if (EscSidebar.validateAppName(newName)) {
                $(this).find(":input").val("");
                $.ajax({
                    type: "POST",
                    url: "/environments/" + envName + "/" + newName,
                    data: {},
                    success: function(data, textStatus) {
                        EscSidebar.getListofEnvsAndApps('#sidebar');
                    },
                    error: function(XMLHttpRequest, textStatus, errorThrown) {
                        alert("Error creating new app '" + newName);
                    },
                });
            } else {
                alert("Not going to create new app called " + newName);
            }
        },

// End of namespace
    };
}();

$(document).ready(function() {
    $('#refresh_env').click(function() {
        EscSidebar.getListofEnvsAndApps('#sidebar');
    })

    //Expand All Code
    $('.expand').live("click", function() {
        $('.children').slideDown('fast');
        $('img', $('.children').parent()).attr('src', EscSidebar.toggleMinus);
    });

    //Contract All Code
    $('.contract').live("click", function() {
        $('.children').parent().attr('src', EscSidebar.toggleMinus).children('ul').slideUp('fast');
        $('img', $('.children').parent()).attr('src', EscSidebar.togglePlus);
    });

    // Click on an app to get stuff in the content pane
    $('#sidebar li li').live("click", function() {
        var thisEnv = $(this).parents("li:first").attr("id").replace('_env', '');
        var thisApp = $(this).attr("id").replace('_app', '');
        if ((thisApp != null) && (thisApp != "")) {
            EscEditor.editPropertiesFor(thisEnv, thisApp);
            $('#new_key').show();
            $('#editor').show();
        } else {
            $('#new_key').hide();
            $('#editor').hide();
        };
    });

    //Expand or Contract one particular Nested ul
    $('.expander').live("click", function() {
        var toggleSrc = $(this).attr('src');
        if ( toggleSrc == EscSidebar.toggleMinus ) {
            $(this).attr('src', EscSidebar.togglePlus).parent().children('ul').slideUp('fast');
        } else{
            $(this).attr('src', EscSidebar.toggleMinus).parent().children('ul').slideDown('fast');
        };
    });

    EscSidebar.getListofEnvsAndApps('#sidebar');
    $('#new_key').hide();
    $('#editor').hide();

/* Bloody droppables!!!
    $('#floater').draggable({ 
        revert: true,
        start: function(event, ui) {
            $(this).find('p').html("Start");
        },
        stop: function(event, ui) {
            $(this).find('p').html("Stop");
        },
        drag: function(event, ui) {
            $(this).find('p').html("Drag");
        },
        
    });
    $('#floater').find('p').html("Loaded Drag");
    $('#drop').droppable({ 
        activate: function(event, ui) {
            $(this).find('p').html("Activate");
        },
        deactivate: function(event, ui) {
            $(this).find('p').html("Deactivate");
        },
        over: function(event, ui) {
            $(this).find('p').html("Over");
        },
        out: function(event, ui) {
            $(this).find('p').html("Out");
        },
        drop: function(event, ui) {
            $(this).find('p').html("Drop");
            $('#drop').find('p').html("Hard Drop");
        },
    });
    $('#drop').find('p').html("Loaded Drop");
*/
});

