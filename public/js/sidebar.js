// Build list of all envs/apps
getListofEnvsAndApps = function() {
	$.getJSON("/environments", function(data){
		var list = "<ul>";
		$.each(data, function(i, thisEnv){
			list += ('<li id="' + thisEnv + '">' + thisEnv + '</li>');
			var url = "/environments/" + thisEnv;
				$.getJSON(url, function(data){
					var list = "<ul>";
					$.each(data, function(i, thisApp){	
						list += "<li id='" + thisApp + "'>" + thisApp + "</li>";	
					});
					list += "</ul>";
					$('#sidebar #' + thisEnv).append(list);
					$('#sidebar li li').click(function(appclick){
						var thisEnv = $(this).parents("li:first").attr("id");
						var thisApp = $(this).attr("id");
						var url = "/environments/" + thisEnv + "/" + thisApp;
						$('#content').html(url);		
					});
				});
		});
		list += "</ul>";
		$('#sidebar').html(list);				
	});
}