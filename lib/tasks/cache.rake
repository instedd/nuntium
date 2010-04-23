task :environment

namespace :cache do
  desc "Clears the cache"
  task :reset => :environment do
    Rails.cache.clear
  end
end
