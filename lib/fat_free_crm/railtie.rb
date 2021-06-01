module FatFreeCrm
  class Railtie < Rails::Railtie

    initializer "fat_free_crm.assets.precompile" do |app|
      app.config.assets.precompile += %w(fat_free_crm_manifest.js)
    end

  end
end
