

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
            $(getTargetLabel(target)).show();
            $(target).show();
        });
    });
}

hideSelector = function(target) {
    $(target).empty();
    $(getTargetLabel(target)).hide();
    $(target).hide();
}

$(document).ready(function(){
    hideSelector('#app_list');

    loadSelectorDataFromUrl('#environments_list', '/environments');

    $("#environments_list").change(function () {
          $("#environments_list option:selected").each(function () {
                loadSelectorDataFromUrl('#app_list', '/environments/' + $(this).text());
          });
    }).change();

});


