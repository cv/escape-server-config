
editPropertiesFor = function(env, app) {
    $('#editor').empty();
    $('#editor').append("Editing /environments/" + env + "/" + app + "<br/><br/>");    

    //$.getJSON("/environments/" + env + "/" + app, function(data) {
    //    $('#editor').append("<pre>");
    //    $.each(data, function(i, item){
    //        alert("Data: " + item);
    //    });
    //    $('#editor').append("</pre>");
    //});
    $.ajax({
        type: "GET",
        url: "/environments/" + env + "/" + app,
        success: function(data, textStatus) {
            $('#editor').append("<pre>");
            $('#editor').append(data);
            $('#editor').append("</pre>");
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
            alert("Error getting properties for app '" + app + "' in environment '" + env + "'");
        },
    });
}

$(document).ready(function() {
    $('#app_list').change(function() {
        var envName = $('#env_list').val();
        var appName = $('#app_list').val();
        if ((envName != null) && (appName != null)) {
            editPropertiesFor(envName, appName);
        }
    }).change();

});


