# frozen_string_literal: true

require 'compiled-opal'
require 'polyfill'
require 'snabberb'
require 'set'

class Application < Snabberb::Component
  def render
		@interval = "off"
    @video = h(
      :video,
      attrs: { autoplay: true},
      style: { width: '320px', height: '240px' },
    )
    @canvas = h(
      :canvas,
      style: { width: '320px', height: '240px' },
    )

    onload = lambda do
      %x{
        video_elm = #{@video.JS['elm']}
        navigator
          .mediaDevices
          .getUserMedia({audio: false, video: true})
          .then(function(stream) {
          video_elm.srcObject = stream
        })
          .catch(function(err) {
          console.log(err)
        })
      }
    end

    stop_interval = lambda do
      puts "clicked, stop interval"
      @interval = "off"
      %x{
      clearInterval(#{@interval_id})
      }
    end

    start_interval = lambda do
      puts "clicked, start interval"
      @interval = "on"
      @interval_id = %x{
      setInterval(#{-> {take_image}},3000)
      }
    end

    save_image = lambda do
      puts "clicked"
      %x{
      var image = canvas_elm.toDataURL('image/png')
      window.location.href=image;
}
    end

    props = {
      style: { width: '100px' },
      hook: { insert: onload},
      attrs: { id: "application_id"},
    }
    h(:div, props, [
      @video,
      @canvas,
      h(:button, {on: {click: -> {take_image}}}, "single take picture"),
      h(:button, {on: {click: start_interval}}, "start interval images"),
      h(:button, {on: {click: stop_interval}}, "stop interval images"),
      h(:button, {on: {click: save_image}}, "save picture"),
    ])
  end

  def take_image
    puts "take image",@interval
    %x{

      video_elm = #{@video.JS['elm']}
      canvas_elm = #{@canvas.JS['elm']}

      stream = video_elm.srcObject
      console.log(stream.getVideoTracks()[0].getSettings().height)
      console.log(stream.getVideoTracks()[0].getSettings().width)

      height = stream.getVideoTracks()[0].getSettings().height
      width = stream.getVideoTracks()[0].getSettings().width

      canvas_elm.width = width
      canvas_elm.height = height
      var context = canvas_elm.getContext('2d')
      context.drawImage(video_elm,0,0,width,height)

}
  end

end

class Index < Snabberb::Layout
  def render
    h(:html, [
      h(:head, [
        h(:meta, props: { charset: 'utf-8' }),
        h(:title, 'Display Webcam Stream'),
      ]),
      h(:body, [
        @application,
        h(:div, props: { innerHTML: @javascript_include_tags }),
        h(:script, props: { innerHTML: @attach_func }),
      ]),
    ])
  end
end

