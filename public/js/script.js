$(function() {

    /* Dead simple validation. */
    $("input[type=text]").bind("keyup", function(event) {

        var required = ["url", "phone"];
        var errors = 0;
        
        /* Required fields. */
        for (i=0;i<required.length;i++) {
            var input = $('input[name="' + required[i] + '"]');
            if ("" === input.val()) {
                ++errors;
            }
        }
                
        if (0 === errors) {
            $("#submit").removeClass("invalid");
        } else {
            $("#submit").addClass("invalid");
        }
        
    });
    
    $("#submit").bind("click", function() { 
        
        if ($(this).hasClass("invalid")) {
            /* Form does not validate. */
        } else {
            
            /* Ask for permissions. */
            FB.ui({ 
                method: "oauth",
                 client_id: settings.client_id
                 //redirect_uri: settings.tab_url
            }, function(response) {
                /* Response contains user_id first time permissions are    */
                /* given. Later it is always false. If permissions are not */
                /* given reponse is also false. */

                /* It seems FB API now returns undefined. */
                console.log(response);
                if (false === response || typeof response === "undefined") {
                    response = {};
                }

                $.extend(response, {
                    url:       $('input[name="url"]').val(),
                    phone:     $('input[name="phone"]').val(),
                });

                console.log(response);

                $.post("/submit", response, function(data) {
                    console.log(data);
                    if ("fail" === data.status) {
                        /* Handle error */
                    } else {
                        console.log(data);
                    }

                }, "json");
            });
            
        }
        
        return false;
    });
    
    $(".share").bind("click", function(event) {
        var wallpost = {
            method: "feed",
            name: "Lorem ipsum dolor sit amet",
            link: settings.tab_url,
            //redirect_uri: settings.tab_url,
            picture: "http://placekitten.com/95/95",
            caption: "Fiant sollemnes in futurum",
            description: "Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum."
        };

        FB.ui(wallpost, function(response) {
            if (response && response.post_id) {
                console.log("OK");
            } else {
                console.log("Fail");
            }
        });
        return false;
    });
    
}); 


    
