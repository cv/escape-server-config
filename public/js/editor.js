
var EscEditor = function() {
    return {

        validateName : function(name) {
            return true;
        },

		editEnvironment : function(env) {
			$('#editor').empty();
		  	$('#editor').html("<center><h3><b><font size='+1>" + env + "</font></b></center><br />");
		},
        
        editPropertiesFor : function(env, app) {
            $('#editor').empty();
            // $('#editor').append("Editing /environments/" + env + "/" + app + "<br/><br/>");    

            $.ajax({
                type: "GET",
                url: "/environments/" + env + "/" + app,
                success: function(data, textStatus) {
                    $('#editor').html("<center><h3><b><font size='+1'>" + app + "</font></b> in <b><font size='+1'>" + env + "</font></b></center><br />");
                    var table = '<table class="keyvalue" id="key_value_table">';
                    table += ('<tr class="keyvalueheader"><th>Key</th><th>Value</th><th>&nbsp;</th></tr>');
					rowcolour = 1
                    $.each(data.split('\n'), function(i, item) {
						if (rowcolour == 1) { //Alternating row colours
							rowcolour = 0
						} else {
							rowcolour = 1
						}

                        var key = item.slice(0, item.indexOf("="));
                        var value = item.slice(item.indexOf("=") + 1);
						
                        table += ('<tr class="tr-' + rowcolour + '">');
                        table += ("<th>" + key + "</th>");
                        table += ("<td id='" + key + "' class='keyeditbox'>" + value + "</td>");
						table += ("<td class='keydeletebox' id='deletekey-" + key + "'>");
                        table += ("<img src='/images/delete.png'/></td>");
                    });
                    table += "</table>";
                    $('#editor').append(table);
                    $('#key_env_name').val(env);
                    $('#key_app_name').val(app);
                    $.uiTableEdit($('#key_value_table'), {
                        find: ".keyeditbox",
                        editDone: function(newText, oldText, e, td) {
                            var key = td.siblings('th').text();
                            var value = td.text();
                            $.ajax({
                                type: "PUT",
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
    $('#new_key_form').submit(function() {
        var newName = $('#new_key_name').val();
        var envName = $('#key_env_name').val();
        var appName = $('#key_app_name').val();
        if (EscEditor.validateName(newName)) {
            $('#new_key_name').val("");
            $.ajax({
                type: "PUT",
                url: "/environments/" + envName + "/" + appName + "/" + newName,
                data: "",
                complete: function(XMLHttpRequest, textStatus) {
                    EscEditor.editPropertiesFor(envName, appName);
                },
            });
        } else {
            alert("Not going to create new key called " + newName);
        }
    });
});


