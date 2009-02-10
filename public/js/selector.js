

getTargetLabel = function(target) {
    return "label[for='" + target.replace(/#/, '') + "']";
}

loadSelectorDataFromUrl = function(target, url) {
    $(target).empty();

    $.getJSON(url, function(data){
        var options = '';
        $.each(data, function(i, item){
            options += '<option value="' + item + '">' + item + '</option>';
            $(target).html(options);
            $(target + ' option:first').attr('selected', 'selected');
            $(getTargetLabel(target)).show();
            $(target).show();
        });
        $(target).change();
    });
}

hideSelector = function(target) {
    $(target).empty();
    $(getTargetLabel(target)).hide();
    $(target).hide();
}

validateName = function(name) {
    if ((name == "default") || (name == "")) {
        return false;
    } else {
        return true;
    }
}

$(document).ready(function() {
    $('#env_list').change(function() {
        $('#env_list option:selected').each(function() {
            loadSelectorDataFromUrl('#app_list', '/environments/' + $(this).text());
        });
    }).change();

    loadSelectorDataFromUrl('#env_list', '/environments');

    $('#new_env_form').submit(function() {
        var newName = $('#new_env_name').val();
        if (validateName(newName)) {
            $('#new_env_name').val("");
            $.ajax({
                type: "POST",
                url: "/environments/" + newName,
                data: {},
                success: function(data, textStatus) {
                    loadSelectorDataFromUrl('#env_list', '/environments');
                },
                error: function(XMLHttpRequest, textStatus, errorThrown) {
                    alert("Error creating new environment '" + newName);
                },
                });
            
        } else {
            alert("Not going to create new environment called " + newName);
        }
    });

});


