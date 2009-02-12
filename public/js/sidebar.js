
var EscSidebar = function() {
    var toggleMinus = '/images/minus.jpg';
    var togglePlus = '/images/plus.jpg';
    var newEnvLabel = '+env:';
    var newAppLabel = '+app:';

    return {
        toggleMinus : toggleMinus,
        togglePlus : togglePlus,
        newEnvLabel : newEnvLabel,
        newAppLabel : newAppLabel,

        getListofEnvsAndApps : function() {
            $.getJSON("/environments", function(envData) {
                var envList = "<ul class='env_list'>";
                $.each(envData, function(envId, thisEnv) {
                    var toggleState;
                    if ($('#sidebar').data(thisEnv + '_expanded')) {
                        toggleState = toggleMinus;
                    } else {
                        toggleState = togglePlus;
                    };
                    envList += ('<li class="environment"><img src="' + toggleState + '" alt="collapse this section" class="expander" class="clickable"><span>' + thisEnv + '</span>');
                    var url = "/environments/" + thisEnv;
                    $.getJSON(url, function(appData) {
                        var myEnv = thisEnv;
                        appList = '<ul class="app_list"';
                        $.each(appData, function(appId, thisApp) {
                            appList += "<li class='app'>" + thisApp + "</li>";
                        });
                        appList += '<li><form id="' + myEnv + '_new_app_form" class="new_app_form" action="javascript:void(0);">' + newAppLabel + '<input type="text" id="new_app_name"/></form></li>';
                        appList += "</ul>";
                        var envObj = $('#sidebar .environment:eq(' + envId + ')');
                        envObj.append(appList);
                        if (! $('#sidebar').data(myEnv + '_expanded')) {
                            envObj.children('ul').slideUp('fast');
                        } 
                        $('#sidebar' + " .new_app_form").submit(EscSidebar.createNewApp);
                    });
                    envList += ('</li>');
                });
                envList += '<li><form id="new_env_form" action="javascript:void(0);">' + newEnvLabel + '<input type="text" id="new_env_name" name="new_env_name"/></form></li>';
                envList += "</ul>";
                $('#sidebar').html(envList);
                $('#sidebar' + " #new_env_form").submit(EscSidebar.createNewEnv);
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
                        EscSidebar.getListofEnvsAndApps();
                    },
                    error: function(XMLHttpRequest, textStatus, errorThrown) {
                        alert("Error creating new environment '" + newName +"': " + XMLHttpRequest.responseText);
                    },
                });
            } else {
                alert("Invalid environment name '" + newName + "'. Valid characters are A-Z, a-z, 0-9, - and _");
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
                        EscSidebar.getListofEnvsAndApps();
                    },
                    error: function(XMLHttpRequest, textStatus, errorThrown) {
                        alert("Error creating new application '" + newName +"': " + XMLHttpRequest.responseText);
                    },
                });
            } else {
                alert("Invalid application name '" + newName + "'. Valid characters are A-Z, a-z, 0-9, - and _");
            }
        },

// End of namespace
    };
}();

$(document).ready(function() {
    $('#refresh_env').click(function() {
        EscSidebar.getListofEnvsAndApps();
    })

    //Expand All Code
    $('.expand').live("click", function() {
        $('#sidebar > ul > li > ul').slideDown('fast');
        $('img', $('#sidebar > ul > li')).attr('src', EscSidebar.toggleMinus);
        // Loop through all envs, set collapsed = true
        $.each($('#sidebar > ul > li'), function(i, item) { 
            var myEnv = $(item + " span").text();
            $('#sidebar').data(myEnv + '_expanded', true);
        });
    });

    //Contract All Code
    $('.contract').live("click", function() {
        $('#sidebar > ul > li > ul').slideUp('fast');
        $('img', $('#sidebar > ul > li')).attr('src', EscSidebar.togglePlus);
        // Loop through all envs, set collapsed = true
        $.each($('#sidebar > ul > li'), function(i, item) { 
            var myEnv = $(item + " span").text();
            $('#sidebar').data(myEnv + '_expanded', false);
        });
    });

    // Click on an app to get stuff in the content pane
    $('#sidebar li li').live("click", function() {
        var thisEnv = $(this).parent().siblings("span").text();
        var thisApp = $(this).text();

        if ((thisApp != null) && (thisApp != "") && (thisApp != EscSidebar.newAppLabel)) {
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
        var thisEnv = $(this).siblings("span").text();

        if ( toggleSrc == EscSidebar.toggleMinus ) {
            $('#sidebar').data(thisEnv + '_expanded', false);
            $(this).attr('src', EscSidebar.togglePlus).parent().children('ul').slideUp('fast');
        } else{
            $('#sidebar').data(thisEnv + '_expanded', true);
            $(this).attr('src', EscSidebar.toggleMinus).parent().children('ul').slideDown('fast');
        };
    });

    EscSidebar.getListofEnvsAndApps();
    $('#new_key').hide();
    $('#editor').hide();
});

