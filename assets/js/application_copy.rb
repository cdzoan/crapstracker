# frozen_string_literal: true

require 'compiled-opal'
require 'polyfill'
require 'snabberb'
require 'set'

class Application < Snabberb::Component
  def render
    video = h(
      :video,
      attrs: { autoplay: true},
      style: { width: '500px', height: '500px' },
    )
    onload = lambda do
      %x{
        video_elm = #{video.JS['elm']}
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
    props = {
      style: { width: '100px' },
      hook: { insert: onload},
      attrs: { id: "application_id"},
    }
    h(:div, props, [
      video
    ])
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

