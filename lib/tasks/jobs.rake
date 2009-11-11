namespace :jobs do
  desc "Enqueue pop3 mail retrieval jobs"
  task :pop3 => :environment do
    ReceivePop3MessageJob.enqueue_for_all_channels
  end
end