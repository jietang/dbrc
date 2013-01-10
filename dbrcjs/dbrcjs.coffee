
window.dbrc_injection = do ->

    class DBRCInjection
        constructor: ->
            @id = Math.floor(Math.random() * 100000000) + 1
            @my_screen = new dbrc.Screen(
                @id
                @show_file 
                 -> console.log('raw handler unimplemented') 
                @display_screen_id
            )
        show_file: (url) =>
            console.log "showing file at #{url}"
            @my_preview = new window.PhotoPreview(
                'filename'
                'fully_qualified_path'
                url  # must be an image, this is what renders
                url  # this is what the "download" link points to
                'display_time'
                'shmodel_link_here'
                )
            window.FilePreviewModal.init [@my_preview]  # this can be a list of PhotoPreviews
            window.FilePreviewModal.show()
        display_screen_id: (screen_id) =>
            jQuery('#main-nav').append("<li style='display: block; padding: 7px; margin-top: 100%; font-size: 14px; color: #1F8CE6; text-decoration: none;'>Screen id:<span style='color: #333; margin-left: 10px'>#{screen_id}</span></li>")
    return {  
        DBRCInjection: DBRCInjection
    }

window.dbrc = do ->
    HOST = 'http://ec2-54-235-229-59.compute-1.amazonaws.com'
    class Screen
        constructor: (device_id, url_handler, raw_handler, display_screen_id) ->
            @url_handler = url_handler
            @raw_handler = raw_handler
            @device_id = device_id
            @screen_id = undefined
            console.log 'initializing screen'
            jQuery.ajax {
                type: "POST"
                url: "#{HOST}/screens/"
                contentType: "application/json; charset=utf-8"
                data: JSON.stringify(
                    device_id: @device_id
                    device_name: "device_#{device_id}"
                    )
                dataType: "json"
                success: (msg) =>
                    if msg.screen_id
                        console.log "starting screen #{msg.screen_id}"
                        @screen_id = msg.screen_id
                        display_screen_id @screen_id
                        @listen_longpoll()
                    else
                        alert "wtf is this?\n#{msg}"
                error: =>
                    alert "something broke"
                }
            
        listen_longpoll: =>
            jQuery.get("#{HOST}/screens/#{@screen_id}",
                (msg) =>
                    reconnectFails = 0
                    if msg.result == 'ok'
                         data = JSON.parse msg.data
                         if data.url
                             @url_handler(data.url)
                         else
                             @raw_handler(data)
                    else if msg.result == 'resubscribe'
                        @listen_longpoll()
                    else
                        console.log 'weird message', msg
                'json').error =>
                    console.log 'dealing with an error'
                    setTimeout @listen_longpoll, 2000

    return Screen: Screen
