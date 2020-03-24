# frozen_string_literal: true

require 'execjs'
require 'opal'
require 'roda'
require 'snabberb'
require 'tilt/opal'

class OpalTemplate < Opal::TiltTemplate
  def evaluate(_scope, _locals)
    builder = Opal::Builder.new(stubs: 'opal')
    builder.append_paths('assets/js')
    builder.append_paths('build')

    opal_path = 'build/compiled-opal.js'
    File.write(opal_path, Opal::Builder.build('opal')) unless File.exist?(opal_path)

    content = builder.build(file).to_s
    map_json = builder.source_map.to_json
    "#{content}\n#{to_data_uri_comment(map_json)}"
  end

  def to_data_uri_comment(map_json)
    "//# sourceMappingURL=data:application/json;base64,#{Base64.encode64(map_json).delete("\n")}"
  end
end

Tilt.register 'rb', OpalTemplate

class App < Roda
  plugin :public
  plugin :assets, js: 'application.rb'
  compile_assets
  context = ExecJS.compile(File.read("#{assets_opts[:compiled_js_path]}.#{assets_opts[:compiled]['js']}.js"))

  route do |r|
    r.public
    r.assets

    r.root do
      context.eval(
        Snabberb.prerender_script(
          'Index',
          'Application',
          'application_id',
          javascript_include_tags: assets(:js),
        )
      )
    end

    r.on "upload_calibration_image" do
      r.post do
        File.open('/home/cdz/code/crapstracker/calibration.png','wb') do |file|
          file.write(Base64.decode64(r.params["image"]))
        end
        results = `python3 /home/cdz/code/crapstracker/testruby.py`
        puts results, "*****************calibration image works*****************"
        r.redirect
      end
    end

    r.on "upload_image" do
      puts "r.on uploadimage"
      r.post do
        File.open('/home/cdz/code/crapstracker/interval.png','wb') do |file|
          file.write(Base64.decode64(r.params["image"]))
        end
        puts "******iamge saved******"
        #results = IO.popen("python3 /home/cdz/code/crapstracker/find_pips_dice.py calibration.png sup.png sup")
        results = `python3 /home/cdz/code/crapstracker/find_pips_dice.py /home/cdz/code/crapstracker/test.png /home/cdz/code/crapstracker/interval.png sup`
        puts results, "**************************"
        r.redirect
      end
    end

  end
end

run App.freeze.app
