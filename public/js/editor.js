
var EscEditor = function() {
    return {

        validateName : function(name) {
            return true;
        },

        editUsers : function() {
			$('#editor').empty();
            var userEditor = "";

		  	userEditor += "<center><h3><b><font size='+1>Users</font></b></center><br />";


            userEditor += "";

		  	$('#editor').html(userEditor);
        },

		editEnvironment : function(env) {
			$('#editor').empty();
		  	$('#editor').html("<center><h3><b><font size='+1>" + env + "</font></b></center><br />");
			$('#editor').append("<div id='crypto'></div>");
			$.ajax({
                type: "GET",
                url: "/crypt/" + env + "/public",
				success: function(data, textStatus){
					var pubkey = data.replace("-----BEGIN RSA PUBLIC KEY-----","");
					pubkey = pubkey.replace("-----END RSA PUBLIC KEY-----","");						 
					$('#crypto').append("<b>Public key</b>:" + pubkey + "<br />");
				},
			});
			$.ajax({
	                type: "GET",
	                url: "/crypt/" + env + "/private",
					success: function(data, textStatus){
						var privkey = data.replace("-----BEGIN RSA PRIVATE KEY-----","");
						privkey = privkey.replace("-----END RSA PRIVATE KEY-----","");						 
						$('#crypto').append("<b>Private key</b>:" + privkey + "<br />");
				},
			});
			
		},
        
        editPropertiesFor : function(env, app) {
            $('#editor').empty(); 

            $.ajax({
                type: "GET",
                url: "/environments/" + env + "/" + app,
                success: function(data, textStatus) {
                    $('#editor').html("<center><h3><b><font size='+1'>" + app + "</font></b> in <b><font size='+1'>" + env + "</font></b></center><br />");
                    var table = '<table class="keyvalue" id="key_value_table">';
                    table += ('<tr class="keyvalueheader"><th>Key</th><th>Value</th><th>&nbsp;</th><th>&nbsp;</th></tr>');
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
						table += ("<td class='edittablebutton'>");
                        table += ("<img class='keydelete' src='/images/delete.png'/></td>");
						table += ("<td class='edittablebutton'>");
                        table += ("<img class='keyencrypt' src='/images/encrypt.png'/></td>");
                    });
                    table += "</table>";
                    $('#editor').append(table);
                    $('#key_env_name').val(env);
                    $('#key_app_name').val(app);
				    // Click on a key delete button
				    $('.keydelete').click(function() {
						var thisKey = $(this).parent().siblings("th").text();
						var confirmation = confirm('Are you sure you want to delete ' + thisKey + '?');

				        if ((confirmation) && (thisKey != null) && (thisKey != "")){
							// Delete the key
							$.ajax({
				                type: "DELETE",
				                url: "/environments/" + env + "/" + app + "/" + thisKey,
				                data: {},
				                success: function(data, textStatus) {
									$('#editor').empty(); 
				                    EscSidebar.showEditor(env, app);
				                },
				                error: function(XMLHttpRequest, textStatus, errorThrown) {
				                    alert("Error deleting '" + thisKey +"': " + XMLHttpRequest.responseText);
				                },
				            })
				        };
				    });
					// Click on a key encrypt button
					$('.keyencrypt').click(function() {
						var thisKey = $(this).parent().siblings("th").text();
						var thisValue = $(this).parent().siblings("td#keyeditbox").text();
						
				        if ((thisKey != null) && (thisKey != "")) {
							// Encrypt the key
							$.ajax({
				                type: "PUT",
				                url: "/environments/" + env + "/" + app + "/" + thisKey,
				                data: thisValue,
				                success: function(data, textStatus) {
									$('#editor').empty(); 
				                    EscSidebar.showEditor(env, app);
				                },
				                error: function(XMLHttpRequest, textStatus, errorThrown) {
				                    alert("Error encrypting '" + thisKey +"': " + XMLHttpRequest.responseText);
				                },
				            })
				        };
				    });
					
					
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

    $('#new_user_form').submit(function() {
//        var userName = $('#key_user_name').val();
//        var userEmail = $('#key_user_email').val();
//        if (EscEditor.validateName(newName)) {
//            $('#new_key_name').val("");
//            $.ajax({
//                type: "PUT",
//                url: "/environments/" + envName + "/" + appName + "/" + newName,
//                data: "",
//                complete: function(XMLHttpRequest, textStatus) {
//                    EscEditor.editPropertiesFor(envName, appName);
//                },
//            });
//        } else {
//            alert("Not going to create new key called " + newName);
//        }
    });
});


