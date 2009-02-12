
var EscSidebar = function() {
    var toggleMinus = '/images/minus.jpg';
    var togglePlus = '/images/plus.jpg';

    return {
        toggleMinus : toggleMinus,

        togglePlus : togglePlus,

        getListofEnvsAndApps : function(target) {
            $.getJSON("/environments", function(envData) {
                var envList = "<ul class='env_list'>";
                $.each(envData, function(i, thisEnv) {
                    var toggleState;
                    if ($('#sidebar').data(thisEnv + '_expanded')) {
                        toggleState = toggleMinus;
                    } else {
                        toggleState = togglePlus;
                    };
                    envList += ('<li id="' + thisEnv + '_env" class="environment"><img src="' + toggleState + '" alt="collapse this section" class="expander" class="clickable"> ' + thisEnv);
                    var url = "/environments/" + thisEnv;
                    $.getJSON(url, function(appData) {
                        var myEnv = thisEnv;
                        appList = '<ul class="app_list"';
                        $.each(appData, function(i, thisApp) {
                            appList += "<li id='" + thisApp + "_app' class='app'>" + thisApp + "</li>";
                        });
                        appList += '<li><form id="' + myEnv + '_new_app_form" class="new_app_form" action="javascript:void(0);"> +app:<input type="text" id="new_app_name"/></form></li>';
                        appList += "</ul>";
                        $(target + ' #' + myEnv + '_env').append(appList);
                        if (! $('#sidebar').data(myEnv + '_expanded')) {
                            // Collapse all the childrens...
                            $('#' + myEnv + '_env').children('ul').slideUp('fast');
                        } 
                        $(target + " .new_app_form").submit(EscSidebar.createNewApp);
                    });
                    envList += ('</li>');
                });
                envList += '<li><form id="new_env_form" action="javascript:void(0);"> +Env:<input type="text" id="new_env_name" name="new_env_name"/></form></li>';
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
                        alert("Error creating new environment '" + newName +"'");
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
                        alert("Error creating new app '" + newName + "'");
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
        $('#sidebar > ul > li > ul').slideDown('fast');
        $('img', $('#sidebar > ul > li')).attr('src', EscSidebar.toggleMinus);
        // Loop through all envs, set collapsed = true
        $.each($('#sidebar > ul > li'), function(i, item) { 
            var myEnv = $(item).attr('id').replace('_env', '');
            $('#sidebar').data(myEnv + '_expanded', true);
        });
    });

    //Contract All Code
    $('.contract').live("click", function() {
        $('#sidebar > ul > li > ul').slideUp('fast');
        $('img', $('#sidebar > ul > li')).attr('src', EscSidebar.togglePlus);
        // Loop through all envs, set collapsed = true
        $.each($('#sidebar > ul > li'), function(i, item) { 
            var myEnv = $(item).attr('id').replace('_env', '');
            $('#sidebar').data(myEnv + '_expanded', false);
        });
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
        var thisEnv = $(this).parent().attr('id').replace('_env', '');
        if ( toggleSrc == EscSidebar.toggleMinus ) {
            $('#sidebar').data(thisEnv + '_expanded', false);
            $(this).attr('src', EscSidebar.togglePlus).parent().children('ul').slideUp('fast');
        } else{
            $('#sidebar').data(thisEnv + '_expanded', true);
            $(this).attr('src', EscSidebar.toggleMinus).parent().children('ul').slideDown('fast');
        };
    });

    EscSidebar.getListofEnvsAndApps('#sidebar');
    $('#new_key').hide();
    $('#editor').hide();
});

