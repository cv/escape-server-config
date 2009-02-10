
editPropertiesFor = function(env, app) {
    $("#editor").append("Editing /environments/" + env + "/" + app);    
}

$(document).ready(function() {
    $("#editor").append("<h4>Edit</h4>");    

    editPropertiesFor("default", "appname");
});


