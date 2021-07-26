namespace :ffcrm do
  task :register_recipients => :environment do
    FatFreeCrm::Lead.register_recipients(FatFreeCrm::Lead.all)
  end
end
