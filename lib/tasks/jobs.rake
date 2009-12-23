namespace :jobs do
  desc "Enqueue pop3 mail retrieval jobs"
  task :pop3 => :environment do
    ReceivePop3MessageJob.enqueue_for_all_channels
  end
  
  desc "Enqueue twitter messages retrieval jobs"
  task :twitter => :environment do
    ReceiveTwitterMessageJob.enqueue_for_all_channels
  end
  
  desc "Enqueue qst push jobs"
  task :qst_push => :environment do
    PushQstMessageJob.enqueue_for_all_interfaces
  end
  
  desc "Enqueue qst pull jobs"
  task :qst_pull => :environment do
    PullQstMessageJob.enqueue_for_all_interfaces
  end
  
end