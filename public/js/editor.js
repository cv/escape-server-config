
var EscEditor = function() {
    return {

        validateName : function(name) {
            return true;
        },

        editUsers : function() {
			$('#editor').empty();
            $('#editor').append("<center><h3>Users</h3></center><br />");
            $('#editor').append("<ul id='user_list'></ul>");

            $.getJSON("/user",
                function(data) {
                    $.each(data, function(i, name) {
                        if (name != "nobody") {
                            $('#user_list').append("<li class='edit_user'>" + name + "</li>");
                        };
                    });
                }
            );
        },

        takeOwnership : function(env) {
			$.ajax({
                type: "POST",
                url: "/owner/" + env,
				success: function(data, textStatus){
                    alert("Congratulations, you now own the environment '" + env + "'");
                    EscEditor.editEnvironment(env);
				},
			});
        },

        releaseOwnership : function(env) {
			$.ajax({
                type: "DELETE",
                url: "/owner/" + env,
				success: function(data, textStatus){
                    alert("Released ownership of environment '" + env + "'");
                    EscEditor.editEnvironment(env);
				},
			});
        },

		editEnvironment : function(env) {
			$('#editor').empty();
		  	$('#editor').html("<center><h3><b><font size='+1>" + env + "</font></b></center><br />");
			$('#editor').append("<div id='owner'></div>");
			$.ajax({
	                type: "GET",
	                url: "/owner/" + env,
					success: function(data, textStatus){
						$('#owner').append("<b>Owner</b>: " + data + "<br />");
				},
			});

            if (env != "default") { 
			    $('#editor').append("<div id='pub_key'></div>");
			    $('#editor').append("<div id='priv_key'></div>");
                $('#editor').append("<input type='button' class='own' value='Take Ownership' onClick='EscEditor.takeOwnership(\"" + env + "\");'/>");
                $('#editor').append("<input type='button' class='disown' value='Release Ownership' onClick='EscEditor.releaseOwnership(\"" + env + "\");'/>");
			    $.ajax({
                    type: "GET",
                    url: "/crypt/" + env + "/public",
				    success: function(data, textStatus){
					    $('#pub_key').append("<b>Public key</b>:<br/><pre>" + data + "</pre><br />");
				    },
			    });
			    $.ajax({
	                type: "GET",
	                url: "/crypt/" + env + "/private",
					success: function(data, textStatus){
						$('#priv_key').append("<b>Private key</b>:<br/><pre>" + data + "</pre><br />");
				    },
			    });
            }
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
                        // TODO: Only show delete if we are default env or this is an override value
                        table += ("<img class='keydelete' src='/images/delete.png'/>");
                        table += ("</td>");

						table += ("<td class='edittablebutton'>");
                        // TODO: Only show encrypt if this is overried and not encrypted already
                        table += ("<img class='keyencrypt' src='/images/encrypt.png'/></td>");
                        table += ("</td>");
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
						var thisValue = $(this).parent().siblings(".keyeditbox").text();

				        if ((thisKey != null) && (thisKey != "")) {
							// Encrypt the key
							$.ajax({
				                type: "PUT",
				                url: "/environments/" + env + "/" + app + "/" + thisKey + "?encrypt",
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

        submitUserDetails : function() {
            $('#new_user_errors').empty();

            var validated = true;
            var userName = $('#new_user_name').val();
            var userEmail = $('#new_user_email').val();
            var userPass1 = $('#new_user_pass1').val();
            var userPass2 = $('#new_user_pass2').val();

            if ((userName == null) || (userName == "") || (userName == "User Name")) {
                $('#new_user_errors').append("<font color='red'>Must specify username</font><br/>");
                validated = false;
            };

            if ((userEmail == null) || (userEmail == "") || (userEmail == "User Email")) {
                $('#new_user_errors').append("<font color='red'>Must specify email address</font><br/>");
                validated = false;
            };

            if ((userPass1 == null) || (userPass1 == "")) { 
                $('#new_user_errors').append("<font color='red'>Blank passwords not allowed</font><br/>");
                validated = false;
            };

            if (userPass2 == null) { userPass2 = ""; };

            if (userPass1 != userPass2) {
                $('#new_user_errors').append("<font color='red'>Password missmatch</font><br/>");
                validated = false;
            };

            if (! validated) {
                return;
            } else {
                $('#new_user_name').val("");
                $('#new_user_email').val("");
                $('#new_user_pass1').val("");
                $('#new_user_pass2').val("");
                $('#new_user_errors').html("<font color='green'>Creating user " + userName + "...</font><br/>");
                $.ajax({
                    type: "POST",
                    url: "/user/" + userName,
                    data: "email=" + userEmail + "&password=" + userPass1,
                    success: function(XMLHttpRequest, textStatus) {
                        $('#new_user_errors').append("<font color='green'>done</font><br/>");
                        EscEditor.clearNewUserForm();
                        EscEditor.editUsers();
                    },
                    error: function(XMLHttpRequest, textStatus, errorThrown) {
                        $('#new_user_errors').append("<font color='red'>Error: " + XMLHttpRequest.responseText + "</font><br/>");
                    },
                });
            };
        },

        clearNewUserForm : function() {
            $('#new_user_name').focus();
            $('#new_user_name').blur();
            $('#new_user_email').focus();
            $('#new_user_email').blur();
            $('#new_user_pass1').focus();
            $('#new_user_pass1').blur();
            $('#new_user_pass2').focus();
            $('#new_user_pass2').blur();
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
        EscEditor.submitUserDetails()
    });

    $(".edit_user").live("click", function() {
        $.getJSON("/user/" + $(this).text(), 
            function(data) {
                $('#new_user_name').val(data.name);
                $('#new_user_email').val(data.email);
                $('#new_user_pass1').val("");
                $('#new_user_pass2').val("");
            }
        );
    });
});


