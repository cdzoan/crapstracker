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
    @calibration_canvas = h(
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

    take_calibration_image = lambda do
      puts "clicked, take calibration image"
      %x{
        video_elm = #{@video.JS['elm']}
        calibration_canvas_elm = #{@calibration_canvas.JS['elm']}

        stream = video_elm.srcObject
        console.log(stream.getVideoTracks()[0].getSettings().height)
        console.log(stream.getVideoTracks()[0].getSettings().width)

        height = stream.getVideoTracks()[0].getSettings().height
        width = stream.getVideoTracks()[0].getSettings().width

        calibration_canvas_elm.width = width
        calibration_canvas_elm.height = height
        var context = calibration_canvas_elm.getContext('2d')
        context.drawImage(video_elm,0,0,width,height)

        var image = calibration_canvas_elm.toDataURL('image/png').split("data:image/png;base64,")[1]

        var calibration_imageData = new FormData();
        calibration_imageData.append('image',image)

        var xhr = new XMLHttpRequest();
        xhr.onprogress = function (e) {
        console.log("progress")
        };

        xhr.onload = function (e) {
        console.log("load")
        };

        xhr.onerror = function (e) {
        console.log("error")
        };

        xhr.open("post", "/upload_calibration_image", true);

        xhr.send(calibration_imageData);
        console.log(image.length)
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

    props = {
      style: { width: '100px' },
      hook: { insert: onload},
      attrs: { id: "application_id"},
    }
    h(:div, props, [
      h(:button, {on: {click: take_calibration_image}}, "calibrate"),
      h(:button, {on: {click: -> {take_image}}}, "single take picture"),
      h(:button, {on: {click: start_interval}}, "start interval images"),
      h(:button, {on: {click: stop_interval}}, "stop interval images"),
      @video,
      @calibration_canvas,
      @canvas,
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

      var image = canvas_elm.toDataURL('image/png').split("data:image/png;base64,")[1]

      var imageData = new FormData();
      imageData.append('image',image)

      var xhr = new XMLHttpRequest();
      xhr.onprogress = function (e) {
      console.log("progress")
      };

      xhr.onload = function (e) {
      console.log("load")
      };

      xhr.onerror = function (e) {
      console.log("error")
      };

      xhr.open("post", "/upload_image", true);

      xhr.send(imageData);
      console.log(image.length)
      console.log(imageData)
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

