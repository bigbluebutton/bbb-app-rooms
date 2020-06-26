# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

theme = Rails.application.config.theme

unless theme.blank?
  # the entrypoint for the styles of the theme
  Rails.application.config.assets.precompile += %w( theme-application.css )
  Rails.application.config.assets.precompile += [
    Proc.new { |path, fn| fn =~ /themes\/#{theme}/ && !%w(.js .css).include?(File.extname(path)) }
  ]
end

# do it in `to_prepare` to make sure they are the first paths searched,
# so assets in the theme take precedence over default ones
Rails.application.config.to_prepare do
  unless theme.blank?
    Rails.application.config.assets.paths
      .unshift(Rails.root.join("themes", theme, "assets", "stylesheets"))
      .unshift(Rails.root.join("themes", theme, "assets", "javascripts"))
      .unshift(Rails.root.join("themes", theme, "assets", "images"))
  end
end
