
var EscEditor = function() {
    return {

        validateName : function(name) {
            return true;
        },
        
        editPropertiesFor : function(env, app) {
            $('#editor').empty();
            $('#editor').append("Editing /environments/" + env + "/" + app + "<br/><br/>");    

            $.ajax({
                type: "GET",
                url: "/environments/" + env + "/" + app,
                success: function(data, textStatus) {
                    var table = '<table border="1" id="key_value_table"><tr><th>Key</th><th>Value</th></tr>';
                    $.each(data.split('\n'), function(i, item) {
                        table += "<tr>";
                        $.each(item.split('=', 2), function(j, jtem) {
                            var tag = (j % 2) ? "td" : "th";
                            table += "<" + tag + ">" + jtem + "</" + tag + ">";
                        });
                    });
                    table += "</table>";
                    $('#editor').html(table);
                    $.uiTableEdit($('#key_value_table'), {
                        editDone: function(newText, oldText, e, td) {
                            var key;
                            var value;
                            $.each(td.siblings().andSelf(), function(i, item) {
                                if (i % 2) {
                                    value = $(item).text();
                                } else {
                                    key = $(item).text();
                                }
                            });
                            $.ajax({
                                type: "POST",
                                url: "/environments/" + env + "/" + app + "/" + key,
                                data: value,
                                complete: function(XMLHttpRequest, textStatus) {
                                    $('#app_list').change();  
                                },
                            });
                        },
                    });
                },
                error: function(XMLHttpRequest, textStatus, errorThrown) {
                    alert("Error getting properties for app '" + app + "' in environment '" + env + "'");
                },
            });
        },

// End of namespace
    };
}();

$(document).ready(function() {
    $('#app_list').change(function() {
        var envName = $('#env_list').val();
        var appName = $('#app_list').val();
        if ((envName != null) && (appName != null)) {
            EscEditor.editPropertiesFor(envName, appName);
        }
    }).change();

    $('#new_key_form').submit(function() {
        var newName = $('#new_key_name').val();
        if (EscEditor.validateName(newName)) {
            $('#new_key_name').val("");
            $.ajax({
                type: "POST",
                url: "/environments/" + "/" + $('#env_list').val() + "/" + $('#app_list').val() + "/" + newName,
                data: "default value",
                complete: function(XMLHttpRequest, textStatus) {
                    $('#app_list').change();
                },
            });
        } else {
            alert("Not going to create new environment called " + newName);
        }
    });
});


